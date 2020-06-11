
DROP TABLE if exists poc2moc_project cascade;

CREATE TABLE poc2moc_project (
                poc_id INTEGER NOT NULL,
                moc_project_id BIGINT NOT NULL,
                poc_poc_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                username VARCHAR(200),
                CONSTRAINT poc2moc_project_pk PRIMARY KEY (poc_id, moc_project_id, poc_poc_id)
);
