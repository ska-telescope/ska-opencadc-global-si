# one database name here is enough, the rest is created automatically
DATABASES='globaldb'

# for luskan, the shemas HAS to be 'inventory'
SCHEMAS='inventory'

# in luskan's catalina.properties and from the README:
#The tapadm pool manages (create, alter, drop) tap_schema tables and manages the tap_schema content.
#The uws pool manages (create, alter, drop) uws tables and manages the uws content (creates and
#modifies jobs in the uws schema when jobs are created and executed by users.
#
#The query pool is used to run TAP queries, including creating tables in the tap_upload schema.
#
#All three pools must have the same JDBC URL (e.g. use the same database) with PostgreSQL.
#This may be relaxed in future. In addition, the TAP service does not currerently support a
#configurable schema name: it assumes a schema named inventory holds the content.
