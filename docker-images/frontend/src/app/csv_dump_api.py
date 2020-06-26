
import argparse
import os

from datetime import datetime
from shutil import make_archive, rmtree
from io import StringIO

from flask import Flask, request, Response, send_file, after_this_request

import db
from auth_middleware import authorized
from csv_dump import query_and_write_data, write_table_output
from query_info import QueryInfo
from util import get_config

app = Flask(__name__)
config = get_config() 

def param_check(params):
  """ Checks the JSON parameters for a given POST request for CSV dump

    Checks:
      Field Checks: JSON should include the following fields: ["start_ts", "end_ts", "type", "name"]
      Size Check: JSON should have 4 parameters
      type_field_check: "type" field should be one of: ["institution", "project"]

    Args:
      params (dict): JSON parameters from the POST request

    Returns:
      Boolean representing whether the JSON parameters pass the checks
  """
  return all([
      len(params.items()) == 4,
      all(field in params for field in ["start_ts", "end_ts", "type", "name"]),
      params["type"] in ["institution", "project"]
      # TODO: Add format check of start_ts and end_ts
  ])

@app.route('/csvdata/<table>', methods=['POST'])
@authorized
def csv_dump_table(table):
  """ Returns a REST response containing csv dump of a single table from the MOC reporting database that is filtered on:
    1. start_timestamp - beginning timestamp of the csv dump
    2. end_timestamp - end timestamp of the csv dump
    3. type - type of the dump required (either an "institution" or "project" filtered dump)
    4. name - name/id of the project/institution (either int or string)
  """
  params = request.get_json()

  response = Response("Bad Request", 400)
  if param_check(params):
    #TODO: Add Auth with username/password
    """
    elif not auth:
      response = Response("Auth Failed", 401)
    """
    # Determine query type
    query = None
    if params["type"] == "project":
      query = QueryInfo.get_query_infos_by_project(params["name"], params["start_ts"], params["end_ts"])
    elif params["type"] == "institution":
      query = QueryInfo.get_query_infos_by_institution(params["name"], params["start_ts"], params["end_ts"])
    else:
      response = Response("Invalid query type: " + params["type"], 404)

    if query is not None:
      conn = db.connect(config['host'], config['dbname'], config['user'], config['pass'])
      """
      #TODO:
        - Convert to streaming CSV output as we receive each row from the db as
          using StringIO requires buffering whole dump in memory
      #Issues:
        - WSGI doesn't like Chunked Transfer-Encoding:
          <https://www.python.org/dev/peps/pep-3333/#other-http-features>
          <https://github.com/pallets/flask/issues/367>
          Possible workaround with iterators:
          <https://dev.to/rhymes/comment/2inm>
        - Not clear how to stick a Writer (input to write_table_output)
          to a Reader (input to Response)
      """
      s = StringIO()
      write_table_output(conn.cursor(), query, s)
      response = Response(s.getvalue(), 200, mimetype='text/csv')
  return response

@app.route('/csvdata', methods=['POST'])
@authorized
def csv_dump():
  """ Returns an archived (zip) csv dump of the MOC reporting database that is filtered on:
    1. start_timestamp - beginning timestamp of the csv dump
    2. end_timestamp - end timestamp of the csv dump
    3. type - type of the dump required (either an "institution" or "project" filtered dump)
    4. name - name/id of the project/institution (either int or string)

    Example request:

    curl -H "Content-type: application/json; charset=utf-8"
       -X POST http://<host_ip>:<port_ip>/csvdata 
       -o archive.zip 
       -d '{"start_ts":"2019-01-01","end_ts":"2019-04-01","type":"project","name":1}'

    Returns:
      Archived csv dump to the client that made the request.
  """
  params = request.get_json()

  response = Response("Bad Request", 400)
  if param_check(params):
    query = None
    #TODO: Add Auth with username/password (As middleware?)
    # Connection to database
    conn = db.connect(config['host'], config['dbname'], config['user'], config['pass'])
    cur = conn.cursor()

    # File name and Path Parameters for dump
    current_ts = datetime.now().strftime("%m_%d_%Y_%H:%M:%S")
    base_path = "{}/api_temp_dump".format(os.getcwd())

    temp_path = "{}/{}/".format(base_path, current_ts)
    archive_file_name = "{}_{}_{}_archive".format(params["name"], params["start_ts"], params["end_ts"])
    archive_path = "{}/{}".format(base_path, archive_file_name)

    # Determine Query of Project/Institution
    query = None
    if params["type"] == "project":
      query = QueryInfo.get_query_infos_by_project(params["name"], params["start_ts"], params["end_ts"])
    elif params["type"] == "institution":
      query = QueryInfo.get_query_infos_by_institution(params["name"], params["start_ts"], params["end_ts"])
    else: # Query is invalid
      response = Response("Invalid query type: " + params["type"], 404)

    # Query and write dump to temp_path
    if query is not None:
      for query_info in query:
        query_and_write_data(cur, query_info, temp_path, "{}_{}".format(params["start_ts"], params["end_ts"]))

      # Create zip archive of dump
      make_archive(archive_path, "zip", temp_path)

      @after_this_request
      def _remove_archive(response):
        try:
          # remove temp_path
          rmtree(base_path)
        except OSError as exc:
          app.logger.error("Failed to remove temp dump directory", exc)
        return response

      # SEND
      response = send_file("{}.zip".format(archive_path), attachment_filename=archive_file_name)
  return response
