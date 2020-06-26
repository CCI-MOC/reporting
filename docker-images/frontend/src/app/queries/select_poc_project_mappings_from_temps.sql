
SELECT * 
    FROM poc2project 
    WHERE project_id IN 
        (SELECT project_id from project_temp) 
    AND poc_id IN 
        (SELECT poc_id FROM poc_temp);
