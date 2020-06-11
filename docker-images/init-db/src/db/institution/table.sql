
DROP TABLE if exists institution cascade;

CREATE TABLE institution (
                institution_id BIGINT NOT NULL,
                institution_name VARCHAR(200),
                CONSTRAINT institution_pk PRIMARY KEY (institution_id)
);
