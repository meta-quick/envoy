ARG BUILD_OS=ubuntu
ARG BUILD_TAG=20.04
ARG ENVOY_VRP_BASE_IMAGE=envoy


FROM scratch AS binary

ARG TARGETPLATFORM
ENV TARGETPLATFORM=linux/amd64
ARG ENVOY_BINARY=envoy
ARG ENVOY_BINARY_SUFFIX=_stripped
ADD linux/amd64/envoy /usr/local/bin/
ADD configs/envoyproxy_io_proxy.yaml /etc/envoy/envoy.yaml
COPY --chown=0:0 linux/amd64/su-exec /usr/local/bin/
#COPY ${TARGETPLATFORM}/schema_validator_tool /usr/local/bin/schema_validator_tool
COPY ci/docker-entrypoint.sh /


# STAGE: envoy
FROM ${BUILD_OS}:${BUILD_TAG} AS envoy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update && apt-get -qq upgrade -y \
    && apt-get -qq install --no-install-recommends -y ca-certificates \
    && apt-get -qq autoremove -y && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/envoy

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /usr/local/bin/su-exec /usr/local/bin/
#COPY --from=binary /usr/local/bin/schema_validator_tool /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml
COPY --from=binary /docker-entrypoint.sh /

RUN adduser --group --system envoy

EXPOSE 10000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml"]
