
import json
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

def initialize_logging():
  '''Initializes Logging'''
  log_format = "%(asctime)s [%(levelname)s]: %(filename)s(%(funcName)s:%(lineno)s) >> %(message)s"
  logging.basicConfig(format=log_format, level=logging.INFO)
  logging.info("Initialized Logging.")

def get_config(filepath='config.json', section='database'):
  """ Reads config file and retrieves configs from a given section

  Args:
    filepath (str): Filepath of the config file.
    section (str): Secton of the config file to read

  Return:
    kwargs (dict): dictionary of config key:value pairs.
  """
  with open(filepath) as json_config:
    config = json.load(json_config)
  try:
    return config[section]
  except:
    raise Exception('Please check the formatting of your {} config file'.format(filepath))

def time_delta(end_time, start_time):
  """
    Calculates the total seconds between two datetime objects

    Args:
      end_time (datetime.datetime): End time
      start_time (datetime.datetime): Start time

    Return:
      total time (int) between the end and start time in seconds.
  """
  return (end_time - start_time).total_seconds()

def calculate_end_date(start_date, period):
  """
    Calculates the end_date, given a start_date and a time period from the start date

    Args:
      start_date (str): Start Date (Format: YYYY-MM-DD)
      period (str): Period to increment (day, week, month)
    Return:
      end_date (str): End Date of the (Format: YYYY-MM-DD)
  """
  period_mapping = {
      "day":   timedelta(days=1),
      "week":  timedelta(days=7),
      "month": relativedelta(months=1)
  }

  # Calculate End Date
  start_date_fmt = datetime.strptime(start_date, "%Y-%m-%d")
  end_date_fmt = start_date_fmt + period_mapping[period]
  end_date = datetime.strftime(end_date_fmt, "%Y-%m-%d") # Bring End Date back into str

  return end_date
