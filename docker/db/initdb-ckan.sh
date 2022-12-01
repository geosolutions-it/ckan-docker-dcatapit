#!/bin/bash
set -e

function create_CKAN_user_and_database() {
	echo "  Creating user and database '$CKAN_DATABASE_USER;'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
		CREATE USER $CKAN_DATABASE_USER with encrypted password '$CKAN_DATABASE_PASSWORD';
		CREATE DATABASE $CKAN_DATABASE with owner $CKAN_DATABASE_USER;
EOSQL
}

function create_pycsw_db() {
	echo "  Creating pycsw database '$CKAN_DATABASE_USER;'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL

		CREATE DATABASE $PYCSW_DATABASE WITH OWNER $CKAN_DATABASE_USER;
		\c $PYCSW_DATABASE
        CREATE EXTENSION IF NOT EXISTS postgis; 
        ALTER VIEW geometry_columns OWNER TO $CKAN_DATABASE_USER; 
        ALTER TABLE spatial_ref_sys OWNER TO $CKAN_DATABASE_USER;
EOSQL
}


function update_database_with_postgis() {
    echo "  Updating database '$CKAN_DATABASE' with extension"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$CKAN_DATABASE" <<-EOSQL
		CREATE EXTENSION IF NOT EXISTS postgis;
		GRANT ALL ON geometry_columns TO PUBLIC;
		GRANT ALL ON spatial_ref_sys TO PUBLIC;
EOSQL
psql -U "$POSTGRES_USER" --dbname "$CKAN_DATABASE" -c "CREATE EXTENSION IF NOT EXISTS postgis; ALTER VIEW geometry_columns OWNER TO $CKAN_DATABASE_USER; ALTER TABLE spatial_ref_sys OWNER TO $CKAN_DATABASE_USER;"
psql -U "$POSTGRES_USER" postgres -c "CREATE ROLE $DATASTORE_READONLY_USER LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION PASSWORD '$DATASTORE_READONLY_PASSWORD';"
psql -U "$POSTGRES_USER" postgres -c "CREATE DATABASE $DATASTORE_DB WITH OWNER ckan ENCODING 'utf-8';"
psql -U "$POSTGRES_USER" postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DATASTORE_DB TO $CKAN_DATABASE_USER;"
psql -U "$POSTGRES_USER" $DATASTORE_DB -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $DATASTORE_READONLY_USER;"

}

if [ -n "$CKAN_DATABASE" ]; then
	echo "CKAN databases creation requested: $CKAN_DATABASE, $DATASTORE_DB"
	create_CKAN_user_and_database
	update_database_with_postgis

	create_pycsw_db

	echo "CKAN databases created"
fi