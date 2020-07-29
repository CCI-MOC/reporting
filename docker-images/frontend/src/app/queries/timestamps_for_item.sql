SELECT * FROM raw_item_ts 
	WHERE item_id={item_id} 
	AND start_ts>='{start_date}' 
	AND end_ts<'{end_date}' 
	ORDER BY start_ts ASC;