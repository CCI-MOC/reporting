
-- ALTER SYSTEM SET listen_addresses = '*'
\connect postgres

DROP TABLE if exists address cascade;
DROP TABLE if exists catalog_item cascade;
DROP TABLE if exists hardware_inventory cascade;
DROP TABLE if exists institution cascade;
DROP TABLE if exists institution2moc_project cascade;
DROP TABLE if exists item cascade;
DROP TABLE if exists item_type cascade;
DROP TABLE if exists item2item;
DROP TABLE if exists metadata cascade;
DROP TABLE if exists moc_project cascade;
DROP TABLE if exists project cascade;
DROP TABLE if exists poc cascade;
DROP TABLE if exists poc2institution cascade;
DROP TABLE if exists poc2moc_project cascade;
DROP TABLE if exists poc2project cascade;
DROP TABLE if exists raw_item_ts cascade;
drop table if exists role cascade;
DROP TABLE if exists service cascade;
DROP TABLE if exists summarized_item_ts cascade;

CREATE TABLE address (
                address_id BIGINT NOT NULL,
                line1 VARCHAR(150),
                line2 VARCHAR(15),
                city VARCHAR(150),
                state VARCHAR(50),
                postal_code VARCHAR(40),
                country VARCHAR(100),
                CONSTRAINT address_pk PRIMARY KEY (address_id)
);

CREATE TABLE catalog_item (
                catalog_item_id BIGINT NOT NULL,
                item_type_id BIGINT NOT NULL,
                create_ts TIMESTAMP,
                price INTEGER,
                CONSTRAINT catalog_item_pk PRIMARY KEY (catalog_item_id)
);

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

CREATE TABLE institution (
                institution_id BIGINT NOT NULL,
                institution_name VARCHAR(200),
                CONSTRAINT institution_pk PRIMARY KEY (institution_id)
);

CREATE TABLE institution2moc_project (
                project_id INTEGER NOT NULL,
                institution_id BIGINT NOT NULL,
                moc_project_id BIGINT NOT NULL,
                percent_owned INTEGER,
                CONSTRAINT institution2moc_project_pk PRIMARY KEY (project_id, institution_id, moc_project_id)
);

CREATE SEQUENCE item_item_id_seq;
CREATE TABLE item (
                item_id BIGINT NOT NULL DEFAULT nextval('item_item_id_seq'),
                project_id BIGINT NOT NULL,
                item_name VARCHAR(150),
                item_uid VARCHAR(150),
                item_type_id BIGINT NOT NULL,
                CONSTRAINT item_pk PRIMARY KEY (item_id)
);

CREATE SEQUENCE item_type_item_type_id_seq;
CREATE TABLE item_type (
                item_type_id BIGINT NOT NULL DEFAULT nextval('item_type_item_type_id_seq'),
                item_definition VARCHAR(50),
                item_desc VARCHAR(500),
                CONSTRAINT item_type_pk PRIMARY KEY (item_type_id)
);

CREATE TABLE item2item (
                primary_item BIGINT NOT NULL,
                secondary_item BIGINT NOT NULL,
                CONSTRAINT item2item_pk PRIMARY KEY (primary_item, secondary_item)
);

CREATE TABLE metadata (
  key VARCHAR(512) NOT NULL PRIMARY KEY,
  value VARCHAR(512)
);

CREATE TABLE poc2institution (
                poc_id BIGINT NOT NULL,
                institution_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                CONSTRAINT poc2institution_pk PRIMARY KEY (poc_id, institution_id)
);

CREATE TABLE poc2moc_project (
                poc_id INTEGER NOT NULL,
                moc_project_id BIGINT NOT NULL,
                poc_poc_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                username VARCHAR(200),
                CONSTRAINT poc2moc_project_pk PRIMARY KEY (poc_id, moc_project_id, poc_poc_id)
);

CREATE TABLE poc2project (
                project_id BIGINT NOT NULL,
                poc_id BIGINT NOT NULL,
                role_id BIGINT NOT NULL,
                username VARCHAR(250) NOT NULL,
                service_uuid VARCHAR(250),
                CONSTRAINT poc2project_pk PRIMARY KEY (project_id, poc_id)
);

