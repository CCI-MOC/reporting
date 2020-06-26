
SELECT * 
    FROM hardware_inventory 
    WHERE service_id IN 
        (SELECT service_id FROM service_temp);
