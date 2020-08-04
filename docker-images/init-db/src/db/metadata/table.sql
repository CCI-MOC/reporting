
DROP TABLE if exists metadata cascade;

CREATE TABLE metadata (
  key VARCHAR(512) NOT NULL PRIMARY KEY,
  value VARCHAR(512)
);
