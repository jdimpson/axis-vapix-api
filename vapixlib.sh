#!/bin/bash

# intended to be sourced or executed. If sourced, recommend using this 
# structure in the sourcing script, assuming the script is in the same 
# directory as the :
# THISDIR="$(dirname "$(readlink -f "$0")")"
# VAPIXLIB="vapixlib.sh";
# . "$THISDIR/$VAPIXLIB";

# check to see if this was sourced or executed (bash only)
(return 0 2>/dev/null) && sourced=1 || sourced=0

# set VERB to any non-empty string to turn on verbosity
if ! test -z "$VERB"; then
	echo "verbose mode" >&2;
fi

# need xmlstarlet for some functions
XMLSTAR=xmlstarlet
if ! which $XMLSTAR > /dev/null; then
	XMLSTAR=xmlstar;
	if ! which $XMLSTAR > /dev/null; then
		echo "Warning: some features unavailable because xmlstartlet is not installed" >&2;
		XMLSTAR=
	fi
fi

# I guess you can override this if you want
if test -z "$APIPROTO"; then 
	APIPROTO="https"; 
fi

# Set NOVALIDATE to any non-empty string in order ignore self-signed server certificate
if ! test -z "$NOVALIDATE"; then
	NOVALIDATE="-k";
	test -z "$VERB" || echo "server certificate validation off" >&2;
else
	test -z "$VERB" || echo "server certificate validation on" >&2;
fi

# https://developer.axis.com/vapix/network-video/api-discovery-service/#authentication
vapix_curl() {
	local HTTPMETH="$1"; # GET, POST; others tbd
	local SERVER="$2"; 
	local APIAUTH="$3"; # username-colon-password, as you'd pass to curl
	local APIPATH="$4";
	local HTTPDATA="$5"; # optional
	if ! echo "$APIPATH" | grep -q "^/"; then
		APIPATH="$APIPATH";
	fi
	URL="${APIPROTO}://${SERVER}${APIPATH}";
	if ! test -z "$HTTPDATA"; then
		HTTPDATA="--data $HTTPDATA";
	fi
	test -z "$VERB" || echo curl -sSL "$NOVALIDATE" -u "$APIAUTH" --anyauth $HTTPDATA \'"$URL"\' >&2;
	curl -sSL $NOVALIDATE -u "$APIAUTH" --anyauth $HTTPDATA "$URL";
}

vapix_get() { # server, user:pass, URL-path
	vapix_curl GET "$1" "$2" "$3";
}

vapix_post() { # server, user:pass, URL-path, data
	# I've not seen VAPIX use this, but just in case
	vapix_curl POST "$1" "$2" "$3" "$4";
}

PARAM="/axis-cgi/param.cgi";
PTZ="/axis-cgi/com/ptz.cgi";
RECORD="/axis-cgi/record/record.cgi";
RECSTOP="/axis-cgi/record/stop.cgi";
RECLIST="/axis-cgi/record/list.cgi";

listprops() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PARAM}?action=list";
}

hasprop() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local PROP="$4";
	O=$(vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PARAM}?action=list&group=${PROP}");
	test -z "$VERB" || test -z "$O" || echo "\-> $O" >&2;
	test "$O" = "${PROP}=yes"
}

hasguardtour() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	hasprop $AXIS "${AXISUSER}" "${AXISPASS}" "Properties.GuardTour.GuardTour";
}
hasptz() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	hasprop $AXIS "${AXISUSER}" "${AXISPASS}" "Properties.PTZ.PTZ";
}
haslocalstorage() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	hasprop $AXIS "${AXISUSER}" "${AXISPASS}" "Properties.LocalStorage.LocalStorage";
}

