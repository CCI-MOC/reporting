
SELECT * 
    FROM raw_item_ts 
    WHERE item_id IN (SELECT item_id FROM item_temp) 
    AND start_ts BETWEEN '{start_date}' AND '{end_date}';
