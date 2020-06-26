
CREATE TEMP TABLE project_temp AS
    (SELECT *
        FROM project
        WHERE project_id = '{id}');

CREATE TEMP TABLE moc_project_temp AS
    (SELECT *
        FROM moc_project
        WHERE moc_project_id IN
            (SELECT moc_project_id FROM project_temp));

CREATE TEMP TABLE institution2moc_project_temp AS
    (SELECT *
        FROM institution2moc_project
        WHERE project_id IN
            (SELECT project_id FROM project_temp)
        AND moc_project_id IN
            (SELECT moc_project_id FROM moc_project_temp));

CREATE TEMP TABLE poc2institution_temp AS
    (SELECT *
        FROM poc2institution
        WHERE institution_id IN
            (SELECT institution_id FROM institution2moc_project_temp));

CREATE TEMP TABLE poc_temp AS
    (SELECT *
        FROM poc
        WHERE poc_id IN
            (SELECT poc_id FROM poc2institution_temp));

CREATE TEMP TABLE service_temp AS
    (SELECT *
        FROM service
        WHERE service_id IN
            (SELECT service_id FROM project_temp));

CREATE TEMP TABLE item_temp AS
    (SELECT *
        FROM item
        WHERE project_id IN
            (SELECT project_id FROM project_temp));

CREATE TEMP TABLE item_type_temp AS
    (SELECT *
        FROM item_type
        WHERE item_type_id IN
            (SELECT item_type_id FROM item_temp));
