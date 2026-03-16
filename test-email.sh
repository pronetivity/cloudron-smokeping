#!/bin/bash
# Test email script for SmokePing Cloudron
# Usage: /app/pkg/test-email.sh [recipient]
#
# Sends a test email using the configured ssmtp settings.
# If no recipient is specified, sends to SMOKEPING_ALERT_TO or CLOUDRON_MAIL_FROM.

# Source .env for overrides
if [[ -f /app/data/.env ]]; then
    set -a
    source /app/data/.env
    set +a
fi

MAIL_FROM="${CLOUDRON_MAIL_FROM:-smokeping@localhost}"
RECIPIENT="${1:-${SMOKEPING_ALERT_TO:-${MAIL_FROM}}}"
HOSTNAME=$(hostname)
DATE=$(date -R)

echo "=> Sending test email to: ${RECIPIENT}"
echo "=> Using sender: ${MAIL_FROM}"
echo "=> SMTP server: ${CLOUDRON_MAIL_SMTP_SERVER:-localhost}:${CLOUDRON_MAIL_SMTP_PORT:-25}"

if /usr/sbin/ssmtp "${RECIPIENT}" <<EOF
To: ${RECIPIENT}
From: ${MAIL_FROM}
Subject: SmokePing Test Email
Date: ${DATE}

This is a test email from your SmokePing Cloudron instance.

Host: ${HOSTNAME}
Time: ${DATE}

If you received this email, your SmokePing alert delivery is working correctly.
EOF
then
    echo "=> Test email sent successfully!"
else
    echo "=> ERROR: Failed to send test email. Check ssmtp configuration and /app/data/.env"
    exit 1
fi
