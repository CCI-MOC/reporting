
import multiprocessing

bind = "127.0.0.1:8080"
workers = multiprocessing.cpu_count() * 2 + 1
wsgi_app = "csv_dump_api:app"
