
import json
import logging

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
