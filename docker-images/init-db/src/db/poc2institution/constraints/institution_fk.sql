
ALTER TABLE poc2institution ADD CONSTRAINT poc2institution_institution_fk
FOREIGN KEY (institution_id)
REFERENCES institution (institution_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
