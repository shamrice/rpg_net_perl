#!/bin/bash

# this script will build the docker image to your local docker repo and 
# start the image in a new local container with the configs passed.

echo "Building docker image..."
echo "========================"
docker build -t rpg-server .
echo
echo "Checking if existing container is already running..."
echo "===================================================="
if docker container ls -la | grep rpg-server-dev-container; then 
    echo "Container already running. Stopping..."
    docker stop rpg-server-dev-container
    echo "Removing existing container..."
    docker rm -f rpg-server-dev-container     
fi 
echo 
echo "Running image in new container..."
echo "================================="
docker run --name rpg-server-dev-container -e RPG_DUMP_CONFIG='1' -e PORT='3000' -e RUN_MODE='development' -d -p 8082:3000 rpg-server

echo

