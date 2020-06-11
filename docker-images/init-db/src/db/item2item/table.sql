
DROP TABLE if exists item2item;

CREATE TABLE item2item (
                primary_item BIGINT NOT NULL,
                secondary_item BIGINT NOT NULL,
                CONSTRAINT item2item_pk PRIMARY KEY (primary_item, secondary_item)
);
