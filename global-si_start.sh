#!/bin/bash

set -e

# create a tempory set of variables from the (hopefully) existing vars.yaml
cat vars.yaml | sed 's/---/#/g' | sed 's/: /=/g' | sed 's/{{/${/g' | sed 's/}}/}/g' > /tmp/vars.sh
source /tmp/vars.sh


# create required directories
mkdir -p ${LOGS_FOLDER}
mkdir -p ${CACERTIFICATES_FOLDER}

# Pull all the containers precreated
docker pull ${POSTGRESQL_IMAGE}
docker pull ${HAPROXY_IMAGE}
docker pull ${SI_REPO_PATH}/baldur:${BALDUR_VERSION}
docker pull ${CORE_REPO_PATH}/reg:${REG_VERSION}
docker pull ${SI_REPO_PATH}/raven:${RAVEN_VERSION}
docker pull ${SI_REPO_PATH}/ratik:${RATIK_VERSION}
docker pull ${SI_REPO_PATH}/fenwick:${FENWICK_VERSION}
docker pull ${SI_REPO_PATH}/luskan:${LUSKAN_VERSION}

# create the network to be used by all
docker network create si-network


# Instantiate postgresql
docker run -d \
       --volume=${CONFIG_FOLDER}/postgresql:/config:ro \
       --volume=${LOGS_FOLDER}:/logs:rw \
       -p 5432:5432 \
       --name pg12db \
       --network si-network \
       ${POSTGRESQL_IMAGE}
# Wait to populate
sleep ${WAIT_SECONDS_LONG}


# Launch global registry
docker run -d --volume=${CONFIG_FOLDER}/reg:/config:ro \
       --user tomcat:tomcat \
       --name reg \
       --network si-network \
       ${CORE_REPO_PATH}/reg:${REG_VERSION}
# Wait to start up
sleep ${WAIT_SECONDS}

# Launch baldur
docker run -d \
       --volume=${CONFIG_FOLDER}/baldur:/config:ro \
       --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
       --user tomcat:tomcat \
       --name baldur \
       --network si-network \
       ${SI_REPO_PATH}/baldur:${BALDUR_VERSION}
# Wait to start up
sleep ${WAIT_SECONDS}

# Launch fenwicks
sites='cadc swesrc spsrc swisrc'
for site in ${sites}; do
    docker run -d \
	   --volume=${CONFIG_FOLDER}/fenwick/${site}:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user opencadc:opencadc \
	   --name fenwick-${site} \
	   --network si-network \
	   ${SI_REPO_PATH}/fenwick:${FENWICK_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
done

# Launch ratiks
for site in ${sites}; do
    docker run -d \
	   --volume=${CONFIG_FOLDER}/ratik/${site}:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user opencadc:opencadc \
	   --name ratik-${site} \
	   --network si-network \
	   ${SI_REPO_PATH}/ratik:${RATIK_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
done

# Launch raven
docker run -d \
       --volume=${CONFIG_FOLDER}/raven:/config:ro \
       --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
       --user tomcat:tomcat \
       --name raven \
       --network si-network \
       ${SI_REPO_PATH}/raven:${RAVEN_VERSION}
# Wait to start up
sleep ${WAIT_SECONDS}

# Launch luskan
docker run -d \
       --volume=${CONFIG_FOLDER}/luskan:/config:ro \
       --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
       --user tomcat:tomcat \
       --name luskan \
       --network si-network \
       ${SI_REPO_PATH}/luskan:${LUSKAN_VERSION}
# Wait to start up
sleep ${WAIT_SECONDS}

# Instantiate haproxy
docker run -d \
       --volume=${CERTIFICATES_FOLDER}/:/config:ro \
       --volume=${LOGS_FOLDER}:/logs:rw \
       --volume=${CONFIG_FOLDER}/haproxy:/usr/local/etc/haproxy/:rw \
       -p ${HAPROXY_EXPOSED_PORT}:443 \
       --name haproxy \
       --network si-network \
       ${HAPROXY_IMAGE}
# Wait to populate
sleep ${WAIT_SECONDS_LONG}
