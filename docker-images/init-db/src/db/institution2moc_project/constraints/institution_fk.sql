
ALTER TABLE institution2moc_project ADD CONSTRAINT institution2moc_project_institution_fk
FOREIGN KEY (institution_id)
REFERENCES institution (institution_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
