
DROP TABLE if exists catalog_item cascade;

CREATE TABLE catalog_item (
                catalog_item_id BIGINT NOT NULL,
                item_type_id BIGINT NOT NULL,
                create_ts TIMESTAMP,
                price INTEGER,
                CONSTRAINT catalog_item_pk PRIMARY KEY (catalog_item_id)
);
