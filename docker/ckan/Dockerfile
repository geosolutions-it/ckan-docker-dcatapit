# See CKAN docs on installation from Docker Compose on usage
FROM debian:buster-slim
LABEL Open Knowledge

ENV DEBIAN_FRONTEND=noninteractive
# Install required system packages
RUN apt-get -q -y update \
    && apt-get -q -y upgrade \
    && apt-get -q -y install \
        crudini \
        tcpdump \
        python3-dev \
        python3-pip \
        python3-virtualenv \
        python3-venv \
        python3-wheel \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
        gdb python3-dbg \
        procps \
        swig \
        proj-bin \
        python3-setuptools \
        curl \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# RUN wget https://raw.githubusercontent.com/pixelb/crudini/0.9.3/crudini -O /usr/bin/crudini \
#     && chmod a+x /usr/bin/crudini

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH /var/lib/ckan
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/bash ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH $CKAN_HOME/ini && \
    chown ckan:ckan -R ${CKAN_HOME} $CKAN_CONFIG $CKAN_STORAGE_PATH

USER ckan

RUN python3 -m venv $CKAN_VENV

RUN git clone https://github.com/ckan/ckan.git -b 2.9 $CKAN_VENV/src/ckan

RUN $CKAN_VENV/bin/pip install -U pip && \
    $CKAN_VENV/bin/pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    $CKAN_VENV/bin/pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    $CKAN_VENV/bin/pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/dev-requirements.txt && \
    $CKAN_VENV/bin/pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini

RUN $CKAN_VENV/bin/pip install -e git+https://github.com/ckan/ckanext-harvest.git@master#egg=ckanext-harvest && \
    $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-harvest/pip-requirements.txt
RUN $CKAN_VENV/bin/pip install -e git+https://github.com/ckan/ckanext-spatial.git@v1.1.0#egg=ckanext-spatial && \
    $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-spatial/requirements.txt
RUN $CKAN_VENV/bin/pip install -e git+https://github.com/ckan/ckanext-dcat.git@master#egg=ckanext-dcat && \
    $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-dcat/requirements.txt
RUN $CKAN_VENV/bin/pip install -e git+https://github.com/geosolutions-it/ckanext-multilang@master#egg=ckanext-multilang && \
     cd $CKAN_VENV/src/ckanext-multilang && $CKAN_VENV/bin/python setup.py develop && \
     $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-multilang/dev-requirements.txt
RUN $CKAN_VENV/bin/pip install -e git+https://github.com/geosolutions-it/ckanext-dcatapit@master#egg=ckanext-dcatapit && \
     $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-dcatapit/requirements.txt

# last pre-2 version (ckanext-spatial sets => 1.2.13)
RUN $CKAN_VENV/bin/pip install Shapely==1.8.5

# customer specific extensions
RUN $CKAN_VENV/bin/pip install -e git+https://github.com/geosolutions-it/ckanext-liguria@main#egg=ckanext-liguria && \
     $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-liguria/requirements.txt
#RUN $CKAN_VENV/bin/pip install -e git+https://github.com/geosolutions-it/ckanext-geonode@master#egg=ckanext-geonode && \
#     $CKAN_VENV/bin/pip install -r $CKAN_VENV/src/ckanext-geonode/requirements.txt
# end of customer specific extensions


### Create VENV for pycsw synch task
ENV PYCSW_VENV $CKAN_HOME/pycsw-venv
RUN mkdir -p $PYCSW_VENV
RUN python3 -m venv $PYCSW_VENV
RUN $PYCSW_VENV/bin/pip install -U pip setuptools
RUN $PYCSW_VENV/bin/pip install -e git+https://github.com/geopython/pycsw.git@2.6.1#egg=pycsw && \
    $PYCSW_VENV/bin/pip install -r $PYCSW_VENV/src/pycsw/requirements-standalone.txt && \
    $PYCSW_VENV/bin/pip install -r $PYCSW_VENV/src/pycsw/requirements-pg.txt
# needed to parse gmx:Anchor
#RUN $PYCSW_VENV/bin/pip install 'OWSLib>=0.19.0'
# This is also set on pycsw master branch
RUN $PYCSW_VENV/bin/pip install 'Shapely<2.0'


RUN $CKAN_VENV/bin/pip install supervisor==4.2.4

USER root

ENV CKAN_LOG=/var/log/ckan
RUN mkdir -p ${CKAN_LOG} && \
    chown ckan:ckan -R ${CKAN_LOG} && \
    mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d && \
    chown -R ckan:ckan /var/log/supervisor /var/log/ckan /var/run/supervisor /etc/supervisor && \
    chown ckan:ckan /var/run && \
    chmod gu+rw /var/run

COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./scheduler.py /usr/local/bin/scheduler.py

RUN chmod +x /usr/local/bin/scheduler.py
RUN $CKAN_VENV/bin/pip install schedule==1.1.0

# Setup CKAN custom scripts
COPY --chown=ckan:ckan ./ckan-entrypoint.sh ./ckan-run.sh ./consumer-entrypoint.sh ./ckan_pycsw.py /
RUN chmod +x            /ckan-entrypoint.sh  /ckan-run.sh  /consumer-entrypoint.sh 

# debug tools, not working with container running as unprivileged user
COPY --chown=ckan:ckan ./gdb.commands ./capture_gdb.sh /
RUN chmod +x           /capture_gdb.sh

# copy custom .ini snippets
COPY ./ini $CKAN_HOME/ini

#Please comment if you need to use debugging tools like gdb
USER ckan

SHELL ["/bin/bash", "-c"]

ENTRYPOINT ["/ckan-entrypoint.sh"]
CMD ["/ckan-run.sh"]
