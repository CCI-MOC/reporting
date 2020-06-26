
SELECT * 
    FROM summarized_item_ts 
    WHERE item_id IN (SELECT item_id FROM item_temp) 
    AND start_ts >= '{start_date}' 
    AND end_ts   <= '{end_date}';
