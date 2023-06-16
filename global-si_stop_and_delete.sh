#!/bin/bash

docker stop haproxy  && docker rm -f haproxy
docker stop critwall && docker rm -f  critwall 
docker stop fenwick  && docker rm -f  fenwick 
docker stop luskan   && docker rm -f  luskan  
docker stop minoc    && docker rm -f  minoc   
docker stop pg12db   && docker rm -f  pg12db  
