
drop table if exists role cascade;

CREATE SEQUENCE role_role_id_seq_2;
CREATE TABLE role (
                role_id BIGINT NOT NULL DEFAULT nextval('role_role_id_seq_2'),
                role_name VARCHAR(100) DEFAULT 'viewer' NOT NULL,
                role_description VARCHAR(300) DEFAULT 'Viewer priveleges' NOT NULL,
                role_level INTEGER NOT NULL,
                CONSTRAINT role_pk PRIMARY KEY (role_id)
);

/* COMMENT ON COLUMN role.role_level IS 'This is to indicate:
    1 -> institution role
    2 -> moc_project role
    3 -> project role';
*/

ALTER SEQUENCE role_role_id_seq_2 OWNED BY role.role_id;
