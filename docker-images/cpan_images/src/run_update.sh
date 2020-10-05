#!/bin/bash
set -ex

DATESTAMP=`date +%Y_%m_%d`
TIMEOUT=${TIMEOUT:-10800} # 3 hours

DOCKER_CMD=${DOCKER:-$(which docker)}
STREAM=${STREAM:-perl_cpan}
SRC_IMG=${SRC_IMG:-latest}
TGT_IMG=${TGT_IMG:-$DATESTAMP}

SRC_DIR=${CMD_DIR:-`dirname "$0"`}
TGT_DIR=${TGT_DIR:-/code}
INTERNAL_CMD=${CMD:-cpan_update.sh}

TGT_BUNDLE="$TGT_DIR/Snapshot_$DATESTAMP_00.pm"

if [ ! -x "$DOCKER_CMD" ]; then
    if [ -x "$(which $DOCKER_CMD)" ]; then
        DOCKER_CMD="$(which $DOCKER_CMD)"
    else
	   echo "Non-executable command: $DOCKER_CMD"
	   exit 1
    fi
fi

cont_id=`$DOCKER_CMD run -d "$STREAM:$SRC_IMG" sleep $TIMEOUT`
$DOCKER_CMD exec -i $cont_id mkdir "$TGT_DIR"
$DOCKER_CMD cp "$SRC_DIR/$INTERNAL_CMD" $cont_id:"$TGT_DIR/$INTERNAL_CMD"
$DOCKER_CMD exec -i $cont_id chmod +x "$TGT_DIR/$INTERNAL_CMD"
$DOCKER_CMD exec -i $cont_id "$TGT_DIR/$INTERNAL_CMD" "$TGT_BUNDLE"
$DOCKER_CMD cp $cont_id:"$TGT_BUNDLE" .
$DOCKER_CMD stop $cont_id
$DOCKER_CMD rm $cont_id

