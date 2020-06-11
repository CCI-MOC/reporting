
DROP TABLE if exists item_type cascade;

CREATE TABLE item_type (
                item_type_id BIGINT NOT NULL,
                item_definition VARCHAR(50),
                item_desc VARCHAR(500),
                CONSTRAINT item_type_pk PRIMARY KEY (item_type_id)
);
