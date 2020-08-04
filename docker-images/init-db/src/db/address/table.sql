
DROP TABLE if exists address cascade;

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
CREATE SEQUENCE address_address_id_seq OWNED BY address.address_id;
