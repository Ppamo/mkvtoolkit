#!/usr/bin/bash

IFS=$'\n'
VPATH=/videos
COMMAND=${COMMAND:=$1}

usage(){
	printf "
USAGE:
	$0 [setSerieInfo|showTracks|setDefaultTrack] [ARGS]

	Commands are:
	- setTitle: Sets the title of the mkv files found in the /videos folder, based on the file's name
	- showTracks: Show the mkv file's tracks information, separated by video (V), audio (A), subtitles (S).   An asterix in front of a track, means it is set as default, the displayed track information is basically track number and name.   And the end of the line, the  name of the file is displayed
	- setDefaultTrack: Based on the information displayed in 'showTracks' command with the argument indicating the letter of the track's category followed by the track's name, as an example: 'A:Eng;S:SDH'
"
}

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
	Lang=$(echo "$1" | grep -E "Language( \([^)]*\))?:")
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
	echo "> $ARGS"
	ARGS="${ARGS};"
	ANAME=$(echo "$ARGS" | grep -Eo "A:[^;]+" )
	ANAME=${ANAME#A:*}
	SNAME=$(echo "$ARGS" | grep -Eo "S:[^;]+" )
	SNAME=${SNAME#S:*}
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
	FILES=$(find $VPATH -iname "*.mkv" )
	COUNTER=0
	for i in $FILES ; do
		COUNTER=$(( COUNTER + 1 ))
		INFO=$(mkvinfo "$i" | sed '/|+ Tags/,$d' | sed '/|+ Chapters/,$d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
		PATTERN='@[^@]*'

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
		printf "V=%s A=%s S=%s - %s:%s\n" "$VTRACK" "$ATRACK" "$STRACK" "$COUNTER" "$(basename $i)"
	done
}

__setTrackName(){
	printf -- "> Editing file \'$(basename \"$1\")\'\n"
	mkvpropedit "$1" --edit track:$2 --set name="$3"
}

setTrackName(){
	printf -- "> Setting file track name:\n"
	# echo "> $ARGS"
	ARGS="${ARGS}"
	FileNumber=$(echo "$ARGS" | grep -Eo 'F:[^;]*')
	FileNumber=${FileNumber#*:}
	TrackNumber=$(echo "$ARGS" | grep -Eo "T:[^;]*")
	TrackNumber=${TrackNumber#*:}
	Name=$(echo "$ARGS" | grep -Eo ';[^;]*$')
	Name=${Name#*;}
	# printf -- "> File:%s - Track:%s - Name:%s\n" "$FileNumber" "$TrackNumber" "$Name"

	if [ -z "$FileNumber" -o -z "$TrackNumber" -o -z "$Name" ]; then
		printf -- "> Error: no configuration detected\n"
		exit 1
	fi

	COUNTER=0
	FILES=$(find $VPATH -iname "*.mkv" )
	for i in $FILES ; do
		if [ "$FileNumber" == "*" ]; then
			__setTrackName "$i" "$TrackNumber" "$Name"
		else
			COUNTER=$(( COUNTER + 1 ))
			[ $COUNTER -ne $FileNumber ] && continue
			__setTrackName "$i" "$TrackNumber" "$Name"
			break
		fi
	done
}

case "$COMMAND" in
	"")
		usage;
		;;
	setTitle)
		setTitle
		;;
	showTracks)
		showTracks
		;;
	setDefaultTrack)
		setDefaultTrack
		;;
	setTrackName)
		setTrackName
		;;
	*)
		printf -- "ERROR: Command '%s' not valid\n" "$COMMAND"
		exit 2
		;;
esac
