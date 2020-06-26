
SELECT * 
    FROM catalog_item 
    WHERE item_type_id IN 
        (SELECT item_type_id FROM item_type_temp);