CREATE SEQUENCE project_project_id_seq;
CREATE TABLE project (
                project_id BIGINT NOT NULL DEFAULT nextval('project_project_id_seq'),
                moc_project_id BIGINT NOT NULL,
                service_id BIGINT NOT NULL,
                project_uuid VARCHAR(250),
                CONSTRAINT project_pk PRIMARY KEY (project_id)
);

CREATE TABLE raw_item_ts (
                item_id BIGINT NOT NULL,
                catalog_item_id INTEGER,
                state VARCHAR(50),
                start_ts TIMESTAMP,
                end_ts TIMESTAMP,
                CONSTRAINT raw_item_ts_pk PRIMARY KEY (item_id, start_ts)
);

CREATE SEQUENCE role_role_id_seq_2;
CREATE TABLE role (
                role_id BIGINT NOT NULL DEFAULT nextval('role_role_id_seq_2'),
                role_name VARCHAR(100) DEFAULT 'viewer' NOT NULL,
                role_description VARCHAR(300) DEFAULT 'Viewer priveleges' NOT NULL,
                role_level INTEGER NOT NULL,
                CONSTRAINT role_pk PRIMARY KEY (role_id)
);
-- COMMENT ON COLUMN role.role_level: This is to indicate:
--    1 -> institution role
--    2 -> moc_project role
--    3 -> project role;


CREATE SEQUENCE service_service_id_seq_1;
CREATE TABLE service (
                service_id BIGINT NOT NULL DEFAULT nextval('service_service_id_seq_1'),
                service_name VARCHAR(100) NOT NULL,
                CONSTRAINT service_pk PRIMARY KEY (service_id)
);

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




CREATE TABLE poc (
                poc_id BIGINT NOT NULL,
                last_name VARCHAR(100),
                first_name VARCHAR(100),
                username VARCHAR(200),
                email VARCHAR(200),
                phone VARCHAR(20),
                address_id BIGINT NOT NULL,
                CONSTRAINT poc_pk PRIMARY KEY (poc_id)
);
CREATE SEQUENCE poc_poc_id_seq OWNED BY poc.poc_id;

CREATE SEQUENCE moc_project_moc_project_id_seq_1;
CREATE TABLE moc_project (
                moc_project_id BIGINT NOT NULL DEFAULT nextval('moc_project_moc_project_id_seq_1'),
                project_name VARCHAR(200),
                CONSTRAINT moc_project_pk PRIMARY KEY (moc_project_id)
);

ALTER SEQUENCE moc_project_moc_project_id_seq_1 OWNED BY moc_project.moc_project_id;

