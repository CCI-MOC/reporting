
import os

import argparse
# import errno
# import logging

from app.csv_dump import query_and_write_data
from app.db import Database
from app.util import initialize_logging, get_config


def parse_program_execution_args(db):
  # check for args
  parser = argparse.ArgumentParser()
  subparsers = parser.add_subparsers(dest='filter_type', required=True)

  # Filtering arguments are start_timestamp and end_timestamp
  timeframe_parser = subparsers.add_parser('timeframe')
  timeframe_parser.add_argument("--start_timestamp",
                                help="the start timestamp where a VM was active",
                                required=True)
  timeframe_parser.add_argument("--end_timestamp",
                                help="the end timestamp till when a VM was active",
                                required=True)

  # Filtering arguments are project_id, start_timestamp and end_timestamp
  project_parser = subparsers.add_parser('project')
  project_parser.add_argument("--project_id",
                              help="the project id to filter the data",
                              required=True)
  # project_parser.add_argument("--start_timestamp",
  #                             help="the start timestamp where a VM was active",
  #                             required=True)
  # project_parser.add_argument("--end_timestamp",
  #                             help="the end timestamp till when a VM was active",
  #                             required=True)

  # Filtering arguments are institution_id, start_timestamp and end_timestamp
  institution_parser = subparsers.add_parser('institution')
  institution_parser.add_argument("--institution_id", help="the institution id to filter the data", required=True)
  # institution_parser.add_argument("--start_timestamp",
  #                                 help="the start timestamp where a VM was active",
  #                                 required=True)
  # institution_parser.add_argument("--end_timestamp",
  #                                 help="the end timestamp till when a VM was active",
  #                                 required=True)
  args = parser.parse_args()

  # Filter based arguments in command line
  file_prefix = None
  if args.filter_type == 'timeframe':
    start_date = args.start_timestamp
    end_date = args.end_timestamp
    file_prefix = "dates_" + start_date + "_" + end_date
    db.build_temps_by_timeframe(start_date=start_date, end_date=end_date, collect=False)
  elif args.filter_type == 'project':
    project_id = args.project_id
    # start_date = args.start_timestamp
    # end_date = args.end_timestamp
    file_prefix = "project_" + project_id # + start_date + "_" + end_date
    db.build_temps_by_project(id=project_id, collect=False) #, start_date=start_date, end_date=end_date)
  elif args.filter_type == 'institution':
    institution_id = args.institution_id
    # start_date = args.start_timestamp
    # end_date = args.end_timestamp
    file_prefix = "institution_" + institution_id # + start_date + "_" + end_date
    db.build_temps_by_institution(id=institution_id, collect=False) # , start_date=start_date, end_date=end_date)
  else:
    print("Invalid filtering types")

  return file_prefix

def check_directory(dir_path):
  '''
  Checks to see if the given directory path exists. If it does not, it creates the path.

  Args:
    dir_path (str): directory path to be checked for existance, or to be created.
  '''
  # If directory does not exist, create it
  i = 0
  def _gen_path():
    return dir_path + (f"_{i}" if i > 0 else "")
  while os.path.exists(_gen_path()):
    i += 1
  os.makedirs(_gen_path())
  return _gen_path()
  # if not os.path.exists(os.path.dirname(dir_path)):
  # Avoid Race condition (Case: directory being created at the same time as this.)
  #   os.makedirs(os.path.dirname(dir_path))
  #   logging.info("Saving to %s", dir_path)
  # except OSError as exc:
  #   if exc.errno != errno.EEXIST:
  #     logging.exception("Directory could not be created: %s", dir_path)
  #   else:
  #     logging.info("File Path Exists: %s", dir_path)

tables = ['service', 'poc', 'moc_project', 'project', 'poc2project']
def main():
  # Initialize Logging
  initialize_logging()
  # Get DB Configs
  config = get_config(os.environ['CREDS_FILE'])
  # Establish Connection to Database
  db = Database.connect(config['host'], config['port'], config['db_name'], config['user'], config['pass'])
  # Parse CLI Arguments
  file_prefix = parse_program_execution_args(db)

  # Dump CSV files
  cur = db.cursor()
  target_dir = check_directory(f"{os.getcwd()}/moc_reporting_csv_dump/{file_prefix}")
  for table in tables:
    query_and_write_data(cur, table, target_dir)

  # Close connection
  db.close()

if __name__ == '__main__':
  main()
