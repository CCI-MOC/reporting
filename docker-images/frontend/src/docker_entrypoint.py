
import sys
import summary_rollup

if __name__ == '__main__':
  ev = summary_rollup.main()
  if int(ev):
    sys.exit(int(ev))
  else:
    sys.exit(0)
