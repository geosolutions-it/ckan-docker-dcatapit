FROM ckan/ckan-solr:2.10-solr9-spatial

ENV SCHEMA_UPDATE_FIELD '\
    <!-- ckanext-multilang --> \n\
    <dynamicField name="package_multilang_localized_*" type="text" indexed="true" stored="true" multiValued="false"/> \n\
    <!-- end of ckanext-multilang --> \n\
 \n\
    <!-- ckanext-dcatapit --> \n\
    <field        name="dcat_theme"            type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <field        name="dcat_subtheme"         type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <dynamicField name="dcat_subtheme_*"       type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <dynamicField name="organization_region_*" type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <dynamicField name="resource_license_*"    type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <field        name="resource_license"      type="string" indexed="true" stored="false" multiValued="true"/> \n\
    <!-- end of ckanext-dcatapit --> \n\
 \n\
    <dynamicField name="harvest_*" type="text" indexed="true" stored="true" multiValued="false"/> \n\
'

ENV SCHEMA_UPDATE_COPY '\
<!-- ckanext-multilang --> \n\
<copyField source="package_multilang_localized_*" dest="text"/>   \n\
<!-- end of ckanext-multilang --> \n\
\
'

ENV SOLR_SCHEMA_FILE="$SOLR_CONFIG_DIR/ckan/conf/managed-schema"

USER root

RUN sed -i "/<\/fields>/i $SCHEMA_UPDATE_FIELD" $SOLR_SCHEMA_FILE
RUN sed -i "/<\/schema>/i $SCHEMA_UPDATE_COPY" $SOLR_SCHEMA_FILE

USER solr
CMD ["sh", "-c", "solr-precreate ckan $SOLR_CONFIG_DIR/ckan"]
