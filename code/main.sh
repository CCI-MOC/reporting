#!/bin/bash
################################################################################
# main.sh
# Main Script for MOC_Reporting Docker container. Starts the following services:
#  - PostgreSQL Server
#  - Data Collection Engine (Perl)
################################################################################
# Validate Environment
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

################################################################################
# Main Body
POSTGRES_USER=postgres
POSTGRES_LOG=/var/log/postgres-server
WORKING_USER=reporting
PERL_MAIN=/reporting/get_info.pl

su $POSTGRES_USER -c "pg_ctl -l $POSTGRES_LOG start"
sleep 1
su $WORKING_USER -c "perl $PERL_MAIN"
su $POSTGRES_USER -c "pg_ctl stop"
sleep 5
