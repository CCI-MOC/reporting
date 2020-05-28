# init_database.sh
# Loads the database definition from sql and initializes the environment 
# specified database with the given
# the following
#  - POSTGRES_USER     - User with admin control on the postgres instance
#                        Default: postgres
#  - POSTGRES_PASSWORD - Password for the postgresql user. Will attempt to 
#                        authenticate without a password if not provided
#  - POSTGRES_HOST     - Host to initialize the database on
#                        Default: localhost

################################################################################
# Function Definitions
function uri_encode {
  # From: <https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command>
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}" 
}

################################################################################
# Validate Input
if [ "$#" -ne 0 ]; then
  echo "Usage: $0"
  exit 1
fi

PSQL=`env which psql`
if [ -z "$PSQL" ]; then
  echo "Missing PSQL executable!"
  exit 1
fi

################################################################################
# Variable Definitions
SRC_ROOT=/code
BILL_SQL=${SRC_ROOT}/bill.sql

PG_USER=$(uri_encode "${POSTGRES_USER:-postgres}")
if [ -z "${POSTGRES_PASSWORD}" ]; then
  PG_AUTH="${PG_USER}"
else
  PG_PASS=$(uri_encode "${POSTGRES_PASSWORD}")
  PG_AUTH="${PG_USER}:${PG_PASS}"
fi
PG_LOCATION="${PG_AUTH}@${POSTGRES_HOST:-localhost}"
PG_DB=$(uri_encode "${POSTGRES_DB:-postgres}")
PG_APP_ID=$(uri_encode "${0}")
PG_URI="postgresql://${PG_LOCATION}/${PG_DB}?application_name=${PG_APP_ID}"

################################################################################
# Program Main
${PSQL} "${PG_URI}" < ${BILL_SQL}
