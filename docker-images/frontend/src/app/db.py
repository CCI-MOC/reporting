
import logging
import os.path
import psycopg2


basepath = os.path.dirname(os.path.realpath(__file__))

class Database(object):
  """docstring for Database"""
  def __init__(self, conn):
    super(Database, self).__init__()
    self._conn = conn
    self._queries_dir = f"{basepath}/queries"
    self._query_cache = {}

  def __getattr__(self, name):
    if name not in self._query_cache:
      loadpath = self._queries_dir + "/" + name + '.sql'
      if not os.path.exists(loadpath):
        raise AttributeError(name)
      with open(loadpath, 'r') as fp:
        stmt = fp.read()
        def _exec(collect=True, **kwargs):
          built_stmt = stmt.format(**kwargs)
          self.execute(built_stmt, collect=collect)
        self._query_cache[name] = _exec
    return self._query_cache[name]

  @staticmethod
  def connect(host, port, dbname, user, password):
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
    logging.info("Attempting Connection %s@%s:%d/%s", user, host, port, dbname)

    try:
      conn = psycopg2.connect(host=host, port=port, dbname=dbname, user=user, password=password)
      logging.info("Connection to Database established.")
      return Database(conn)
    except psycopg2.Error:
      logging.exception("Could not establish connection to database.")

  def close(self):
    return self._conn.close()

  def cursor(self):
    return self._conn.cursor()

  def execute(self, query, collect=True):
    """ Executes a given query to a database pointed to by a given cursor
        Args:
          cur: cursor pointing to the connected database
          query (str): String representing the query to execute

        Returns:
          Response (List of rows) from the query
    """
    cur = self._conn.cursor()
    cur.execute(query)
    if collect:
      return cur.fetchall()

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
    usage_data = self.execute(query)
    return usage_data

  def tables(self):
    ''' Gets all tables from a connected database.

    Args:
      cur (psycopg2.cursor): Cursor to execute queries to the connected database.

    Returns:
      tables: List of names(str) of the tables within the databse
    '''
    cur = self._conn.cursor()
    logging.info("Retrieving tables from database.")
    query = "SELECT table_name FROM information_schema.tables WHERE table_schema='public'"
    cur.execute(query)
    tables = [item[0] for item in cur.fetchall()]
    logging.debug("Tables retrieved: {tables}", tables=tables)
    return tables
