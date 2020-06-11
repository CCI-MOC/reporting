
import argparse
import logging

import app.db as db
import app.summary_rollup as rollup
import app.util as util

def main():
  '''cli main'''
  # Check Args
  parser = argparse.ArgumentParser()
  parser.add_argument("--start_date", help="Start date of summary rollup (In the form of YYYY-MM-DD).", required=True)
  parser.add_argument("--period", choices=['day', 'week', 'month'], help="Summary Period (day, week, month).", required=True)
  parser.add_argument("--item_id", help="ID of item to create summary rollup for.", required=True)
  args = parser.parse_args()

  # Args
  start_date = args.start_date
  period = args.period
  item_id = args.item_id

  # Initialize Logging
  util.initialize_logging()

  # Calculate End Date
  # A period of 'month' requires a start date that is the first of a given month
  end_date = util.calculate_end_date(start_date, period)

  # Get DB Configs
  config = util.get_config()
  # Establish Connection to Database
  conn = db.connect(config['host'], config['dbname'], config['user'], config['pass'])
  cur = conn.cursor()

  # Query raw_item_ts 
  raw_item_ts_rows = db.query_item_ts(cur, start_date, end_date, item_id)
  # Check if we are able to summarize
  if raw_item_ts_rows and len(raw_item_ts_rows) > 0:
    catalog_item_id = raw_item_ts_rows[0][1]

    # Aggregate
    agg_summary = rollup.aggregate_summary(raw_item_ts_rows)

    # Write to summarized_item_ts
    write_success = rollup.write_summary(cur, agg_summary, period, start_date, end_date, item_id, catalog_item_id)

    # If successfully written all rows, commit.
    if write_success:
      conn.commit()
    else:
      logging.error("Error in writing summary rows. Please check inputs.")
  else:
    logging.error("No rows found for the given parameters: (item_id: {id}, start_date: {start}, period: {delta})",
                  id=item_id,
                  start=start_date,
                  delta=period)

  # Close
  logging.info("Closing Connection to {db_name}",
               db_name=config['dbname'])
  cur.close()
  conn.close()

if __name__ == '__main__':
  main()
