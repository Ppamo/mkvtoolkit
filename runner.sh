#!/usr/bin/bash

APP=mkvtoolkit
VERSION=0.1.1
IMAGE=${APP}.v${VERSION}
REBUILD=${REBUILD:-0}
COMMAND=$1
VIDEOS=$2
BOLD="\033[1m"
RESET="\033[0m"

usage(){
	printf -- "
USAGE:
	$0 [COMMAND] [MKV_FOLDER_PATH]

This script start a container and execute a set of tools to get and set information about mkv files.
The COMMAND indicates which action will be executed, there are 3 options:
	- ${BOLD}setTitle${RESET}: Sets the title of the mkv files found in the /videos folder, based on the file's name
	- ${BOLD}showTracks${RESET}: Show the mkv file's tracks information, separated by video (V), audio (A), subtitles (S).   An asterix in front of a track, means it is set as default, the displayed track information is basically track number and name.   And the end of the line, the  name of the file is displayed
	- ${BOLD}setDefaultTrack${RESET}: Based on the information displayed in 'showTracks' command with the argument indicating the letter of the track's category followed by the track's name, as an example: 'A:Eng;S:SDH'

The MKV_FOLDER_PATH arg is the path to a folder with mkv files in it, it can be nested folders, cos the script will start with a find command to get all mkv files in the folder.

The first time this script runs the image will be built, so it will take more than usual

"
}

if [ $# -eq 0 ]; then
	usage
	exit 0
fi

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
shift
shift
docker run -ti --name $APP --rm --platform linux/amd64 \
	--volume "$VIDEOS":/videos \
	$DOCKER_ARGS \
	$IMAGE "$COMMAND" $@
