
import logging
import psycopg2

class Database(object):
  """docstring for Database"""
  def __init__(self, conn):
    super(Database, self).__init__()
    self._conn = conn

  @staticmethod
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
    logging.info("Attempting Connection to {db} at {host} as {user}",
                 db=dbname,
                 host=host,
                 user=user)

    try:
      conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password)
      logging.info("Connection to Database established.")
      return new Database(conn)
    except:
      logging.exception("Could not establish connection to database.")

  def execute(self, query):
    """ Executes a given query to a database pointed to by a given cursor
        Args:
          cur: cursor pointing to the connected database
          query (str): String representing the query to execute

        Returns:
          Response (List of rows) from the query
    """
    self._cur.execute(query)
    return self._cur.fetchall()

  def query_item_ts(self, start_date, end_date, item_id):
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

  def tables(self):
    pass