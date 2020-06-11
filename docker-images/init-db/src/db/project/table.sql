
DROP TABLE if exists project cascade;

CREATE SEQUENCE project_project_id_seq;
CREATE TABLE project (
                project_id BIGINT NOT NULL DEFAULT nextval('project_project_id_seq'),
                moc_project_id BIGINT NOT NULL,
                service_id BIGINT NOT NULL,
                project_uuid VARCHAR(250),
                CONSTRAINT project_pk PRIMARY KEY (project_id)
);

ALTER SEQUENCE project_project_id_seq OWNED BY project.project_id;
