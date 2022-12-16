FROM geopython/pycsw:2.6.1
LABEL dcatapit pycsw

USER root

# install curl for healthcheck
RUN apt-get update && \
    apt-get install --yes curl && \
    rm -rf /var/lib/apt/lists/*

# config log dir
RUN mkdir -p /var/log/pycsw && \
    chown pycsw: -R /var/log/pycsw

USER pycsw