# https://developer.axis.com/vapix/network-video/pantiltzoom-api/#ptz-control 
ptzinfo() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	# gets list of available parameters
	local CAM="$4";
	if test -z "$CAM"; then CAM=1; fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?info=1&camera=${CAM}";
}
ptzleft() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local CAM="$4";
	if test -z "$CAM"; then CAM=1; fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?move=left&camera=${CAM}";
}
ptzright() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local CAM="$4";
	if test -z "$CAM"; then CAM=1; fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?move=right&camera=${CAM}";
}
ptzup() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local CAM="$4";
	if test -z "$CAM"; then CAM=1; fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?move=up&camera=${CAM}";
}
ptzdown() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local CAM="$4";
	if test -z "$CAM"; then CAM=1; fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?move=down&camera=${CAM}";
}
ptzzoomin() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local UNIT="$4";
	if test -z "$UNIT"; then
		UNIT=100;
	fi
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PTZ}?rzoom=${UNIT}";
}
ptzzoomout() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local UNIT="$4";
	if test -z "$UNIT"; then
		UNIT=100;
	fi
	ptzzoomin $AXIS "${AXISUSER}" "${AXISPASS}" "-${UNIT}";
}

# https://developer.axis.com/vapix/network-video/guard-tour-api/#prerequisites
# XXX: this section needs work to make it easier to use
tourlist() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PARAM}?action=list&group=GuardTour" | egrep '\.(Name|CamNbr|Running)=' | sed -e 's/root\.GuardTour\.//'; 
}

tourstart() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local G="$4";
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PARAM}?action=update&GuardTour.${G}.Running=yes"
	echo;
}
tourstop() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local G="$4";
	vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${PARAM}?action=update&GuardTour.${G}.Running=no"
	echo;
}

# https://developer.axis.com/vapix/network-video/edge-storage-api/#recording-api
recordingstart() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	X=$(vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${RECORD}?diskid=NetworkShare&options=eventid%3Dmanual")
	if test -z "$XMLSTAR"; then
		echo "$X";
	else
		echo "$X" | xmlstarlet sel -t -m '//record' -v @recordingid -o ' started ' -v '@result' -n;
	fi
}
recordinglist() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local RECSXML=$(vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${RECLIST}?recordingid=all");
	if test -z "$XMLSTAR"; then
		echo $RECSXML;
	else
		echo $RECSXML | xmlstarlet sel -t -m '//recording' -v @recordingstatus -o ' ' -v @recordingid -n;
	fi
}
recordingstop() {
	local AXIS="$1";
	local AXISUSER="$2";
	local AXISPASS="$3";
	local ID="$4";
	local RECSXML=$(vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${RECLIST}?recordingid=all");
	if test -z "$ID"; then
		if test -z "$XMLSTAR"; then
			echo "Error: Cannot shutoff recording if xmlstarlet is not installed: pass as argument" >&2;
			exit 1;
		else
			ID=$(echo $RECSXML | xmlstarlet sel -t -m '//recording' -v @recordingstatus -o ' ' -v @recordingid -n | awk '/recording/ { print $2 }');
		fi
	fi
	for id in $ID; do
		O=$(vapix_get $AXIS "${AXISUSER}:${AXISPASS}" "${RECSTOP}?recordingid=$id") 
		if test -z "$XMLSTAR"; then
			echo "$O";
		else
			echo "$O" | xmlstarlet sel -t -m '//stop' -v @recordingid -o ' stopped ' -v '@result' -n
		fi
	done
	exit 0;
}
recordingliststreams() {
	recordinglist "$1" "$2" "$3" | while read s i; do
		echo "$s rtsp://$2:$3@$1/axis-media/media.amp?recordingid=${i}";
	done
}

if test $sourced -eq 0; then
	# main
	NOVALIDATE="-k";

	if test -z "$AXIS"; then
	        echo "Please set env variable AXIS to the IP address or hostname of the Axis Communications Network Video or Network Audio device" >&2;
	        exit 2;
	fi

	if test -z "$AXISUSER" || test -z "$AXISPASS"; then
	        echo "Please set env variables AXISUSER and AXISPASS for $AXIS" >&2;
	        exit 3;
	fi

	listprops "$AXIS" "$AXISUSER" "$AXISPASS";

fi
