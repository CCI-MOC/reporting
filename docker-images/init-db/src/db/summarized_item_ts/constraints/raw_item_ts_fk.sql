
/*
Temporarily disabling uniqueness check for summarizing due to error: 
ERROR:  there is no unique constraint matching given keys for referenced table "raw_item_ts"

Notes: raw_item_ts has PRIMARY KEY based on (item_id, start_ts)

TODO: fixme!
*/

/*
ALTER TABLE summarized_item_ts ADD CONSTRAINT summarized_item_ts_raw_item_ts_fk
FOREIGN KEY (item_id)
REFERENCES raw_item_ts (item_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
*/
