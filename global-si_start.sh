#!/bin/bash

# Pull all the containers precreated
docker pull swsrc/cadc-postgresql-12-dev
docker pull amigahub/cadc-haproxy
docker pull swsrc/minoc
#docker pull swsrc/luskan
docker pull images.opencadc.org/storage-inventory/luskan:0.6.0
#docker pull amigahub/fenwick
docker pull images.opencadc.org/storage-inventory/fenwick:0.5.4
#docker pull amigahub/crtiwall
docker pull images.opencadc.org/storage-inventory/critwall:0.4.0

# Default config files locate in ${CONFIG_FOLDER}
#$CONFIG_FOLDER="/home/ubuntu/software/src/cadc-storage-inventory"
$CONFIG_FOLDER="/home/gi-spsrc/software/global-si"
# Define where the data will live, directory need XXX permissons
$DATA_BASE_DIR="/data/swsrc"

# Instantiate cadc-postgresql
docker run -d --volume=${CONFIG_FOLDER}/config/postgresql:/config:ro \
              --volume=${CONFIG_FOLDER}/logs/postgresql:/logs:rw \
              -p 5432:5432 
              --name pg12db 
              swsrc/cadc-postgresql-12-dev:latest

# Wait to populate
sleep 7

# Instantiate cadc-minoc
docker run -d --user tomcat:tomcat  --link pg12db:pg12db \
       --volume=${CONFIG_FOLDER}/config/minoc:/config:ro \
       --volume=${DATA_BASE_DIR}:/data:rw \
       --name minoc \
       swsrc/minoc:latest

#Wait
sleep 3

# Instantiate cadc-luskan
docker run -d --user tomcat:tomcat  --link pg12db:pg12db \
       --volume=${CONFIG_FOLDER}/config/luskan:/config:ro \
       --name luskan \
       swsrc/luskan:latest
      # optionally add the below if baseStorageDir in cadc-tap-tmp.properties is not /tmp
      #--volume=/dir/on/host:/data:rw

#Wait 
sleep 3
# Instantiate cadc-fenwick
docker run -d --user opencadc:opencadc  --link pg10db:pg10db \
              --volume=${CONFIG_FOLDER}/config/fenwick:/config:ro 
              --name fenwick 
              amigahub/fenwick:latest
#Wait 
sleep 3
# Instantiate cadc-critwall
docker run -d --user opencadc:opencadc  --link pg10db:pg10db \
              --volume=${CONFIG_FOLDER}/config/critwall:/config:ro 
              --name critwall 
              amigahub/critwall:latest


#Create you own ssl cert without manual entry
openssl genrsa -out spsrc.key 2048
openssl req -new -subj "/C=ES/ST=Spain/L=Granada/O=IAA-CSIC/CN=localhost" -key spsrc.key -out spsrc.csr
openssl x509 -req rsa:2048 -days 365 -in spsrc.csr -signkey spsrc.key -out spsrc.crt
cat spsrc.key spsrc.crt >> ${CONFIG_FOLDER}/config/server-cert.pem


# Instantiate cadc-haproxy
docker run -d --volume=${CONFIG_FOLDER}/logs/haproxy:/logs:rw \
              --volume=${CONFIG_FOLDER}/certs:/config:ro \
	      --volume=${CONFIG_FOLDER}/config/haproxy:/usr/local/etc/haproxy/:rw \
              --link minoc:minoc \
              --link luskan:luskan \
              --link critwall:critwall \
              --link fenwick:fenwick \
              -p 443:443 \
              --name haproxy \
              amigahub/cadc-haproxy:latest

