
import errno
import logging
import os


def write_table_output(cur, table, fp):
  # fetch from temp table
  copy_query = f"COPY {table} TO STDOUT DELIMITER ',' CSV HEADER;"
  cur.copy_expert(copy_query, fp)

def query_and_write_data(cur, table_name, target_dir):
  '''Queries all data and headers from a given table, and writes it to a csv file.
  Path of the file is as such: {base_path}/{start_date_end_date_table_name}.csv

  Args:
    cur (psycopg2.cursor): Cursor to execute queries to the connected database
    table_name (str): Each table query info has table name, table query, params flag and temp_table flag
    base_path (str): Base path of where the CSV file dump of the table is to be stored.
            (Example: /example/path/to/desired/directory/)
    start_date: start endpoint where when the VM was active
    end_date:  end endpoint where the VM was active
  '''
  file_path = f"{target_dir}/{table_name}.csv"
  logging.info("Dumping %s table to %s", table_name, file_path)
  with open(file_path, "w+") as file_to_write:
    write_table_output(cur, table_name, file_to_write)
  logging.info("%s table contents successfully written to %s\n", table_name, file_path)
