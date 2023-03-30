FROM registry.home/ironbank/ubi9:latest


ARG MAXMIND_GEOIP_DB_LICENSE_KEY
ARG SUBSCRIPTION_MANAGER_ACTIVATION_KEY
ARG SUBSCRIPTION_MANAGER_ORG
ENV MAXMIND_GEOIP_DB_LICENSE_KEY=${MAXMIND_GEOIP_DB_LICENSE_KEY} \
    SMDEV_CONTAINER_OFF=1 \
    ELASTIC_AUTH_URL=http://elastic:elastic@es.rancher.home \
    ARKIME_DIR="/opt/arkime" \
    ARKIME_ADMIN_USER=admin \
    ARKIME_ADMIN_PASSWORD=password \
    DEFAULT_GID=1000 \
    DEFAULT_UID=1000 \
    DEFAULT_GROUP=arkime \
    DEFAULT_USER=arkime




RUN rm /etc/rhsm-host && subscription-manager register --org ${SUBSCRIPTION_MANAGER_ORG} --activationkey ${SUBSCRIPTION_MANAGER_ACTIVATION_KEY}

RUN dnf update -y && \
    dnf install -y --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf install -y --nogpgcheck https://s3.amazonaws.com/files.molo.ch/builds/el-9/arkime-4.2.0-1.x86_64.rpm && \
    dnf install -y \
        iproute \
        nano \
        procps-ng \
        supervisor \
        wget 


RUN curl -sSLo $ARKIME_DIR/etc/ipv4-address-space.csv "https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.csv" && \
    curl -sSLo $ARKIME_DIR/etc/oui.txt "https://raw.githubusercontent.com/wireshark/wireshark/master/manuf" && \
    if [ ! -z "$MAXMIND_GEOIP_DB_LICENSE_KEY" ]; then \
        for EDITION in ASN City Country; do \
            curl -sSLo - "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-$EDITION&license_key=$MAXMIND_GEOIP_DB_LICENSE_KEY&suffix=tar.gz" | tar zxf - --wildcards --no-anchored --strip=1 -C $ARKIME_DIR/etc/ '*.mmdb'; \
        done \
    fi;


COPY rootfs /

RUN groupadd --gid $DEFAULT_GID $DEFAULT_GROUP && \
    useradd -M --uid $DEFAULT_UID --gid $DEFAULT_GID --home $ARKIME_DIR $DEFAULT_USER && \
    usermod -a -G tty $DEFAULT_USER && \
    mkdir $ARKIME_DIR/raw && chown -R $DEFAULT_UID:$DEFAULT_GID $ARKIME_DIR

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n" ]