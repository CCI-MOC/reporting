#!=/usr/local/bin/zsh
project_name="reporting-5"
postgres_dbname="postgres"
postgres_username="admin"
postgres_password="pass"
database_size="2Gi"
# image: docker-registry.default.svc:5000/[project_name]/init-db:latest
# image: docker.io/robertbartlettbaron/init-db:latest

#create stuff into the project
oc new-project $project_name
oc create configmap reporting-db-initdb --"from-file=PostgresSetup/init_rpt.sql"
oc create configmap billing-config --"from-file=docker-images/get-info/billconf.json"
oc process -f yaml/pg-rpt-secret.yaml -p project_name=$project_name -p pg_user=$postgres_username -p pg_pass=$postgres_password -p pg_db=$postgres_dbname | oc create -f -
oc process -f yaml/pg-rpt-conn.yaml -p project_name=$project_name -p pg_user=$postgres_username -p pg_pass=$postgres_password -p pg_db=$postgres_dbname | oc create -f -


#copy the kustomize stuff to the working directory
mkdir work
sed "s/\${project_name}/$project_name/g" yaml/kustomize-template.yaml > work/kustomization.yaml
cp yaml/postgres-pvc.yaml work/postgres-pvc.yaml
cp yaml/postgres-deployment.yaml work/postgres-deployment.yaml
cp yaml/postgres-service.yaml work/postgres-service.yaml
cp yaml/secret-generator.yaml work/secret-generator.yaml
cp yaml/test-conn.yaml work/test-conn.yaml
cp yaml/get-info.yaml work/get-info.yaml

cd work
oc apply -k . 
cd ..

# "psql", "-d" ,"host=$DATABASE_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DATABASE user=$POSTGRES_USER password=$POSTGRES_PASSWORD", "-c", "\q"
# "psql", "-d" ,"host=reporting-db-svc port=5432 dbname=postgres user=admin password=pass", "-c", '\q'
# "sleep", 60000
# psql -d "host=reporting-db-svc port=5432 dbname=postgres user=admin password=pass" -c "\q"

POSTGRES_PASSWORD=pass
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/13/bin
POSTGRES_HOST=reporting-db-svc
POSTGRES_USER=admin
POSTGRES_PORT=5432
POSTGRES_DATABASE=postgres

# psql -d "host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DATABASE user=$POSTGRES_USER password=$POSTGRES_PASSWORD" -c "\q"


