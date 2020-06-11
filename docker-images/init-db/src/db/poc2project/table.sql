
DROP TABLE if exists poc2project cascade;

CREATE TABLE poc2project (
                project_id BIGINT NOT NULL,
                poc_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                username VARCHAR(250) NOT NULL,
                service_uuid VARCHAR(250),
                CONSTRAINT poc2project_pk PRIMARY KEY (project_id, poc_id)
);
