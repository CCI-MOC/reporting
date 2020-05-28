# init-db

FROM postgres:latest
ADD ./src/ /code/
CMD ["/bin/bash", "/code/init_database.sh"]
HEALTHCHECK NONE
