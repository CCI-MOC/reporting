
DROP TABLE if exists summarized_item_ts cascade;

CREATE TABLE summarized_item_ts (
                item_id BIGINT NOT NULL,
                start_ts TIMESTAMP NOT NULL,
                catalog_item_id INTEGER NOT NULL,
                state VARCHAR(50) NOT NULL,
                end_ts TIMESTAMP NOT NULL,
                summary_period VARCHAR(16) NOT NULL,
                state_time INTEGER NOT NULL,  
                CONSTRAINT summarized_item_ts_pk PRIMARY KEY (item_id, start_ts, end_ts, state)
);

/* 
COMMENT ON COLUMN summarized_item_ts.summary_period IS 'Summary periods:
  1 -> daily
  2 -> weekly
  3 -> monthly';
*/
