
DROP TABLE if exists item_type cascade;

CREATE SEQUENCE item_type_item_type_id_seq;
CREATE TABLE item_type (
                item_type_id BIGINT NOT NULL DEFAULT nextval('item_type_item_type_id_seq'),
                item_definition VARCHAR(50),
                item_desc VARCHAR(500),
                CONSTRAINT item_type_pk PRIMARY KEY (item_type_id)
);

ALTER SEQUENCE item_type_item_type_id_seq OWNED BY item_type.item_type_id;

