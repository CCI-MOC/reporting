
DROP TABLE if exists moc_project cascade;

CREATE SEQUENCE moc_project_moc_project_id_seq_1;
CREATE TABLE moc_project (
                moc_project_id BIGINT NOT NULL DEFAULT nextval('moc_project_moc_project_id_seq_1'),
                project_name VARCHAR(200),
                CONSTRAINT moc_project_pk PRIMARY KEY (moc_project_id)
);

ALTER SEQUENCE moc_project_moc_project_id_seq_1 OWNED BY moc_project.moc_project_id;
