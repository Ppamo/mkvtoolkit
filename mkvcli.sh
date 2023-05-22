#!/usr/bin/bash

IFS=$'\n'

setSerieFileTitle(){
	FILES=$(find /videos -iname '*.mkv' )
	for i in $FILES ; do
		FILETITLE=$(basename "$i" .mkv)
		TEXT=$(dirname "$i")
		SEASON=$(basename "$TEXT")
		TEXT=$(dirname "$i")
		SERIENAME=$(dirname "$TEXT")
		SERIENAME=$(basename "$SERIENAME")
		TITLE=${SERIENAME##* - }
		YEAR=${SERIENAME%% - *}
		TEXT=${SERIENAME% - *}
		AUTHOR=${TEXT#* - }

		printf "> Setting title '%s' to '%s'\n" "$FILETITLE" "$i"
		mkvpropedit "$i" --edit info --set "title=$FILETITLE"
		if [ $? -ne 0 ]; then
			exit 1
		fi
		echo
	done
}

getMatchInfo(){
	TYPE=$(echo "$1" | grep "+ Track type:")
	TYPE=${TYPE#*: }
	TRNumber=$(echo "$1" | grep "+ Track number:")
	TRNumber=${TRNumber##*: }
	TRNumber=${TRNumber%*)}
	TRN=$(echo "$1" | grep "+ Track number:")
	TRN=${TRN#*|  + Track number: }
	TRN=${TRN% (track ID for mkvmerge & mkvextract:*}
	Lang=$(echo "$1" | grep -E "Language \([^)]*\):")
	Lang=${Lang#*: }
	DTrack=$(echo "$1" | grep '+ "Default track" flag:')
	DTrack=${DTrack#*: }
	NAME=$(echo "$1" | grep '+ Name:')
	NAME=${NAME#*: }
}

setDefaultTrack(){
	printf -- "> Setting default tracks flags\n"
	ARGS="${ARGS};"
	ANAME=$(echo "$ARGS" | grep -Eo "A:[^;]+" )
	ANAME=${ANAME#A:*}
	SNAME=$(echo "$ARGS" | grep -Eo "S:[^;]+" )
	SNAME=${SNAME#S:*}

	FILES=$(find /videos -iname '*.mkv' )
	for i in $FILES ; do
		printf -- "> Analizing file \'$(basename $i)\'\n"
		INFO=$(mkvinfo $i | sed "s/@/ /g" | sed "s/| + Track/@/g")
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
					[ "$NAME" == "$ANAME" ] && FLAG=1
					;;
				subtitles)
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
		# printf -- "> Executing:\n%s\n" "$LINE"
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
	FILES=$(find /videos -iname '*.mkv' )
	for i in $FILES ; do
		INFO=$(mkvinfo $i | sed "s/@/ /g" | sed "s/| + Track/@/g")
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
					printf "> Missing track:\n%s\n" "$INFO"
					;;
			esac
			unset DT
			INFO=${INFO/"${BASH_REMATCH[0]}"/}
		done
		VTRACK=${VTRACK#*;}
		ATRACK=${ATRACK#*;}
		STRACK=${STRACK#*;}
		printf "V=%s A=%s S=%s - '%s'\n" "$VTRACK" "$ATRACK" "$STRACK" "$(basename $i)"
	done
}

case "$COMMAND" in
	setSerieInfo)
		setSerieFileTitle
		;;
	showTracks)
		showTracks
		;;
	setDefaultTrack)
		setDefaultTrack
		;;
	*)
		printf -- "ERROR: Command '%s' not valid\n" "$COMMAND"
		exit 2
		;;
esac
