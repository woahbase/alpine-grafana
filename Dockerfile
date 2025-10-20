# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG SRCARCH
ARG VERSION
#
ENV \
    GRAFANA_HOME="/var/lib/grafana"
#
RUN set -ex \
    && apk add -Uu --no-cache \
        ca-certificates \
        curl \
        fontconfig \
        gcompat \
        musl-utils \
        openssl \
        tzdata \
    && (if [ ! -e /etc/nsswitch.conf ]; then echo 'hosts: files dns' > /etc/nsswitch.conf; fi) \
    && echo "Using version: $VERSION" \
    && mkdir -p ${GRAFANA_HOME} \
    && curl -o /tmp/grafana-${VERSION}.${SRCARCH}.tar.gz -SL https://dl.grafana.com/oss/release/grafana-${VERSION}.${SRCARCH}.tar.gz \
    && cd /tmp/ \
    && tar -xzf grafana-${VERSION}.${SRCARCH}.tar.gz \
    && mv grafana-${VERSION}/* ${GRAFANA_HOME}/ \
    && mv ${GRAFANA_HOME}/bin/* /usr/local/bin/ \
    && mkdir -p /defaults \
    && mv $GRAFANA_HOME/conf/defaults.ini /defaults/defauls.ini.default \
    && chown -R ${S6_USER:-alpine}:${S6_USER:-alpine} ${GRAFANA_HOME} \
    && rm -rf /var/cache/apk/* /tmp/*
#
ENV \
    S6_USER=alpine \
    S6_USERHOME=${GRAFANA_HOME} \
    GF_PATHS_CONFIG="${GRAFANA_HOME}/conf/defaults.ini" \
    GF_PATHS_DATA="${GRAFANA_HOME}/data" \
    GF_PATHS_HOME="${GRAFANA_HOME}" \
    GF_PATHS_LOGS="${GRAFANA_HOME}/logs" \
    GF_PATHS_PLUGINS="${GRAFANA_HOME}/plugins" \
    GF_PATHS_PROVISIONING="${GRAFANA_HOME}/provisioning"
#
COPY root/ /
#
VOLUME  ["${GRAFANA_HOME}/dashboards", "${GF_PATHS_DATA}", "${GF_PATHS_LOGS}", "${GF_PATHS_PLUGINS}", "${GF_PATHS_PROVISIONING}"]
#
EXPOSE 3000
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    wget --quiet --tries=1 --no-check-certificate --spider ${HEALTHCHECK_URL:-"http://localhost:3000/api/health"} || exit 1
#
ENTRYPOINT ["/init"]
