
DROP TABLE if exists institution2moc_project cascade;

CREATE TABLE institution2moc_project (
                project_id INTEGER NOT NULL,
                institution_id BIGINT NOT NULL,
                moc_project_id BIGINT NOT NULL,
                percent_owned INTEGER,
                CONSTRAINT institution2moc_project_pk PRIMARY KEY (project_id, institution_id, moc_project_id)
);
