
import logging
import psycopg2

def connect(host, dbname, user, password):
  '''
  Attempts to establish a connection to a given Database

  Args:
    host(str): Host to connect to
    dbname (str): Name of the Database
    user (str): Name of the User
    password (str): Password
  Returns:
    conn: Connection object to the given database.

  '''
  try:
    logging.info("Connecting to {db} at {host} as {user}",
                 db=dbname,
                 host=host,
                 user=user)
    conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password)
    logging.info("Connection to Database established.")
    return conn
  except:
    logging.exception("Could not establish connection to database.")

def execute_query(cur, query, return_rows):
  """ Executes a given query to a database pointed to by a given cursor
      Args:
        cur: cursor pointing to the connected database
        query (str): String representing the query to execute
        return_rows(bool): True if there are any rows to be returned from the query. False otherwise

      Returns:
        Response (List of rows) from the query
        empty list if return_rows = False
  """

  try:
    cur.execute(query)
    results = []
    if return_rows:
      results = cur.fetchall()
    return results
  except psycopg2.Error as exc:
    logging.error(exc)

def query_item_ts(cur, start_date, end_date, item_id):
  """Queries all rows from raw_item_ts with the given item_id, start_date, and period
    Args:
    cur: Cursor to the connected database
    start_date (str): Start Date of the summary period (Format: YYYY-MM-DD)
    period (str): Period of the summary rollup (day, week, month)
    item_id (str): ID of the item to create a summary roll up for
  """

  # Format Query, Order by start_ts ASCENDING
  query = "SELECT * FROM raw_item_ts " + \
          f"WHERE item_id={item_id} " + \
          f"AND start_ts>='{start_date}' " + \
          f"AND end_ts<'{end_date}' " + \
          "ORDER BY start_ts ASC " + \
          ";"

  # Log Query
  logging.info("Querying usage data for ID: {item_id} from {start_date} to {end_date}",
               item_id=item_id,
               start_date=start_date,
               end_date=end_date)

  # Execute Query and retrieve usage data
  usage_data = execute_query(cur, query, True)
  return usage_data
