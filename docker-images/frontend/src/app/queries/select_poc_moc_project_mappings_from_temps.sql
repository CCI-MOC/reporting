
SELECT * FROM poc2moc_project 
    WHERE poc_id IN 
        (SELECT poc_id from poc_temp) 
    AND moc_project_id IN 
        (SELECT moc_project_id FROM moc_project_temp);
