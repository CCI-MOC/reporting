
import argparse

import app.db as db
import app.summary_rollup as rollup
import app.util as util

def main():
  '''docker auto main'''
  parser = argparse.ArgumentParser()
  parser.add_argument("period",
                      choices=['day', 'week', 'month'],
                      help="Summary Period: <day | week | month>")
  args = parser.parse_args()

if __name__ == '__main__':
  main()
