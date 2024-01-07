#!/bin/bash

IFS=$'\n'
VPATH=/videos
CODESFILE="/opt/iso_639-2_codes.txt"
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
BOLD="\e[1m"
HIGHLIGHT="\e[7m"
NC="\e[0m"

usage(){
	printf "
USAGE:
	$0 [setSerieInfo|showTracks|setDefaultTrack|setTrackName] [ARGS]

	Commands are:
	- setTitle: Sets the title of the mkv files, based on the file's name, it requires no arguments since the title is calculated from the file name.
	- showTracks: Show the mkv file's tracks information, separated by video (V), audio (A), subtitles (S).   An asterix in front of a track, means it is set as default.   The displayed track information is basically track number and name.   And the end of the line, the file number and name of the file is displayed.
	- setDefaultTrack: Based on the information displayed with 'showTracks' command with the argument indicating the letter of the track's category followed by the track's name, as an example: 'A:Eng;S:English_SDH'.
	- setTrackName: Based on the information displayed with 'showTracks' command with the argument indicating the file, with the F prefix, track number with the T prefix and finally the new track name, e.g.: 'F:*;T:3:New_Track_Name'.   Not spaces allowed, all underscore characters will be converted into spaces through the process.   An asterisk as file number means all files.
	- convert: It searches for .mp4 or .avi files and subs, in order to create .mkv files using theses as tracks.   For the subs only .str are used and the script will search for those in the 'subs/[video file name without extension]/' path.   If the name of the subtitle file start with a number followed with and underscore, it will be used as a referential information about position and be removed as part of the track name, any underscore in the remaining name, will be converted into a space in the track name.
	If only one video file is found, it will look for .srt files ending like '.[LANG].srt', where LANG is the name of the subtitle language, like 'EN' or 'ES', letters case are ignored.  Any srt file found with language definition will be added as a subtitle track, to the new file.

"
}

