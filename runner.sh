#!/usr/bin/bash

APP=mkvtoolkit
VERSION=0.1.1
IMAGE=${APP}.v${VERSION}
REBUILD=${REBUILD:-0}

if [ -z "$VIDEOS" ]; then
	printf "ERROR: VIDEOS env var is empty\n"
	exit 0
fi
if [ ! -d "$VIDEOS" ]; then
	printf "ERROR: VIDEO folder does not exist\n"
	exit 0
fi

if [ $REBUILD -eq 1 ]; then
	docker images --format "{{.Repository}}:{{.Tag}}" | grep $IMAGE > /dev/null
	if [ $? -eq 0 ]; then
		printf -- "> Remving old image $IMAGE\n"
		docker rmi $IMAGE
	fi
fi

docker images --format "{{.Repository}}:{{.Tag}}" | grep $IMAGE > /dev/null
if [ $? -ne 0 ]; then
	printf "> Building new image $IMAGE\n"
	docker build --platform linux/amd64 --progress plain -t $IMAGE .
	if [ $? -ne 0 ]; then
		printf -- "ERROR: Failed to build new image\n"
		exit 1
	fi
fi

printf -- "> Starting new container\n"
docker run -ti --name $APP --rm --platform linux/amd64 \
	--volume "$VIDEOS":/videos \
	--volume $PWD:/res \
	--volume /Volumes/Backups:/Backups \
	--entrypoint bash \
	--env MEDIATYPE=$MEDIATYPE \
	$IMAGE
