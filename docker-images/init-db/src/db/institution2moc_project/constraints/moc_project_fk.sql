
ALTER TABLE institution2moc_project ADD CONSTRAINT institution2moc_project_moc_project_fk
FOREIGN KEY (moc_project_id)
REFERENCES moc_project (moc_project_id)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;
