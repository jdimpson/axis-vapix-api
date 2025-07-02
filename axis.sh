#!/bin/bash

THISDIR="$(dirname "$(readlink -f "$0")")"
VAPIXLIB="vapixlib.sh";

NOVALIDATE=true
VERB=true
if test -r "$THISDIR/$VAPIXLIB"; then
        . "$THISDIR/$VAPIXLIB";
else
        echo "Cannot find $VAPIXLIB; it should be in the same folder as this script ($THIDIR)" >&2;
        exit 6;
fi

if test -z "$AXIS"; then
	echo "Please set env variable AXIS to the IP address or hostname of the Axis Communications Network Video or Network Audio device" >&2;
	exit 2;
fi

if test -z "$AXISUSER" || test -z "$AXISPASS"; then
        echo "Please set env variables AXISUSER and AXISPASS for $AXIS" >&2;
        exit 3;
fi

test -z "$VERB" || echo "Connecting to $AXIS" >&2;


ranas() {
	local P;
	P="$1";
	echo "$0" | grep -q "$P";
}

if ranas "startvlc.sh"; then
	CAM=1;
	echo "WARNING: running this script puts your AXIS Password in the process list table." >&2;
	exec vlc "rtsp://${AXISUSER}:${AXISPASS}@${AXIS}/axis-media/media.amp?audiocodec=aac&audiosamplerate=16000&audiobitrate=32000&camera=${CAM}&videoframeskipmode=empty&videozprofile=classic&resolution=800x450&fps=30&audiodeviceid=0&audioinputid=0&timestamp=2&videocodec=h264"
fi

if ranas "listtours.sh"; then
	if hasguardtour $AXIS "$AXISUSER" "$AXISPASS"; then
		tourlist $AXIS "$AXISUSER" "$AXISPASS";
		exit 0
	else echo "$AXIS doesn't support guard tours" >&2; exit 1; fi
fi

# XXX: guard tour stuff needs work
if ranas "starttour.sh"; then
	G="$1";
	if ! echo "$G" | grep -q "G[0-9]"; then
		echo "Usage: $0 Gn" >&2;
		echo "	Where n is the tour number that you can see when running listtour.sh" >&2;
		exit 4;
	fi
	if hasguardtour $AXIS "$AXISUSER" "$AXISPASS"; then
		tourstart $AXIS "$AXISUSER" "$AXISPASS" "$G"
		exit 0
	else echo "$AXIS doesn't support guard tours" >&2; exit 1; fi
fi
if ranas "stoptour.sh"; then
	if hasguardtour $AXIS "$AXISUSER" "$AXISPASS"; then
		tourstop $AXIS "$AXISUSER" "$AXISPASS" "$1";
		exit 0
	else echo "$AXIS doesn't support guard tours" >&2; exit 1; fi
fi

if ranas "startrec.sh"; then
	if haslocalstorage $AXIS "${AXISUSER}" "${AXISPASS}" ; then
		recordingstart $AXIS "$AXISUSER" "$AXISPASS";
		exit 0;
	else
		echo "$AXIS does not have LocalStorage configured" >&2;
		exit 5;
	fi
fi

if ranas "listrec.sh"; then
	recordinglist $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi

if ranas "stoprec.sh"; then
	recordingstop $AXIS "$AXISUSER" "$AXISPASS" "$1";
	exit 0;
fi

if ranas "recordedstreams.sh"; then
	recordingliststreams $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi


if ! hasptz $AXIS "$AXISUSER" "$AXISPASS"; then
	echo "Warning: $AXIS doesn't support PTX" >&2;
fi

if ranas "left.sh"; then
	ptzleft $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "right.sh"; then
	ptzright $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "up.sh"; then
	ptzup $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "down.sh"; then
	ptzdown $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "zoomin.sh"; then
	ptzzoomin $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "zoomout.sh"; then
	ptzzoomout $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi
if ranas "ptzinfo.sh"; then
	ptzinfo $AXIS "$AXISUSER" "$AXISPASS";
	exit 0;
fi;

# main
while test $# -gt 0; do
	if test "$1" = "install"; then
		echo "Not implemented yet" >&2;
		exit 7;
	else
		echo "executing $AXIS / $1" >&2;
		if test "$2" = "-d"; then
			DATA="$3";
			vapix_post "$AXIS" "$AXISUSER:$AXISPASS" "$1" "$3";
			shift; 
			shift;
		else
			vapix_get "$AXIS" "$AXISUSER:$AXISPASS" "$1";
		fi
	fi
	shift;
done
