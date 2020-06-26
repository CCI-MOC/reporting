
SELECT * 
  FROM institution 
  WHERE institution_id IN 
    (SELECT institution_id FROM institution2moc_project _temp);
