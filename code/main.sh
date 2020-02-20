#!/bin/bash
################################################################################
# main.sh
# Main Script for MOC_Reporting Docker container. Starts the following services:
#  - PostgreSQL Server
#  - Data Collection Engine (Perl)
################################################################################

id

pg_ctl -l $PGLOG start
sleep 1
perl $WORKDIR/get_info.pl
pg_ctl stop
sleep 5
