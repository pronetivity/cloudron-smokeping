#!/bin/bash
set -eu

echo "=> SmokePing Cloudron startup"

# ----- Directory setup -----
echo "=> Ensuring data directories exist"
mkdir -p /app/data/config
mkdir -p /app/data/cache
mkdir -p /app/data/data
mkdir -p /run/smokeping

# ----- First run: copy default .env if not present -----
if [[ ! -f /app/data/.env ]]; then
    echo "=> Creating default .env"
    cp /app/pkg/config-defaults/env /app/data/.env
fi

# Source user overrides
if [[ -f /app/data/.env ]]; then
    echo "=> Loading user overrides from /app/data/.env"
    set -a
    source /app/data/.env
    set +a
fi

# ----- Apply timezone container-wide -----
if [[ -n "${TZ:-}" && -f "/usr/share/zoneinfo/${TZ}" ]]; then
    echo "=> Setting timezone to ${TZ}"
    cp /usr/share/zoneinfo/${TZ} /run/localtime
    echo "${TZ}" > /run/timezone
else
    # Default to UTC
    cp /usr/share/zoneinfo/UTC /run/localtime
    echo "UTC" > /run/timezone
fi

# ----- First run: generate htpasswd -----
if [[ ! -f /app/data/htpasswd ]]; then
    echo "=> First run detected, generating HTTP basic auth credentials"
    SP_USER="admin"
    SP_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
    htpasswd -cb /app/data/htpasswd "$SP_USER" "$SP_PASS"
    cat > /app/data/htpasswd.txt <<EOF
SmokePing HTTP Basic Auth Credentials
======================================
Username: ${SP_USER}
Password: ${SP_PASS}

Generated on first run. To change credentials, set
SMOKEPING_ADMIN_USER and SMOKEPING_ADMIN_PASS in /app/data/.env
EOF
    chmod 600 /app/data/htpasswd.txt
    echo "=> Credentials saved to /app/data/htpasswd.txt"
fi

# ----- Override htpasswd if env vars are set -----
if [[ -n "${SMOKEPING_ADMIN_USER:-}" && -n "${SMOKEPING_ADMIN_PASS:-}" ]]; then
    echo "=> Updating HTTP basic auth from environment"
    htpasswd -cb /app/data/htpasswd "$SMOKEPING_ADMIN_USER" "$SMOKEPING_ADMIN_PASS"
fi

# ----- Restore missing config files from defaults -----
for cfg in General Alerts Database Presentation Probes Targets; do
    if [[ ! -f /app/data/config/$cfg ]]; then
        echo "=> Creating default config: $cfg"
        cp /app/pkg/config-defaults/$cfg /app/data/config/$cfg
    fi
done

# ----- Resolve settings -----
SMTP_SERVER="${CLOUDRON_MAIL_SMTP_SERVER:-localhost}"
SMTP_PORT="${CLOUDRON_MAIL_STARTTLS_PORT:-${CLOUDRON_MAIL_SMTP_PORT:-587}}"
SMTP_USER="${CLOUDRON_MAIL_SMTP_USERNAME:-}"
SMTP_PASS="${CLOUDRON_MAIL_SMTP_PASSWORD:-}"
MAIL_FROM="${CLOUDRON_MAIL_FROM:-smokeping@localhost}"
ALERT_TO="${SMOKEPING_ALERT_TO:-${MAIL_FROM}}"
CGI_URL="${CLOUDRON_APP_ORIGIN:-http://localhost:8000}/smokeping.fcgi"
OWNER="${SMOKEPING_OWNER:-SmokePing Admin}"
CONTACT="${SMOKEPING_CONTACT:-admin@foo.bar}"
STEP="${SMOKEPING_STEP:-300}"
PINGS="${SMOKEPING_PINGS:-20}"

# ----- Configure ssmtp -----
# Write to /run/ (writable); /etc/ssmtp/ssmtp.conf is symlinked here at build time
echo "=> Configuring ssmtp"
cat > /run/ssmtp.conf <<EOF
root=${MAIL_FROM}
mailhub=${SMTP_SERVER}:${SMTP_PORT}
hostname=$(hostname)
UseSTARTTLS=YES
AuthUser=${SMTP_USER}
AuthPass=${SMTP_PASS}
FromLineOverride=YES
EOF

# ----- Assemble SmokePing config -----
echo "=> Assembling SmokePing configuration"
ASSEMBLED_CONFIG="/run/smokeping/config"

# Assemble all config sections, replacing placeholders in each
> "${ASSEMBLED_CONFIG}"
for cfg in General Alerts Database Presentation Probes Targets; do
    sed \
        -e "s|__OWNER__|${OWNER}|g" \
        -e "s|__CONTACT__|${CONTACT}|g" \
        -e "s|__MAIL_FROM__|${MAIL_FROM}|g" \
        -e "s|__ALERT_TO__|${ALERT_TO}|g" \
        -e "s|__SMTP_SERVER__|${SMTP_SERVER}|g" \
        -e "s|__CGI_URL__|${CGI_URL}|g" \
        -e "s|__STEP__|${STEP}|g" \
        -e "s|__PINGS__|${PINGS}|g" \
        /app/data/config/$cfg >> "${ASSEMBLED_CONFIG}"
    echo "" >> "${ASSEMBLED_CONFIG}"
done
chmod 640 "${ASSEMBLED_CONFIG}"
chown root:www-data "${ASSEMBLED_CONFIG}"

# ----- Fix permissions -----
echo "=> Setting permissions"
chown -R www-data:www-data /app/data/cache /app/data/data
chown -R www-data:www-data /run/smokeping
chown www-data:www-data /app/data/htpasswd
chmod 644 /app/data/htpasswd

# ----- Launch supervisor -----
echo "=> Starting supervisor"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
