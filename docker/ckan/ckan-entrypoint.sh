#!/bin/bash
set -e
set -x

echo "########################################"
echo "### Starting CKAN entrypoint"
echo "########################################"

# URL for the primary database, in the format expected by sqlalchemy (required
# unless linked to a container called 'db')
: ${CKAN_SQLALCHEMY_URL:=}
# URL for solr (required unless linked to a container called 'solr')
: ${CKAN_SOLR_URL:=}
# URL for redis (required unless linked to a container called 'redis')
: ${CKAN_REDIS_URL:=}
# URL for datapusher (required unless linked to a container called 'datapusher')
: ${CKAN_DATAPUSHER_URL:=}

# PGTMP=${CKAN_SQLALCHEMY_URL##*@}
# CKAN_PG_HOST=${PGTMP%/*}

CONFIG_INI="${CKAN_CONFIG}/ckan.ini"

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=/var/lib/ckan
  export CKAN_DATAPUSHER_URL=${CKAN_DATAPUSHER_URL}
  export CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
  export CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
  export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
  # custom
  export GEONAMES_USERNAME=${GEONAMES_USERNAME}
}

write_config () {
  echo "Generating config at ${CONFIG_INI}..."
  $CKAN_VENV/bin/ckan generate config "$CONFIG_INI"

}

# Wait for PostgreSQL
while ! pg_isready -h $PG_HOST -U ckan; do
  echo "waiting for pg to be ready..."
  sleep 1;
done

# If we don't already have a who config file, bootstrap
if [ ! -e "$CKAN_CONFIG/who.ini" ]; then
  cp $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini
else
  echo "who.ini already exists"
fi

# If we don't already have a config file, bootstrap
if [ ! -e "$CONFIG_INI" ]; then
  write_config
else
  echo "Config at ${CONFIG_INI} already exists"
  ls -l ${CONFIG_INI}
fi

echo "Customizing CKAN configuration file ${CONFIG_INI}..."
CONFIG_TMP=/tmp/ckan.ini

# we need to use crudini in a local copy or we get a [Errno 13] Permission denied
cp ${CONFIG_INI} ${CONFIG_TMP}
#cp ${CONFIG_INI} "/etc/ckan/$(date -Ins)_ckan.ini"

# Please note that many values are configured through environment variables, not in the ini file
# See https://docs.ckan.org/en/2.9/maintaining/configuration.html#environment-variables

# changes to the ini file -- SHOULD BE IDEMPOTENT
crudini --set ${CONFIG_TMP} app:main ckan.plugins ""
for plugin in \
    stats \
    text_view image_view recline_view \
    datastore datapusher \
    harvest \
    spatial_metadata spatial_query \
    structured_data dcat dcat_json_interface \
    multilang \
    dcatapit_pkg dcatapit_org dcatapit_config dcatapit_harvest_list dcatapit_harvester dcatapit_csw_harvester dcatapit_vocabulary
do
    crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins $plugin
done

crudini --set --verbose ${CONFIG_TMP} DEFAULT debug False

crudini --set --verbose ${CONFIG_TMP} app:main ckan.site_url ${CKAN_SITE_URL}

crudini --set --verbose ${CONFIG_TMP} logger_root     level WARN
crudini --set --verbose ${CONFIG_TMP} logger_werkzeug level WARN
crudini --set --verbose ${CONFIG_TMP} logger_ckan     level WARN
crudini --set --verbose ${CONFIG_TMP} logger_ckanext  level DEBUG
crudini --set --verbose ${CONFIG_TMP} handler_console level DEBUG
crudini --set --verbose ${CONFIG_TMP} handler_syslog  level DEBUG

crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.echo_pool     True
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_size     10
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_pre_ping True
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_reset_on_return rollback
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_timeout  30

crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.url                ${CKAN_DATAPUSHER_URL}
crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.callback_url_base  ${CKAN_INTERNAL_URL}
crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.assume_task_stale_after ${DATAPUSHER_ASSUME_TASK_STALE}

crudini --set --verbose ${CONFIG_TMP} app:main ckan.max_resource_size          ${CKAN_MAX_UPLOAD_SIZE_MB}

crudini --set --verbose ${CONFIG_TMP} app:main ckan.auth.create_user_via_web   false

crudini --set --verbose ${CONFIG_TMP} app:main ckan.locale_default    it
crudini --set --verbose ${CONFIG_TMP} app:main ckan.locale_order     "it en de fr"
crudini --set --verbose ${CONFIG_TMP} app:main ckan.locales_offered  "it en de fr"

crudini --set --verbose ${CONFIG_TMP} app:main ckanext.spatial.search_backend solr
crudini --set --verbose ${CONFIG_TMP} app:main ckanext.spatial.harvest.continue_on_validation_errors True

# preview formats

crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.json_formats json

crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats xml
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats rdf
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats rdf+xml
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats owl+xml
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats atom
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.xml_formats rss

crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.text_formats text
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.text_formats plain
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.preview.text_formats text/plain

# dcat / dcatapit

crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckanext.dcat.rdf.profiles euro_dcat_ap
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckanext.dcat.rdf.profiles it_dcat_ap
crudini --set --verbose ${CONFIG_TMP} app:main  ckanext.dcat.base_uri ${DCAT_BASE_URI}
crudini --set --verbose ${CONFIG_TMP} app:main  ckan.dcatapit.eurovoc_location $CKAN_VENV/src/ckanext-dcatapit/vocabularies/eurovoc-filtered.rdf

crudini --set --verbose ${CONFIG_TMP} app:main my.geoNamesApiServer secure.geonames.org
crudini --set --verbose ${CONFIG_TMP} app:main my.geoNamesProtocol https
crudini --set --verbose ${CONFIG_TMP} app:main geonames.limits.countries IT
crudini --set --verbose ${CONFIG_TMP} app:main geonames.username ${GEONAMES_USERNAME}

# customer specific plugins
#for plugin in \
#    grouplabel \
#    custom_lf custom_harvester
#do
#    crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins $plugin
#done

#crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckanext.dcat.rdf.profiles custom_ap
# end of customer specific extensions

# full INI blocks 
if [ -n "$(ls -A /usr/lib/ckan/ini/*.ini 2>/dev/null)" ]
then
  for ini in /usr/lib/ckan/ini/*.ini ; do
    echo "Merging configuration from $ini"
    crudini --verbose --merge ${CONFIG_TMP} < $ini
  done
else
    echo "No ini files to merge)"
fi
# END changes to the ini file
cp ${CONFIG_TMP} ${CONFIG_INI}

#Configure datastore SQL functions
echo "Configuring datastore..."

# we don't want logs lines to creep into the sql script
$CKAN_VENV/bin/ckan -c ${CONFIG_INI} datastore set-permissions | grep -v  sqlalchemy.pool > /tmp/check_datastore.sql
PGPASSWORD=${CKAN_DATABASE_PASSWORD} psql --set ON_ERROR_STOP=1 -U ckan -h ${PG_HOST} --dbname datastore -f /tmp/check_datastore.sql

# Get or create CKAN_SQLALCHEMY_URL
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
  abort "ERROR: no CKAN_SQLALCHEMY_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
    abort "ERROR: no CKAN_SOLR_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
    abort "ERROR: no CKAN_REDIS_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_DATAPUSHER_URL" ]; then
    abort "ERROR: no CKAN_DATAPUSHER_URL specified in docker-compose.yml"
fi

echo "Setting var and venv..."
set_environment
source $CKAN_VENV/bin/activate

echo "Initting DB... -- ckan"
ckan -c "$CONFIG_INI" db init

echo "Initting DB... -- harvest"
ckan -c "$CONFIG_INI" harvester initdb

echo "Initting DB... -- spatial"
ckan -c "$CONFIG_INI" spatial initdb

echo "Initting DB... -- multilang"
ckan -c "$CONFIG_INI" multilang initdb

echo "Initting DB... -- dcatapit"
ckan -c "$CONFIG_INI" dcatapit initdb

echo "Initting DB... -- pycsw"
/usr/lib/ckan/pycsw-venv/bin/python  /ckan_pycsw.py setup -p /etc/pycsw/pycsw.cfg


if [ "$(ckan -c "$CONFIG_INI" sysadmin list 2>&1 | grep ^User | grep -v 'name=default' | wc -l )" == "0" ];then
  echo "Adding admin user"
  # APIKEY=$(cat /proc/sys/kernel/random/uuid)
  echo -ne '\n' | ckan -c "$CONFIG_INI" sysadmin add admin email=admin@localhost name=admin password=adminadmin
fi

if [ ! -f "${CKAN_CONFIG}/vocabularies.downloaded" ]; then
  echo "Starting configuration of vocabolaries"

  # download vocabolaries
  # (eurovoc is already set using ckan.dcatapit.eurovoc_location)
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/languages-filtered.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/data-theme-filtered.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/places-filtered.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/frequencies-filtered.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/filetypes-filtered.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/theme-subtheme-mapping.rdf
  ckan --config=$CONFIG_INI dcatapit load --filename $CKAN_VENV/src/ckanext-dcatapit/vocabularies/licences.rdf

  touch ${CKAN_CONFIG}/vocabularies.downloaded

  echo "Finished configuration of vocabularies"
fi

echo "Starting ckan scheduler"

/usr/lib/ckan/venv/bin/python /usr/local/bin/scheduler.py &

echo 'Running command --> ' $@
exec "$@"
