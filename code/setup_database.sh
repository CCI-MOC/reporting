#!$/bin/bash
################################################################################
# setup_database.sh
# This script takes one argument, creates a postgresql instance and creates a 
# database named the given argument

################################################################################
# Validate Input
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <db_name>"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

################################################################################
# Program Main
POSTGRES_USER=postgres
DATA_DIR=/usr/local/pgsql/data
POSTGRES_CONF=$DATA_DIR/postgresql.conf
POSTGRES_LOG=/var/log/postgres-server
DB_NAME="$1"

if [ ! -d $DATA_DIR ]; then 
  echo "ERROR: Could not find Postgres Data at $DATA_DIR"
  exit 2
fi

if [ -f $POSTGRES_CONF ]; then
  echo "ERROR: There appears to be a pre-existing database at $DATA_DIR; aborting!"
  exit 2
fi

su $POSTGRES_USER -c "pg_ctl init"
echo "pg_ctl -l '$POSTGRES_LOG' start"
su $POSTGRES_USER -c "pg_ctl -l $POSTGRES_LOG start"
sleep 1
psql -U $POSTGRES_USER -c "CREATE DATABASE \"$DB_NAME\";"
# psql -U $POSTGRES_USER < bill.sql
su $POSTGRES_USER -c "pg_ctl stop"
