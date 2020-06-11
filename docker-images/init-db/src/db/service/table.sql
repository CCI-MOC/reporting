
DROP TABLE if exists service cascade;

CREATE SEQUENCE service_service_id_seq_1;
CREATE TABLE service (
                service_id BIGINT NOT NULL DEFAULT nextval('service_service_id_seq_1'),
                service_name VARCHAR(100) NOT NULL,
                CONSTRAINT service_pk PRIMARY KEY (service_id)
);

ALTER SEQUENCE service_service_id_seq_1 OWNED BY service.service_id;
