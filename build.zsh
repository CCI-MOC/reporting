#!=/usr/local/bin/zsh
project_name="reporting-1"
postgres_dbname="reporting-1"
postgres_username="admin"
postgres_password="pass"
database_size="2Gi"


oc new-project $project_name
oc process -f yaml/postgres-secret.yaml -p project_name=$project_name -p pg_user=$postgres_username -p pg_pass=$postgres_password -p pg_db=$postgres_dbname | oc create -f -
oc process -f yaml/postgres-pvc.yaml -p project_name=$project_name -p db_size=$database_size | oc create -f -
oc process -f yaml/postgres-deployment.yaml  -p project_name=$project_name | oc apply -f -
oc process -f yaml/postgres-service.yaml -p project_name=$project_name | oc apply -f -
oc process -f yaml/rpt-init-db-job.yaml -p project_name=$project_name | oc apply -f -