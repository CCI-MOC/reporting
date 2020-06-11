
DROP TABLE if exists raw_item_ts cascade;

CREATE TABLE raw_item_ts (
                item_id BIGINT NOT NULL,
                catalog_item_id INTEGER,
                state VARCHAR(50),
                start_ts TIMESTAMP,
                end_ts TIMESTAMP,
                CONSTRAINT raw_item_ts_pk PRIMARY KEY (item_id, start_ts)
);
