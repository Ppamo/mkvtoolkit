#!/usr/bin/bash

APP=mkvtoolkit
VERSION=0.1.3
IMAGE=${APP}:v${VERSION}
REBUILD=${REBUILD:-0}
DEV=${DEV:-0}
VIDEOS=$1
COMMAND=$2
BOLD="\033[1m"
RESET="\033[0m"

usage(){
	printf -- "
USAGE:
	$0 [FILES_PATH] [COMMAND] [ARGS]

This script start a container and execute a set of tools to get and set information about mkv files.
The COMMAND indicates which action will be executed:
	- ${BOLD}setTitle${RESET}: Sets the title of the mkv files found in the /videos folder, based on the file's name
	- ${BOLD}showTracks${RESET}: Show the mkv file's tracks information, separated by video (V), audio (A), subtitles (S).   An asterix in front of a track, means it is set as default, the displayed track information is basically track number and name.   And the end of the line, the  name of the file is displayed
	- ${BOLD}setDefaultTrack${RESET}: Based on the information displayed in 'showTracks' command with the argument indicating the letter of the track's category followed by the track's name, as an example: 'A:Eng;S:SDH'
	- ${BOLD}setTrackName${RESET}: Based on the information displayed in 'showTracks' output with the argument indicating the file, with the F prefix, track number with the T prefix and finally the new track name, e.g.: 'F:*;T:3:New_Track_Name'.   Not spaces allowed, all underscore characters will be converted into spaces through the process.   An asterisk as file number means all files.
	- ${BOLD}convert${RESET}: It searches for .mp4 or .avi files and subs, in order to create .mkv files using theses as tracks.   For the subs only .str are used and the script will search for those in the 'subs/[video file name without extension]/' path.   If the name of the subtitle file start with a number followed with and underscore, it will be used as a referential information about position and be removed as part of the track name, any underscore in the remaining name, will be converted into a space in the track name.

The FILES_PATH arg is the path to a folder with videos and subtitles files in it, it can be the root of nested folders, cos the script will start with a find command to get all files in the folder.   The PATH must be absolute, cos it wull get mounted to the container.

The first time this script runs the image will be built, so it will take more than usual.

"
}

if [ $# -eq 0 ]; then
	usage
	exit 0
fi

if [ -z "$VIDEOS" ]; then
	printf "ERROR: FILES_PATH path not set\n"
	exit 0
fi
if [ ! -d "$VIDEOS" ]; then
	printf "ERROR: '%s' folder does not exist\n" "$VIDEOS"
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

if [ $DEV -eq 1 ]; then
	docker run -ti --name $APP --rm --platform linux/amd64 \
		--volume "$VIDEOS":/videos \
		--volume "$PWD":/app \
		--entrypoint /bin/bash \
		--workdir /app \
		$IMAGE
else
	docker run -ti --name $APP --rm --platform linux/amd64 \
		--volume "$VIDEOS":/videos \
		$IMAGE "$COMMAND" $@
fi
