#!/bin/bash

IFS=$'\n'
VPATH=/videos
BPATH=/videos/converted
CODESFILE="/opt/iso_639-2_codes.txt"
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
BOLD="\e[1m"
HIGHLIGHT="\e[4m"
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
	__getMkvVideoFiles
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
	NAME=$(echo "$1" | grep '+ Name:' | head -n 1)
	NAME=${NAME#*: }
	[ -z "$NAME" ] && NAME="$Lang"
	# printf -- "> TYPE:%s;TRNumber:%s;TRN:%s;Lang:%s;DTrack:%s;NAME:%s\n" "$TYPE" "$TRNumber" "$TRN" "$Lang" "$DTrack" "$NAME"
}

setDefaultTrack(){
	printf -- "> Setting default tracks flags\n"
	ARGS="$1;"
	FNAME=$(echo "$ARGS" | grep -Eo "F:[^;]+" )
	FNAME=${FNAME#F:*}
	ANAME=$(echo "$ARGS" | grep -Eo "A:[^;]+" )
	ANAME=${ANAME#A:*}
	ANAME=${ANAME//_/ }
	SNAME=$(echo "$ARGS" | grep -Eo "S:[^;]+" )
	SNAME=${SNAME#S:*}
	SNAME=${SNAME//_/ }
	if [ -z "$ANAME$SNAME" ]; then
		printf -- "> Error: no configuration detected\n"
		exit 1
	fi
	
	__getVideoFiles
	for i in $FILES ; do
		if [[ ! "$i" =~ $FNAME ]]; then
			printf "> Skipping file $i\n"
			continue
		fi

		printf -- "> Analizing file \'$(basename \"$i\")\'\n"
		INFO=$(mkvinfo "$i" | sed '/|+ Tags/,$d' | sed '/|+ Chapters/,$d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
		PATTERN='@[^@]*'
		ARGS=''
		AFOUND=0
		SFOUND=0
		while [[ "$INFO" =~ $PATTERN ]]; do
			FLAG=0
			getMatchInfo "${BASH_REMATCH[0]}"
			case "$TYPE" in
				video)
					INFO=${INFO/"${BASH_REMATCH[0]}"/}
					# printf -- "> Checking video track $TRN ($NAME)\n"
					continue
					;;
				audio)
					if [ -z "$ANAME" ];then
						INFO=${INFO/"${BASH_REMATCH[0]}"/}
						continue
					fi
					# printf -- "> Checking audio track $TRN ($NAME)\n"
					if [[ "$NAME" == $ANAME ]]; then
						FLAG=1
						AFOUND=$(( AFOUND+1 ))
						printf -- "> Match audio track $TRN ${BOLD}$NAME${NC}\n"
					fi
					;;
				subtitles)
					if [ -z "$SNAME" ];then
						INFO=${INFO/"${BASH_REMATCH[0]}"/}
						continue
					fi
					if [[ $NAME == $SNAME ]]; then
						FLAG=1
						SFOUND=$(( SFOUND+1 ))
						printf -- "> Match sub track $TRN ${BOLD}$NAME${NC}\n"
					fi
					;;
				*)
					printf "> Missing track:\n%s\n" "$INFO"
					;;
			esac
			ARGS="$ARGS --edit track:$TRN --set flag-default=$FLAG"
			INFO=${INFO/"${BASH_REMATCH[0]}"/}
		done
		if [ $(( $AFOUND + $SFOUND )) -eq 0 ]; then
			printf "> No matches found\n"
			continue
		fi
		if [ $AFOUND -gt 1 -o $SFOUND -gt 1 ]; then
			printf "> More than 1 match found\n"
			continue
		fi
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
	__getVideoFiles
	COUNTER=0
	for i in $FILES ; do
		if [ "${i##*.}" != "mkv" ]; then
			printf -- "%.2d\n${HIGHLIGHT}%s${NC}\n" "$COUNTER" "$(basename $i)"
			continue
		fi
		COUNTER=$(( COUNTER + 1 ))
		INFO=$(mkvinfo "$i" | sed '/|+ Tags/,$d' | sed '/|+ Chapters/,$d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
		TITLE=$(echo "$INFO" | grep "| + Title: " | sed "s/| + Title: //")
		if [ -z "$TITLE" ]; then
			TITLE="-"
		fi
		echo "$INFO" | grep "+ Track" >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			INFO=$(mkvinfo --track-info "$i" | grep -v "Simple block: " | grep -v "Frame with size" | grep -v "+ Cluster" | grep -v "+ Block" | grep -v "subentries will be skipped" | grep -v "Statistics for track number" | sed '0,/+ Tracks/d' | sed "s/@/ /g" | sed "s/| + Track/@/g")
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
					printf "> Undetected track:\n%s\n" "$INFO"
					;;
			esac
			unset DT
			INFO=${INFO/"${BASH_REMATCH[0]}"/}
		done
		VTRACK=${VTRACK#*;}
		ATRACK=${ATRACK#*;}
		STRACK=${STRACK#*;}
		printf "%.2d\n${BOLD}%s${NC}\n${BLUE}%s\n${YELLOW}V=%s ${RED}A=%s ${GREEN}S=%s${NC}\n" \
			"$COUNTER" "$(basename $i)" "${TITLE}"  "$VTRACK" "$ATRACK" "$STRACK"
	done
	if [ $COUNTER -eq 0 ]; then
		printf -- "< No mkv files found!\n"
	fi
}

__setTrackName(){
	OLDIFS=$IFS
	FileName=$(basename "$1")
	IFS=','
	for i in $2; do
		printf -- "> Editing track %s of file \'%s\'\n" "$i" "$FileName"
		mkvpropedit "$1" --edit track:$i --set name="$3"
	done
	IFS=$OLDIFS
}

setTrackName(){
	printf -- "> Setting file track name:\n"
	printf "${BOLD}+ Write file number (* to all): _ "
	read FileNumber
	if [[ ! $FileNumber =~ [0-9]+|\* ]]; then
		printf "> Invalid file number\n"
		return
	fi
	printf "+ Write track number: _ "
	read TrackNumber
	if [[ ! $TrackNumber =~ [0-9]+ ]]; then
		printf "> Invalid track number\n"
		return
	fi
	printf "+ Write new name: _ ${NC}"
	read Name
	Name=${Name//_/ }
	# printf -- "> File:%s - Track:%s - Name:%s\n" "$FileNumber" "$TrackNumber" "$Name"

	if [ -z "$FileNumber" -o -z "$TrackNumber" -o -z "$Name" ]; then
		printf -- "> Error: not enough data to complete the change\n"
		exit 1
	fi

	COUNTER=0
	__getVideoFiles
	for i in $FILES ; do
		if [ "$FileNumber" == "*" ]; then
			if [ "${i##*.}" != "mkv" ]; then
				printf -- "> Skipping file \'$(basename \"$i\")\'\n"
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

addTrack(){
	printf -- "> Adding track to mkv file:\n"
	printf "${BOLD}+ Write file number (* to all): _ "
	read FileNumber

	[ -z "$FileNumber" ] && FileNumber="*"

	if [[ ! $FileNumber =~ [0-9]+|\* ]]; then
		printf "> Invalid file number\n"
		return
	fi

	__getMkvVideoFiles
	for i in $FILES ; do
		if [ "$FileNumber" == "*" ]; then
			if [ "${i##*.}" != "mkv" ]; then
				printf -- "> Skipping file \'$(basename \"$i\")\'\n"
				continue
			fi
			printf "> Adding track to %s\n" "$i"
			__AddTracksToFile "$i"
		else
			COUNTER=$(( COUNTER + 1 ))
			[ $COUNTER -ne $FileNumber ] && continue
			printf "> Adding track to %s\n" "$i"
			__AddTracksToFile "$i"
			break
		fi
	done
	# printf -- "> File:%s - Track:%s - Name:%s\n" "$FileNumber" "$TrackNumber" "$Name"
}

convertToMKV(){
	printf -- "> Converting files to mkv\n"
	__getVideoFiles
	FILES_COUNT=$(echo "$FILES" | wc -l)
	if [ "$FILES_COUNT" -eq 1 ]; then
		if [ $(basename "$FILES") = "VIDEO_TS" ]; then
			__convertFromDVD "$FILES"
			exit 0
		fi
		# This is probably a movie, a single video file, with probably a single sub title in root folder
		printf "> Found movie\n%s\n" "$FILES"
		SUBS=$(find $VPATH -iname "*.srt")
		SUBS_COUNT=$(echo "$SUBS" | wc -l)
		FILENAME=$(basename "$FILES")
		FILENAME=${FILENAME%.*}
		ARGS=$(printf -- '-o "%s.mkv" "%s" --title "%s"' "${FILES%.*}" "$FILES" "$FILENAME")
		if [ -n "$SUBS" ]; then
			printf "> Found %d subs:\n%s\n" "$SUBS_COUNT" "$SUBS"
			if [ $SUBS_COUNT -gt 0 ]; then
				printf "> Subs should be the lang code between dots, ie: sub.en.001.srt"
			fi
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
		__backupConvertedFiles "$FILES"
	else
		# Probably a serie, multiple video files
		for i in $FILES ; do
			FILENAME=$(basename "$i")
			if [[ "$i" =~ .*\.mkv ]]; then
				printf "> Skipping %s\n" "$FILENAME"
				continue
			fi
			FILENAME=${FILENAME%.*}
			ARGS=$(printf -- '-o "%s.mkv" "%s" --title "%s"' "${i%.*}" "$i" "$FILENAME")
			FILES_TO_BACKUP="$i"
			FILEPATH=$(dirname $i)
			SUBSFILES=$(find "$FILEPATH" -iname "*.srt" | grep "$FILENAME" | sort -n)
			for j in $SUBSFILES ; do
				printf -- "> Analizyng subtitle file '%s'\n" "${j%*/*/}"
				# count the separators in order to detect the file name format
				SUBFILENAME=$(basename $j)
				SUBFILENAME=${SUBFILENAME%.*}
				unset SUBCODE SUBNAME
				LINES=$(printf "$SUBFILENAME" | sed "s/ - /\n/g" | wc -l)
				if [ $LINES -gt 1 ]; then
					# {order} - {name} - {code}
					SUBNAME=${SUBFILENAME#* - }
					SUBCODE=${SUBNAME#* - }
					SUBNAME=${SUBNAME% - *}
					SUBCODE=$(printf "$SUBCODE" | tr '[:lower:]' '[:upper:]')
					grep -E "^$SUBCODE[[:space:]]" "$CODESFILE" >/dev/null 2>&1
					[ $? -ne 0 ] && unset SUBCODE
				fi
				if [ -z "$SUBCODE" ]; then
					LINES=$(printf "$SUBFILENAME" | sed "s/_/\n/g" | wc -l)
					if [ $LINES -eq 1 ]; then
					# {order}_{name}
						SUBNAME=${SUBFILENAME#*_}
						if [ ${#SUBNAME} -eq 3 ]; then
							SUBCODE=$(grep -iE "^$SUBNAME[[:space:]]" "$CODESFILE" | head -n 1 | grep -Eo "^[A-Z]{3}")
							SUBNAME=$(grep -E "^$SUBCODE" "$CODESFILE" | head -n 1 | sed "s/^[A-Z]*[[:space:]]*//g")
						else
							SUBCODE=$(grep -iE "^[A-Z]*[[:space:]]*$SUBNAME" "$CODESFILE" | head -n 1 | grep -Eo "^[A-Z]{3}")
							if [ -z "$SUBCODE" ]; then
								SUBCODE=$(grep -i "$SUBNAME" "$CODESFILE" | head -n 1 | grep -Eo "^[A-Z]{3}")
							fi
						fi
					fi
				fi

				if [ -z "$SUBCODE" ]; then
					printf "> No language code detected, skipping\n"
					continue
				fi

				printf "> Language name and code detected: ${BOLD}%s/%s${NC}\n" "$SUBNAME" "$SUBCODE"
				ARGS=$(printf -- '%s --language 0:%s --track-name 0:"%s" "%s"' "$ARGS" "$SUBCODE" "$SUBNAME" "$j" | sed 's/\n//')
				FILES_TO_BACKUP=$(printf "%s\n%s" "$FILES_TO_BACKUP" "$j")
			done
			# printf "> ARGS: $ARGS\n"
			__executeConvertion
			__backupMultipleConvertedFiles "$FILES_TO_BACKUP"
			echo
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
	fi
}

__convertFromDVD(){
	printf  "> Converting DVD from %s\n" "$1"
	OLDIFS=$IFS
	IFS=$' '
	FILES=$(find $VPATH -iname "*.vob" -size +250M -exec printf "{} " \; | sort)
	for i in $FILES; do
		printf "> Converting %s:\n" $i
		FILENAME=$(basename $i)
		mkvmerge -o $VPATH/$FILENAME.mkv --title "$FILENAME" $i
	done
	IFS=$OLDIFS
}

__backupConvertedFiles(){
	FILEPATH="$1"
	DIRPATH="$(dirname $1)"
	mkdir -p $DIRPATH/converted
	FILENAME=$(basename $FILEPATH)
	FILENAME=${FILENAME%.*}
	OLDIFS=$IFS
	IFS=$'\n'
	FILESTOBACKUP=$(find "$DIRPATH" -type f -iname "*$FILENAME*" ! -iname "*.mkv" )
	printf "> Backing up files:\n"
	for i in $FILESTOBACKUP; do
		printf "> $i -> $DIRPATH/converted\n"
		mv -v "$i" "$DIRPATH/converted"
	done
	IFS=$OLDIFS
}

__backupMultipleConvertedFiles(){
	DST="$VPATH/converted"
	mkdir -p "$DST"
	printf "> Backing up files:\n"
	for i in $1; do
		FILEDST=$(printf "%s/%s" "$DST" "$i")
		mkdir -p $(dirname "$FILEDST")
		mv -v "$i" "$FILEDST"
	done
	find -name ".DS_Store" -exec rm -f {} \;
	while [ $(find /videos -type d -empty  | wc -l) -gt 0 ]; do
		find /videos -type d -empty -delete
	done
}

__backupFiles(){
	FILES=$1
	mkdir -p "$BPATH"
	for i in $FILES; do
		mv "$i" "$BPATH"
	done
}

__getVideoFiles(){
	FILES=$(find $VPATH  \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -name "VIDEO_TS" \) ! -path "$BPATH/*"  | sort )
	printf "> Found files:\n%s\n" "$FILES"
}

__getMkvVideoFiles(){
	FILES=$(find $VPATH -iname "*.mkv" ! -path "$BPATH/*"  | sort )
}

__AddTracksToFile(){
	FILEPATH="$1"
	DSTPATH="$(echo "$FILEPATH" | sed s/.mkv$/.converted.mkv/g)"
	DIRPATH="$(dirname $FILEPATH)"
	mkdir -p $DIRPATH/converted
	FILENAME=$(basename $FILEPATH)
	FILENAME=${FILENAME%.*}

	OLDIFS=$IFS
	IFS=$'\n'
	SUBSFILES=$(find "$DIRPATH" -type f \( -iname "*$FILENAME*" -a \( -iname "*.srt" -o -iname "*.vtt" \) ! -path "$BPATH/*" \) )
	FILESTOADD=""
	if [ -z "$SUBSFILES" ]; then
		printf ">> No subtitles files found!\n"
		return
	fi
	for i in $SUBSFILES; do
		printf ">> Found subtitle $i, add as new track? [y/n]_ "
		read OPTION
		if [ "$OPTION" == "y" ]; then
			printf ">> Subtitle file content:\n---\n"
			head -n 15 "$i"
			printf -- "---\n>> Add subtitle lang code: (ENG|SPA|..) _ "
			read SUBCODE
			printf -- "---\n>> Add subtitle lang code name: (English SDH|Español|..) _ "
			read SUBCODENAME
			SUBCODENAME=$(echo "$SUBCODENAME" | tr ' ' '_')
			printf ">> Adding sub: %s\n" "$i"
			FILESTOADD=$(printf "%s\n%s:%s:%s" "$FILESTOADD" "$i" "$SUBCODE" "$SUBCODENAME" )
		fi
	done
	# printf ">> Files to add:\n%s\n" "$FILESTOADD"
	FILES=""
	for i in $FILESTOADD; do
		SUBPATH=${i%%:*}
		SUBCODE=${i%:*}
		SUBCODE=${SUBCODE#*:}
		SUBCODENAME=${i##*:}
		ARGS=$(printf "%s --language 0:%s --track-name 0:%s '%s'" "$ARGS" "$SUBCODE" "$SUBCODENAME" "$SUBPATH")
		FILES=$(printf "%s\n%s" "$FILES" "$SUBPATH")
		# printf ">> SUBCODE: %s - SUBCODENAME: %s - FILEPATH: %s\n" "$SUBCODE" "$SUBCODENAME" "$SUBPATH"
	done
	if [ -n "$ARGS" ]; then
		COMMAND=$(printf "mkvmerge -o '%s' '%s' %s" "$DSTPATH" "$FILEPATH" "$ARGS")
		printf "> Executing:\n> %s\nejecutar? [y/n] _ " "$COMMAND"
		read OPTION
		echo
		if [ "$OPTION" == "y" ]; then
			eval "$COMMAND"
			if [ $? -eq 0 ]; then
				__backupFiles "$FILES"
				rm -f "$FILEPATH"
				mv "$DSTPATH" "$FILEPATH"
			fi
		fi
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
	addTrack)
		addTrack $@
		;;
	*)
		printf -- "ERROR: Command '%s' not valid\n" "$COMMAND"
		exit 2
		;;
esac
