#!=/usr/local/bin/zsh
project_name="reporting-1"
postgres_dbname="reporting-1"
postgres_username="admin"
postgres_password="pass"
database_size="2Gi"
# image: docker-registry.default.svc:5000/[project_name]/init-db:latest
# image: docker.io/robertbartlettbaron/init-db:latest


oc new-project $project_name
oc create configmap postgres-setup --"from-file=PostgresSetup/init_rpt.sql"
oc process -f yaml/postgres-secret.yaml -p project_name=$project_name -p pg_user=$postgres_username -p pg_pass=$postgres_password -p pg_db=$postgres_dbname | oc create -f -
oc process -f yaml/postgres-pvc.yaml -p project_name=$project_name -p db_size=$database_size | oc create -f -
oc process -f yaml/postgres-deployment.yaml  -p project_name=$project_name | oc apply -f -
oc process -f yaml/postgres-service.yaml -p project_name=$project_name | oc apply -f -

# oc process -f yaml/postgres-secret-patch.yaml -p project_name=$project_name | oc patch -f -
# oc process -f yaml/rpt-init-db-job.yaml -p project_name=$project_name | oc apply -f -
# oc process -f yaml/init-db-only.yaml -p project_name=$project_name | oc apply -f -



# psql -d "host=reporting-1-rpt-db-svc port=5432 dbname=postgres user=admin"
# psql -d "host=172.30.167.60 port=5432 dbname=postgres user=admin"
# psql -d "host=localhost port=5432 dbname=postgres user=admin"
#
# (app-root) sh-4.2$ env | grep POSTGRES
# POSTGRESQL_PORT_5432_TCP_ADDR=172.30.186.103
# POSTGRESQL_PORT=tcp://172.30.186.103:5432
# POSTGRESQL_SERVICE_PORT_POSTGRESQL=5432
# POSTGRESQL_PORT_5432_TCP=tcp://172.30.186.103:5432
# POSTGRESQL_SERVICE_HOST=172.30.186.103
# POSTGRESQL_PORT_5432_TCP_PORT=5432
# POSTGRESQL_SERVICE_PORT=5432
# POSTGRESQL_PORT_5432_TCP_PROTO=tcp


# {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"reporting-1-rpt-db-svc","namespace":"reporting-1"},"spec":{"ports":[{"name":"postgresql","port":5432,"protocol":"TCP","targetPort":5432}],"selector":{"app":"reporting-1","deploymentconfig":"reporting-1-dc","name":"postgres"},"type":"ClusterIP"},"status":{"loadBalancer":{}}}
# 
# psql -d "host=reporting-1-rpt-db-svc port=5432 dbname=postgres user=admin"
# psql: error: could not connect to server: Connection refused
#        Is the server running on host "reporting-1-rpt-db-svc" (172.30.167.60) and accepting
#        TCP/IP connections on port 5432?