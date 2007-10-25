#!/bin/bash
#
# encode.sh -- encoding glc stream to x264-encoded video
# Copyright (C) 2007 Pyry Haulos
# For conditions of distribution and use, see copyright notice in glc.h

FILE="pid-*.glc"
AUDIO="1"
CTX="1"
BITRATE="2000"
QP="20"
CRF="18"
METHOD="qp"
OUT="video.avi"
PASSLOG="pass.log"
AUDIOTMP="audio.mp3.tmp"
MULTIPASS="no"
OPTS=""

show-help () {
	echo "$0 [file ${FILE}] [out (${OUT})] [ctx ${CTX}] [audio ${AUDIO}] [bitrate|crf|qp (${METHOD})] [value (${BITRATE}|${CRF}|${QP})] [additional options for mencoder]"
}

if [ "$1" != "" -a "$1" != "-h" ]; then
	FILE=$1
else
	if [ "$1" != "" ]; then
		show-help
		exit 1
	fi
fi

[ "$2" != "" ] && OUT=$2
[ "$3" != "" ] && CTX=$3
[ "$4" != "" ] && AUDIO=$4
[ "$5" != "" ] && METHOD=$5
[ "$7" != "" ] && OPTS=$7

#FPS=`glc-play "${FILE}" -s fps`
#KEYINT=`expr "${FPS}" \* 10`
KEYINT=300

X264_OPTS="ref=4:mixed_refs:bframes=3:b_pyramid:bime:weightb:direct_pred=auto:filter=-1,0:partitions=all:turbo=1:threads=auto:keyint=${KEYINT}"
LAME_OPTS="q=4" # TODO configure q, cbr or abr

if [ "${METHOD}" == "crf" ]; then
	[ "$6" != "" ] && CRF=$6
	X264_OPTS="crf=${CRF}:${X264_OPTS}"
	MULTIPASS="no"
else
	if [ "${METHOD}" == "bitrate" ]; then
		[ "$6" != "" ] && BITRATE=$6
		X264_OPTS="bitrate=${BITRATE}:${X264_OPTS}"
		MULTIPASS="yes"
	else
		if [ "${METHOD}" == "qp" ]; then
			[ "$6" != "" ] && QP=$6
			X264_OPTS="qp=${QP}:${X264_OPTS}"
			MULTIPASS="yes"
		else
			show-help
			exit 1
		fi
	fi
fi

glc-play "${FILE}" -o - -a "${AUDIO}" | lame -hV2 - "${AUDIOTMP}"

if [ "${MULTIPASS}" == "no" ]; then
	glc-play "${FILE}" -o - -y "${CTX}" | \
		mencoder - \
			-audiofile "${AUDIOTMP}"\
			-ovc x264 \
			-x264encopts "${X264_OPTS}" \
			-oac copy \
			 ${OPTS} \
			 -of avi \
			 -o "${OUT}"
else
	glc-play "${FILE}" -o - -y "${CTX}" | \
		mencoder - \
			-nosound \
			-ovc x264 \
			-x264encopts "${X264_OPTS}:pass=1" \
			-passlogfile "${PASSLOG}" \
			${OPTS} \
			-of avi \
			-o "${OUT}"
	glc-play "${FILE}" -o - -y "${CTX}" | \
		mencoder - \
			-audiofile "${AUDIOTMP}" \
			-ovc x264 \
			-x264encopts "${X264_OPTS}:pass=2" \
			-passlogfile "${PASSLOG}" \
			-oac copy \
			${OPTS} \
			-of avi \
			-o "${OUT}"
fi

rm -f "${PASSLOG}" "${AUDIOTMP}"
