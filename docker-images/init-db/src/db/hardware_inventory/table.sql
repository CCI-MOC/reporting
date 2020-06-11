
DROP TABLE if exists hardware_inventory cascade;

CREATE SEQUENCE hardware_inventory_hardware_inventory_id_seq;
CREATE TABLE hardware_inventory (
                hardware_inventory_id VARCHAR NOT NULL DEFAULT nextval('hardware_inventory_hardware_inventory_id_seq'),
                service_id BIGINT NOT NULL,
                manufacturer VARCHAR(250) NOT NULL,
                model VARCHAR(250) NOT NULL,
                serial_number VARCHAR(250) NOT NULL,
                type VARCHAR(200) NOT NULL,
                CONSTRAINT hardware_inventory_pk PRIMARY KEY (hardware_inventory_id)
);

ALTER SEQUENCE hardware_inventory_hardware_inventory_id_seq OWNED BY hardware_inventory.hardware_inventory_id;
