
ALTER TABLE catalog_item ADD CONSTRAINT catalog_item_item_type_fk
FOREIGN KEY (item_type_id)
REFERENCES item_type (item_type_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
