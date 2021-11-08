FROM postgis/postgis:13-3.1-alpine
LABEL dcatapit CKAN db

COPY ./initdb-ckan.sh /docker-entrypoint-initdb.d/ckan.sh
RUN chmod +x /docker-entrypoint-initdb.d/ckan.sh