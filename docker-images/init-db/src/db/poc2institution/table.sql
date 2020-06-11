
DROP TABLE if exists poc2institution cascade;

CREATE TABLE poc2institution (
                poc_id BIGINT NOT NULL,
                institution_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                CONSTRAINT poc2institution_pk PRIMARY KEY (poc_id, institution_id)
);
