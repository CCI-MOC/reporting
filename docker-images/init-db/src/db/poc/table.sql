

DROP TABLE if exists poc cascade;

CREATE TABLE poc (
                poc_id BIGINT NOT NULL,
                last_name VARCHAR(100),
                first_name VARCHAR(100),
                username VARCHAR(200),
                email VARCHAR(200),
                phone VARCHAR(20),
                address_id BIGINT NOT NULL,
                CONSTRAINT poc_pk PRIMARY KEY (poc_id)
);
