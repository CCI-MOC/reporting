
ALTER TABLE hardware_inventory ADD CONSTRAINT service_hardware_inventory_fk
FOREIGN KEY (service_id)
REFERENCES service (service_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
