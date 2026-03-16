FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/pkg

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    rrdtool \
    librrds-perl \
    fping \
    nginx \
    ssmtp \
    spawn-fcgi \
    libfcgi-perl \
    libcgi-pm-perl \
    libcgi-fast-perl \
    libconfig-grammar-perl \
    libsocket6-perl \
    libio-socket-ssl-perl \
    libdigest-hmac-perl \
    libnet-telnet-perl \
    libnet-openssh-perl \
    libnet-snmp-perl \
    libnet-ldap-perl \
    libnet-dns-perl \
    libio-pty-perl \
    libwww-perl \
    libauthen-radius-perl \
    libpath-tiny-perl \
    libmime-base64-perl \
    dnsutils \
    apache2-utils \
    autoconf \
    automake \
    make \
    && rm -rf /var/lib/apt/lists/*

# renovate: datasource=github-releases depName=oetiker/SmokePing versioning=semver
ARG SMOKEPING_VERSION=v2.9.0

# Download and build SmokePing from source
WORKDIR /tmp/smokeping-build
RUN curl -LSs https://github.com/oetiker/SmokePing/archive/${SMOKEPING_VERSION}.tar.gz | tar -xz --strip-components 1 -f - && \
    ./bootstrap && \
    ./configure --prefix=/app/code/smokeping --enable-pkgonly && \
    make install && \
    rm -rf /tmp/smokeping-build

# Remove build-only packages
RUN apt-get purge -y autoconf automake make && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Configure nginx: remove default, install our site config at build time
# (Cloudron filesystem is read-only at runtime)
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-enabled/smokeping.conf

# Configure nginx: master runs as root (drops workers to www-data),
# logs to stdout/stderr (captured by supervisor -> Cloudron log viewer)
RUN mkdir -p /run/smokeping && chown www-data:www-data /run/smokeping && \
    sed -i 's|access_log /var/log/nginx/access.log;|access_log /dev/stdout;|' /etc/nginx/nginx.conf && \
    sed -i 's|error_log /var/log/nginx/error.log;|error_log stderr;|' /etc/nginx/nginx.conf && \
    echo 'client_body_temp_path /tmp/nginx_body;' > /etc/nginx/conf.d/tmpfs.conf && \
    echo 'proxy_temp_path /tmp/nginx_proxy;' >> /etc/nginx/conf.d/tmpfs.conf && \
    echo 'fastcgi_temp_path /tmp/nginx_fastcgi;' >> /etc/nginx/conf.d/tmpfs.conf && \
    echo 'uwsgi_temp_path /tmp/nginx_uwsgi;' >> /etc/nginx/conf.d/tmpfs.conf && \
    echo 'scgi_temp_path /tmp/nginx_scgi;' >> /etc/nginx/conf.d/tmpfs.conf

# Configure ssmtp: symlink config to writable /run/ so start.sh can write it
RUN rm -f /etc/ssmtp/ssmtp.conf && ln -s /run/ssmtp.conf /etc/ssmtp/ssmtp.conf

# Symlink timezone files to writable /run/ so start.sh can set timezone
RUN rm -f /etc/localtime && ln -s /run/localtime /etc/localtime && \
    rm -f /etc/timezone && ln -s /run/timezone /etc/timezone

# Copy Cloudron packaging files
COPY start.sh test-email.sh /app/pkg/
COPY supervisor/ /etc/supervisor/conf.d/
COPY config-defaults/ /app/pkg/config-defaults/

RUN chmod +x /app/pkg/start.sh /app/pkg/test-email.sh

# Configure supervisor logging
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

EXPOSE 8000

CMD ["/app/pkg/start.sh"]
