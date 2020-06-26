
SELECT * 
    FROM role 
    WHERE role_id IN 
        (SELECT role_id FROM poc2institution_temp);