if [ $# -eq 0 ]; then
	usage
	exit 0
fi

setTitle(){
	FILES=$(find $VPATH -iname '*.mkv' )
	for i in $FILES ; do
		FILETITLE=$(basename "$i" .mkv)
		printf "> Setting title '%s' to '%s'\n" "$FILETITLE" "$i"
		mkvpropedit "$i" --edit info --set "title=$FILETITLE"
		if [ $? -ne 0 ]; then
			exit 1
		fi
		echo
	done
}

getMatchInfo(){
	# printf ">> %s\n" "$1"
	TYPE=$(echo "$1" | grep "+ Track type:")
	TYPE=${TYPE#*: }
	TRNumber=$(echo "$1" | grep "+ Track number:")
	TRNumber=${TRNumber##*: }
	TRNumber=${TRNumber%*)}
	TRN=$(echo "$1" | grep "+ Track number:")
	TRN=${TRN#*|  + Track number: }
	TRN=${TRN% (track ID for mkvmerge & mkvextract:*}
	Lang=$(echo "$1" | grep -E "Language( \([^)]*\))?:" | head -n 1)
	Lang=${Lang#*: }
	DTrack=$(echo "$1" | grep '+ "Default track" flag:')
	DTrack=${DTrack#*: }
	NAME=$(echo "$1" | grep '+ Name:')
	NAME=${NAME#*: }
	[ -z "$NAME" ] && NAME="$Lang"
	# printf -- "> TYPE:%s;TRNumber:%s;TRN:%s;Lang:%s;DTrack:%s;NAME:%s\n" "$TYPE" "$TRNumber" "$TRN" "$Lang" "$DTrack" "$NAME"
}

setDefaultTrack(){
	printf -- "> Setting default tracks flags\n"
	echo "> $1"
	ARGS="$1;"
	ANAME=$(echo "$ARGS" | grep -Eo "A:[^;]+" )
	ANAME=${ANAME#A:*}
	ANAME=${ANAME//_/ }
	SNAME=$(echo "$ARGS" | grep -Eo "S:[^;]+" )
	SNAME=${SNAME#S:*}
	SNAME=${SNAME//_/ }
	printf -- "> Audio:%s - Subtitle:%s\n" "$ANAME" "$SNAME"
	if [ -z "$ANAME$SNAME" ]; then
		printf -- "> Error: no configuration detected\n"
		exit 1
	fi

	FILES=$(find $VPATH -iname "*.mkv" )
	for i in $FILES ; do
		printf -- "> Analizing file \'$(basename \"$i\")\'\n"
		INFO=$(mkvinfo "$i" | sed '/|+ Tags/,$d' | sed '/|+ Chapters/,$d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
		PATTERN='@[^@]*'
		ARGS=''
		while [[ "$INFO" =~ $PATTERN ]]; do
			FLAG=0
			getMatchInfo "${BASH_REMATCH[0]}"
			printf -- "> Checking track $TRN\n"
			case "$TYPE" in
				video)
					INFO=${INFO/"${BASH_REMATCH[0]}"/}
					continue
					;;
				audio)
					if [ -z "$ANAME" ];then
						INFO=${INFO/"${BASH_REMATCH[0]}"/}
						continue
					fi
					[ "$NAME" == "$ANAME" ] && FLAG=1
					;;
				subtitles)
					if [ -z "$SNAME" ];then
						INFO=${INFO/"${BASH_REMATCH[0]}"/}
						continue
					fi
					[ "$NAME" == "$SNAME" ] && FLAG=1
					;;
				*)
					printf "> Missing track:\n%s\n" "$INFO"
					;;
			esac
			ARGS="$ARGS --edit track:$TRN --set flag-default=$FLAG"
			INFO=${INFO/"${BASH_REMATCH[0]}"/}
		done
		LINE=$(printf -- "/usr/bin/mkvpropedit \"%s\" %s" "$i" "$ARGS")
		printf -- "> Executing:\n%s\n" "$LINE"
		eval $LINE
		if [ $? -ne 0 ]; then
			printf "* FAILURE\n"
		else
			printf "* SUCCESS\n"
		fi
		echo
	done
}

showTracks() {
	FILES=$(find $VPATH  \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \)  | sort )
	COUNTER=0
	for i in $FILES ; do
		COUNTER=$(( COUNTER + 1 ))
		if [ "${i##*.}" != "mkv" ]; then
			printf -- "%.2d:${HIGHLIGHT}%s${NC}\n" "$COUNTER" "$(basename $i)"
			continue
		fi
		INFO=$(mkvinfo "$i" | sed '/|+ Tags/,$d' | sed '/|+ Chapters/,$d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
		TITLE=$(echo "$INFO" | grep "| + Title: " | sed "s/| + Title: //")
		if [ -z "$TITLE" ]; then
			TITLE="-"
		fi
		PATTERN='@[^@]*'
		# printf "> Track info:\n%s\n" "$INFO"
		VTRACK=''
		ATRACK=''
		STRACK=''
		while [[ "$INFO" =~ $PATTERN ]]; do
			getMatchInfo "${BASH_REMATCH[0]}"
			[ "$DTrack" != "0" ] && DT="*"
			case $TYPE in
				video)
					VTRACK="$VTRACK;${DT}${TRN}:${Lang}"
					;;
				audio)
					ATRACK="$ATRACK;${DT}${TRN}:${NAME}"
					;;
				subtitles)
					STRACK="$STRACK;${DT}${TRN}:${NAME}"
					;;
				*)
					# printf "> Missing track:\n%s\n" "$INFO"
					;;
			esac
			unset DT
			INFO=${INFO/"${BASH_REMATCH[0]}"/}
		done
		VTRACK=${VTRACK#*;}
		ATRACK=${ATRACK#*;}
		STRACK=${STRACK#*;}
		printf "%.2d:${BOLD}%s${NC}\n${BLUE}%s\n${YELLOW}V=%s ${RED}A=%s ${GREEN}S=%s${NC}\n" \
			"$COUNTER" "$(basename $i)" "${TITLE}"  "$VTRACK" "$ATRACK" "$STRACK"
	done
	if [ $COUNTER -eq 0 ]; then
		printf -- "< No mkv files found!\n"
	fi
}

__setTrackName(){
	printf -- "> Editing file \'$(basename \"$1\")\'\n"
	mkvpropedit "$1" --edit track:$2 --set name="$3"
}

setTrackName(){
	printf -- "> Setting file track name:\n"
	printf "${BOLD}+ Write file number (* to all): _ "
	read FileNumber
	printf "+ Write track number: _ "
	read TrackNumber
	printf "+ Write new name: _ ${NC}"
	read Name
	Name=${Name//_/ }
	# printf -- "> File:%s - Track:%s - Name:%s\n" "$FileNumber" "$TrackNumber" "$Name"

	if [ -z "$FileNumber" -o -z "$TrackNumber" -o -z "$Name" ]; then
		printf -- "> Error: not enough data to complete the change\n"
		exit 1
	fi

	COUNTER=0
	FILES=$(find $VPATH  \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \)  | sort )
	for i in $FILES ; do
		if [ "$FileNumber" == "*" ]; then
			if [ "${i##*.}" != "mkv" ]; then
				printf -- "> Skipping file \'$(basename \"$1\")\'\n"
				continue
			fi
			__setTrackName "$i" "$TrackNumber" "$Name"
		else
			COUNTER=$(( COUNTER + 1 ))
			[ $COUNTER -ne $FileNumber ] && continue
			__setTrackName "$i" "$TrackNumber" "$Name"
			break
		fi
	done
}

convertToMKV(){
	printf -- "> Converting files to mkv\n"
	FILES=$(find $VPATH -iname "*.mp4" -o -iname "*.avi")
	FILES_COUNT=$(echo "$FILES" | wc -l)
	if [ "$FILES_COUNT" -eq 1 ]; then
		# This is probably a movie, a single video file, with probably a single sub title in root folder
		printf "> Found movie\n%s\n" "$FILES"
		SUBS=$(find $VPATH -iname "*.srt")
		SUBS_COUNT=$(echo "$SUBS" | wc -l)
		FILENAME=$(basename "$FILES")
		FILENAME=${FILENAME%.*}
		ARGS=$(printf -- '-o "%s.mkv" "%s" --title "%s"' "${FILES%.*}" "$FILES" "$FILENAME")
		if [ -n "$SUBS" ]; then
			printf "> Found %d subs:\n%s\n" "$SUBS_COUNT" "$SUBS"
			for i in $SUBS; do
				echo "$i" | grep -Eo '\.[a-z]{2,4}\.' > /dev/null
				if [ $? -eq 0 ]; then
					LANG=$(echo "$i" | grep -Eo '\.[a-z]{2,4}\.' | grep -Eo "[a-z]{2,4}" | tr "[:lower:]" "[:upper:]")
					printf "> Found lang %s in file '%s'\n%s\n" "$LANG" "$i" "$(file $i)"
					ARGS=$(printf -- '%s --language 0:%s --track-name 0:"%s" "%s"' "$ARGS" "$LANG" "$LANG" "$i" | sed 's/\n//')
				fi
			done
		fi
		__executeConvertion
	else
		for i in $FILES ; do
			FILENAME=$(basename "$i")
			FILENAME=${FILENAME%.*}
			printf "> Analizing '%s'\n" "$FILENAME"
			ARGS=$(printf -- '-o "%s.mkv" "%s" --title "%s"' "${i%.*}" "$i" "$FILENAME")
			FILEPATH=$(dirname $i)
			SUBSPATH=$(find "$FILEPATH" -iname subs)
			if [ -d "$SUBSPATH/$FILENAME" ]; then
				SUBSCOUNT=0
				for j in $(cd "$SUBSPATH/$FILENAME" && ls -1 *.srt | sort -n); do
					# subs format: N_Name.srt
					[ $SUBSCOUNT -eq 0 ] && printf -- "- Subtitles found!\n"
					SUBNAME=$(basename $j .srt)
					echo "$SUBNAME" | grep -E '^[0-9]+_' > /dev/null 2>&1
					[ $? -eq 0 ] && SUBNAME=${SUBNAME#*_}
					SUBNAME=${SUBNAME//_/ }
					SUBCODE=$(grep -Ii "[[:space:]]${SUBNAME%* SDH}\$" $CODESFILE | head -n 1 | grep -Eo "^[a-zA-Z]+")
					if [ -z "$SUBCODE" ]; then
						SUBCODE=$(grep -Ii "${SUBNAME%* SDH}" $CODESFILE | head -n 1 | grep -Eo "^[a-zA-Z]+")
					fi
					ARGS=$(printf -- '%s --language 0:%s --track-name 0:"%s" "%s"' "$ARGS" "$SUBCODE" "$SUBNAME" "$SUBSPATH/$FILENAME/$j" | sed 's/\n//')
					SUBSCOUNT=$(( SUBSCOUNT + 1 ))
				done
				echo
			fi
			__executeConvertion
		done
	fi
}

__executeConvertion(){
	if [ -n "$ARGS" ]; then
		printf -- "- Executing 'mkvmerge %s'\n" "$ARGS"
		eval "mkvmerge $ARGS"
		if [ $? -ne 0 ]; then
			printf -- "< Error executing command\n"
			exit 1
		fi
		printf "\n\n"
	fi
}

COMMAND=$1
shift
case "$COMMAND" in
	"")
		usage
		;;
	setTitle)
		setTitle  $@
		;;
	showTracks)
		showTracks $@
		;;
	setDefaultTrack)
		setDefaultTrack $@
		;;
	setTrackName)
		setTrackName $*
		;;
	convert)
		convertToMKV $@
		;;
	*)
		printf -- "ERROR: Command '%s' not valid\n" "$COMMAND"
		exit 2
		;;
esac
