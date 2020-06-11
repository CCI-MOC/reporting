
DROP TABLE if exists item cascade;

CREATE SEQUENCE item_item_id_seq;
CREATE TABLE item (
                item_id BIGINT NOT NULL DEFAULT nextval('item_item_id_seq'),
                project_id BIGINT NOT NULL,
                item_name VARCHAR(150),
                item_uid VARCHAR(150),
                item_type_id BIGINT NOT NULL,
                CONSTRAINT item_pk PRIMARY KEY (item_id)
);

ALTER SEQUENCE item_item_id_seq OWNED BY item.item_id;
