#!/bin/bash
set -e

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

CONFIG_INI="${CKAN_CONFIG}/production.ini"

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
}

write_config () {
  echo "Generating config at ${CONFIG_INI}..."
  $CKAN_VENV/bin/ckan generate config "$CONFIG_INI"

}

# Wait for PostgreSQL
while ! pg_isready -h $PG_HOST -U ckan; do
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

# changes to the ini file -- SHOULD BE IDEMPOTENT

# Make sure azure_auth is before c195
# crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins grace_period
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins structured_data
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins datastore
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins datapusher
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins harvest
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins dcat
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins dcat_json_interface
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins spatial_metadata 
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins spatial_query
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins multilang
crudini --set --verbose --list --list-sep=\  ${CONFIG_TMP} app:main ckan.plugins dcatapit


crudini --set --verbose ${CONFIG_TMP} DEFAULT debug False

crudini --set --verbose ${CONFIG_TMP} logger_root     level DEBUG
crudini --set --verbose ${CONFIG_TMP} logger_werkzeug level DEBUG
crudini --set --verbose ${CONFIG_TMP} logger_ckan     level DEBUG
crudini --set --verbose ${CONFIG_TMP} logger_ckanext  level DEBUG
crudini --set --verbose ${CONFIG_TMP} handler_console level DEBUG
crudini --set --verbose ${CONFIG_TMP} handler_syslog  level DEBUG

crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_size 10
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.echo_pool True
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_pre_ping True
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_reset_on_return rollback
crudini --set --verbose ${CONFIG_TMP} app:main sqlalchemy.pool_timeout 30

#Azure auth plugin https://github.com/geosolutions-it/ckanext-azure-auth.git
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.tenant_id ${TENANT_ID}
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.client_id ${CLIENT_ID}
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.audience ${CLIENT_ID}
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.client_secret ${CLIENT_SECRET}
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.auth_callback_path /azure/callback
# crudini --set --verbose ${CONFIG_TMP} app:main ckanext.azure_auth.allow_create_users True

crudini --set --verbose ${CONFIG_TMP} app:main ckan.max_resource_size ${CKAN_MAX_UPLOAD_SIZE_MB}
crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.callback_url_base ${CKAN_SITE_URL}
crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.url ${CKAN_DATAPUSHER_URL}
crudini --set --verbose ${CONFIG_TMP} app:main ckan.datapusher.assume_task_stale_after ${DATAPUSHER_ASSUME_TASK_STALE}

crudini --set --verbose ${CONFIG_TMP} app:main ckanext.spatial.search_backend solr

# dcatapit

crudini --set --verbose ${CONFIG_TMP} app:main my.geoNamesApiServer secure.geonames.org
crudini --set --verbose ${CONFIG_TMP} app:main my.geoNamesProtocol https


# END changes to the ini file 
cp ${CONFIG_TMP} ${CONFIG_INI}

#Configure datastore SQL functions
echo "Configuring datastore..."
$CKAN_VENV/bin/ckan -c ${CONFIG_INI} datastore set-permissions > /tmp/check_datastore.sql
PGPASSWORD=${CKAN_DATABASE_PASSWORD} psql --set ON_ERROR_STOP=1 -U ckan -h ${PG_HOST} --dbname datastore


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
ckan --config "$CONFIG_INI" db init

echo "Initting DB... -- harvest"
ckan --config "$CONFIG_INI" harvester initdb

echo "Initting DB... -- spatial"
ckan --config "$CONFIG_INI" spatial initdb

echo "Initting DB... -- multilang"
ckan --config "$CONFIG_INI" multilangdb initdb

echo "Initting DB... -- dcatapit"
ckan --config "$CONFIG_INI" vocabulary initdb

if [ "$(ckan -c "$CONFIG_INI" sysadmin list 2>&1 | grep ^User | grep -v 'name=default' | wc -l )" == "0" ];then
  echo "Adding admin user"
  # APIKEY=$(cat /proc/sys/kernel/random/uuid)
  echo -ne '\n' | ckan -c "$CONFIG_INI" sysadmin add admin email=admin@localhost name=admin password=adminadmin
fi

echo 'Running command --> ' $@
exec "$@"
