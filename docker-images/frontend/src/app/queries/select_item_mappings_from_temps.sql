
SELECT * 
    FROM item2item 
    WHERE primary_item IN 
        (SELECT item_id FROM item_temp);