ALTER TABLE poc ADD CONSTRAINT poc_address_fk
FOREIGN KEY (address_id)
REFERENCES address (address_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;


/* institution */
INSERT INTO role (role_name, role_description, role_level) values ('Sr. Software Engineer', '', 1);
INSERT INTO role (role_name, role_description, role_level) values ('Bustiness Administrator', '', 1);

/* moc_project */
INSERT INTO role (role_name, role_description, role_level) values ('admin', 'Billing Authority', 2);
INSERT INTO role (role_name, role_description, role_level) values ('admin', 'Principle Investigator', 2);
INSERT INTO role (role_name, role_description, role_level) values ('member', '', 2);

/* project */
INSERT INTO role (role_name, role_description, role_level) values ('admin', '', 3);
INSERT INTO role (role_name, role_description, role_level) values ('member', '', 3);
INSERT INTO role (role_name, role_description, role_level) values ('viewer', '', 3);



ALTER SEQUENCE role_role_id_seq_2 OWNED BY role.role_id;

ALTER TABLE hardware_inventory ADD CONSTRAINT service_hardware_inventory_fk
FOREIGN KEY (service_id)
REFERENCES service (service_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;


ALTER SEQUENCE hardware_inventory_hardware_inventory_id_seq OWNED BY hardware_inventory.hardware_inventory_id;

ALTER TABLE poc2institution ADD CONSTRAINT poc2institution_poc_fk
FOREIGN KEY (poc_id)
REFERENCES poc (poc_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2institution ADD CONSTRAINT poc2institution_role_fk
FOREIGN KEY (role_id)
REFERENCES role (role_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2institution ADD CONSTRAINT poc2institution_institution_fk
FOREIGN KEY (institution_id)
REFERENCES institution (institution_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;


ALTER TABLE poc2project ADD CONSTRAINT poc2project_poc_fk
FOREIGN KEY (poc_id)
REFERENCES poc (poc_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2project ADD CONSTRAINT poc2project_project_fk
FOREIGN KEY (project_id)
REFERENCES project (project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2project ADD CONSTRAINT poc2project_role_fk
FOREIGN KEY (role_id)
REFERENCES role (role_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE institution2moc_project ADD CONSTRAINT institution2moc_project_moc_project_fk
FOREIGN KEY (moc_project_id)
REFERENCES moc_project (moc_project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE institution2moc_project ADD CONSTRAINT institution2moc_project_institution_fk
FOREIGN KEY (institution_id)
REFERENCES institution (institution_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



/* Nova */
/* Cinder */
/* Neturon */
INSERT INTO item_type (item_definition, item_desc) VALUES ('floating_ip', 'OpenShift Floating Allocation IP Addresses');
/* Panko */



ALTER SEQUENCE item_type_item_type_id_seq OWNED BY item_type.item_type_id;



-- Temporarily disabling uniqueness check for summarizing due to error: 
-- ERROR:  there is no unique constraint matching given keys for referenced table "raw_item_ts"
-- 
-- Notes: raw_item_ts has PRIMARY KEY based on (item_id, start_ts)
-- 
-- TODO: fixme!



-- ALTER TABLE summarized_item_ts ADD CONSTRAINT summarized_item_ts_raw_item_ts_fk
-- FOREIGN KEY (item_id)
-- REFERENCES raw_item_ts (item_id)
-- ON DELETE NO ACTION
-- ON UPDATE NO ACTION
-- NOT DEFERRABLE;





-- COMMENT ON COLUMN summarized_item_ts.summary_period IS 'Summary periods:
--   1 -> daily
--   2 -> weekly
--   3 -> monthly';

ALTER TABLE project ADD CONSTRAINT project_moc_project_fk
FOREIGN KEY (moc_project_id)
REFERENCES moc_project (moc_project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE project ADD CONSTRAINT project_service_fk
FOREIGN KEY (service_id)
REFERENCES service (service_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER SEQUENCE project_project_id_seq OWNED BY project.project_id;


ALTER TABLE catalog_item ADD CONSTRAINT catalog_item_item_type_fk
FOREIGN KEY (item_type_id)
REFERENCES item_type (item_type_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE item ADD CONSTRAINT item_item_type_fk
FOREIGN KEY (item_type_id)
REFERENCES item_type (item_type_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE item ADD CONSTRAINT provisioned_service_item_fk
FOREIGN KEY (project_id)
REFERENCES project (project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER SEQUENCE item_item_id_seq OWNED BY item.item_id;


CREATE SEQUENCE address_address_id_seq OWNED BY address.address_id;

ALTER TABLE raw_item_ts ADD CONSTRAINT raw_item_ts_item_fk
FOREIGN KEY (item_id)
REFERENCES item (item_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;



ALTER TABLE poc2moc_project ADD CONSTRAINT poc2moc_project_moc_project_fk
FOREIGN KEY (moc_project_id)
REFERENCES moc_project (moc_project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2moc_project ADD CONSTRAINT poc2moc_project_poc_fk
FOREIGN KEY (poc_poc_id)
REFERENCES poc (poc_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE poc2moc_project ADD CONSTRAINT poc2moc_project_role_fk
FOREIGN KEY (role_id)
REFERENCES role (role_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;





ALTER SEQUENCE service_service_id_seq_1 OWNED BY service.service_id;



ALTER TABLE item2item ADD CONSTRAINT item2item_secondary_item_fk
FOREIGN KEY (secondary_item)
REFERENCES item (item_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE item2item ADD CONSTRAINT item2item_primary_item_fk
FOREIGN KEY (primary_item)
REFERENCES item (item_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;


