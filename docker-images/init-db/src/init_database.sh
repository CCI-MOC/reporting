# init_database.sh
# Builds and commits transactions from the database description to initialize a
# new database.
# This script uses the psql cli underneath, and so responds to the psql cli 
# Environment Variables. For full documentation, see:
# <https://www.postgresql.org/docs/9.3/libpq-envars.html>
#  - EXCEPTION: PGAPPNAME is forcibly set to 'init-db'
################################################################################
# Validate Input
if [ "$#" -ne 0 ]; then
  echo "Usage: $0"
  exit 1
fi

PSQL="$(/usr/bin/env which psql)"
if [ -z "$PSQL" ]; then
  echo "Missing PSQL executable!"
  exit 1
fi

################################################################################
# Variable Definitions
SRC_ROOT="$(dirname $0)"
DB_SPEC="${SRC_ROOT}/db"

WORK_DIR="$(mktemp -d)"
WORK=(
  "${WORK_DIR}/tables.sql      ${DB_SPEC}/*/table.sql"
  "${WORK_DIR}/constraints.sql ${DB_SPEC}/*/constraints/*"
  "${WORK_DIR}/data.sql        ${DB_SPEC}/*/data.sql" )

BEGIN="BEGIN TRANSACTION;"
END="END;"

################################################################################
# Program Main

# Validate Postgres Configuration
if [ -z "${PGDATABASE}" ] ; then
  echo "Missing target database; should be stored in \$PGDATABASE"
  exit 1
fi
if [ -z "${PGPASSWORD}" -a -z "${PGPASSFILE}" ]; then
  echo "WARN: No authentication method provided"
fi
export PGAPPNAME="init-db"

# Build each transaction
for tupl in "${WORK[@]}" ; do
  # Push the list [ DEST IN1 IN2 ... ] to $@
  set -- $tupl
  # Pop DEST from $@
  dest_file=$1
  shift 
  # Write Beginning-of-Transaction indicator to DEST
  echo "$BEGIN" > $dest_file
  # Append all files to DEST
  cat $@ >> $dest_file
  # Write End-of-Transaction indicator to DEST
  echo "$END" >> $dest_file
done

# Run each transaction or die
for tupl in "${WORK[@]}" ; do
  set -- $tupl
  src_file=$(eval echo $1)
  ${PSQL} < $src_file || exit $?
done

rm -rf $WORKING

echo "Done"
