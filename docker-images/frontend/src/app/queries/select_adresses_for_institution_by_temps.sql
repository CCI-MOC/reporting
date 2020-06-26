
SELECT * 
    FROM address 
    WHERE address_id IN 
        (SELECT address_id 
            FROM poc 
            WHERE poc_id IN 
                (SELECT poc_id FROM poc2institution_temp));
