import sys
import logging

class ActionManager:
    def __init__(self, msg):
        self.msg = msg

    def __enter__(self):
        logging.info(self.msg)
        sys.stdout.write("%s ... " % self.msg)
        sys.stdout.flush()

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type == None:
            sys.stdout.write("\033[1m\033[92mok\033[0m\n")
        elif exc_type == KeyboardInterrupt:
            sys.stdout.write("\033[1m\033[93maborted\033[0m\n")
        else:
            sys.stdout.write("\033[1m\033[91mfail\033[0m\n")
        sys.stdout.flush()
