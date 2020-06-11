
import logging
from db import execute_query
from util import time_delta

def aggregate_summary(usage_data):
  """ Aggregates list of usage data into {state: total_time}

    Args
      usage_data: Sorted List (by start_ts) of usage data tuples
                  [(item_id, catalog_item_id, state, start_ts, end_ts), ...]

    Return:
      Dictionary mapping each state to the total time spent in that state for
      the given period of time
  """

  # Initialize aggregate_summary mapping
  agg_summary = {}

  if len(usage_data) > 0:
    # Add Time for first element in the row
    _, _, cur_state, cur_start, cur_end = usage_data[0]
    agg_summary[cur_state] = time_delta(cur_end, cur_start)

    # Iterate through rest of the usage data rows
    for row in usage_data[1:]:
      # Get the next row info
      _, _, next_state, next_start, next_end = row

      # Case 1: Next state is the same as the current state
      if cur_state == next_state:
        agg_summary[next_state] += time_delta(next_end, cur_end)
      # Case 2: Next state is not the same as the current state
      elif next_state in agg_summary: # Mapping exists, add time
        agg_summary[next_state] += time_delta(next_end, next_start)
      # Case 3: Mapping does not exist
      else:
        agg_summary[next_state] = time_delta(next_end, next_start)

      # Update current row info
      _, _, cur_state, cur_start, cur_end = row

  return agg_summary

def write_summary(cur, agg_summary, period, start_date, end_date, item_id, catalog_item_id):
  """
    Writes the contents of a given aggregated summary dictionary
    to the summarized_item_ts

    Args:
      cur: cursor pointing to the connected database
      agg_summary (dict): aggregated summary mapping {state(str): time in state (int seconds)}
      period (str): period of aggregation (day, week, month)
      start_date (str): Start date of Summary Period in the form (YYYY-MM-DD)
      end_date (str): End date of Summary Period in the form (YYYY-MM-DD)
      item_id (str): ID of item that is being summarized
      catalog_item_id (str): Catalog ID of the item

    Returns:
      1 for successful write
      0 for unsuccessful write
  """

  query = "INSERT INTO summarized_item_ts " + \
      "(item_id, start_ts, catalog_item_id, state, end_ts, summary_period, state_time) " + \
      "VALUES({},'{}',{},'{}','{}','{}',{})" + \
      ";"

  # Write each item in aggregate summary
  for state, time in agg_summary.items():
    # Log query being executed
    logging.info("Inserting summary for ID: {id} for state: {state} from {start} to {end}",
                 id=item_id,
                 state=state,
                 start=start_date,
                 end=end_date)
    # Execute query
    f_query = query.format(item_id, start_date, catalog_item_id, state, end_date, period, time)
    if execute_query(cur, f_query, False) is None:
      return 0 # Query execution failed. Abort
  return 1 # Success
