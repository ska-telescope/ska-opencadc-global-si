#!/bin/bash

# assumes that image versions in vars.yaml have been pulled via fetch-latest-images.sh and that vars.yaml has been updated
# will remove existing running containers and spin them up again

# "0" means it will not be touched, "1" means it will be restarted; CAREFUL with POSTGRES!
POSTGRES=0 # CAREFUL with POSTGRES! if removing do at docker commit -m "message" pg12db repo/name:tag first; then replace default image with repo/name:tag
REG=0
BALDUR=0
FENWICK=1
RATIK=0
RAVEN=0
LUSKAN=0
HAPROXY=0  # will be restarted in any case, but if set to 1 running container will be removed

# for fenwick and ratik we have one instance per site
sites='cadc swesrc spsrc swisrc'

set -e

# create a tempory set of variables from the (hopefully) existing vars.yaml
cat vars.yaml | sed 's/---/#/g' | sed 's/: /=/g' | sed 's/{{/${/g' | sed 's/}}/}/g' > /tmp/vars.sh
source /tmp/vars.sh

if ! [[ ${POSTGRES} -eq 0 ]]; then
    echo "Removing and restarting postgres db."
    sudo docker rm -f pg12db
    # Instantiate postgresql
    sudo docker run -d \
	   --volume=${CONFIG_FOLDER}/postgresql:/config:ro \
	   --volume=${LOGS_FOLDER}:/logs:rw \
	   -p 5432:5432 \
	   --name pg12db \
	   --network si-network \
	   ${POSTGRESQL_IMAGE}
    # Wait to populate
    sleep ${WAIT_SECONDS_LONG}
fi

if ! [[ ${REG} -eq 0 ]]; then
    echo "Removing and restarting registry."
    sudo docker rm -f reg
    # Launch global registry
    sudo docker run -d \
	   --volume=${CONFIG_FOLDER}/reg:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user tomcat:tomcat \
	   --name reg \
	   --network si-network \
	   ${CORE_REPO_PATH}/reg:${REG_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
fi

if ! [[ ${BALDUR} -eq 0 ]]; then
    echo "Removing and restarting baldur."
    sudo docker rm -f baldur
    # Launch baldur
    sudo docker run -d \
	   --volume=${CONFIG_FOLDER}/baldur:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user tomcat:tomcat \
	   --name baldur \
	   --network si-network \
	   ${SI_REPO_PATH}/baldur:${BALDUR_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
fi

if ! [[ ${FENWICK} -eq 0 ]]; then
    # Launch fenwicks
    for site in ${sites}; do
	echo "Removing and restarting fenwick-${site}"
	sudo docker rm -f fenwick-${site}
	sudo docker run -d \
	       --volume=${CONFIG_FOLDER}/fenwick/${site}:/config:ro \
	       --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	       --user opencadc:opencadc \
	       --name fenwick-${site} \
	       --network si-network \
	       ${SI_REPO_PATH}/fenwick:${FENWICK_VERSION}
	# Wait to start up
	sleep ${WAIT_SECONDS}
    done
fi

if ! [[ ${RATIK} -eq 0 ]]; then
    # Launch ratiks
    for site in ${sites}; do
	echo "Removing and restarting ratik-${site}"
	sudo docker rm -f ratik-${site}
	sudo docker run -d \
	       --volume=${CONFIG_FOLDER}/ratik/${site}:/config:ro \
	       --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	       --user opencadc:opencadc \
	       --name ratik-${site} \
	       --network si-network \
	       ${SI_REPO_PATH}/ratik:${RATIK_VERSION}
	# Wait to start up
	sleep ${WAIT_SECONDS}
    done
fi

if ! [[ ${RAVEN} -eq 0 ]]; then
    echo "Removing and restarting raven."
    sudo docker rm -f raven
    # Launch raven
    sudo docker run -d \
	   --volume=${CONFIG_FOLDER}/raven:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user tomcat:tomcat \
	   --name raven \
	   --network si-network \
	   ${SI_REPO_PATH}/raven:${RAVEN_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
fi

if ! [[ ${LUSKAN} -eq 0 ]]; then
    echo "Removing and restarting luskan."
    sudo docker rm -f luskan
    # Launch luskan
    sudo docker run -d \
	   --volume=${CONFIG_FOLDER}/luskan:/config:ro \
	   --volume=${CONFIG_FOLDER}/cadc-registry.properties:/config/cadc-registry.properties:ro \
	   --user tomcat:tomcat \
	   --name luskan \
	   --network si-network \
	   ${SI_REPO_PATH}/luskan:${LUSKAN_VERSION}
    # Wait to start up
    sleep ${WAIT_SECONDS}
fi

if ! [[ ${HAPROXY} -eq 0 ]]; then
    echo "Removing and restarting haproxy."
    sudo docker rm -f haproxy
    # Instantiate haproxy
    sudo docker run -d \
	   --volume=${CERTIFICATES_FOLDER}/:/config:ro \
	   --volume=${LOGS_FOLDER}:/logs:rw \
	   --volume=${CONFIG_FOLDER}/haproxy:/usr/local/etc/haproxy/:rw \
	   -p ${HAPROXY_EXPOSED_PORT}:443 \
	   --name haproxy \
	   --network si-network \
	   ${HAPROXY_IMAGE}
    # Wait to populate
    sleep ${WAIT_SECONDS_LONG}
else
    echo "Restarting haproxy."
    sudo docker restart haproxy
fi
