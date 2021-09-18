import sys
import logging
import time
import threading
import os


def spinning_cursor():
    """
    Generator returning chars used by the spinner.
    """
    while True:
        for cursor in '|/-\\':
            yield cursor


class Spinner(threading.Thread):
    """
    Terminal spinner running in its own thread.
    """
    def __init__(self, *args, **kwargs):
        super(Spinner, self).__init__(*args, **kwargs)
        self._stopper = threading.Event()

    def stop(self):
        self._stopper.set()
        sys.stdout.flush()

    def run(self):
        cursor = spinning_cursor()
        while True:
            time.sleep(0.1)
            if self._stopper.isSet():
                return
            sys.stdout.write(next(cursor))
            sys.stdout.flush()
            sys.stdout.write('\b')


class ActionManager:
    def __init__(self, msg):
        self.msg = msg
        self.spinner = Spinner()

    def __enter__(self):
        logging.info(self.msg)
        sys.stdout.write("%s ... " % self.msg)
        sys.stdout.flush()

        # Start the spinner
        self.spinner.start()

    def __exit__(self, exc_type, exc_value, traceback):
        # Stop the spinner
        self.spinner.stop()

        if exc_type == None:
            sys.stdout.write("\033[1m\033[92mok\033[0m\n")
        elif exc_type == KeyboardInterrupt:
            sys.stdout.write("\033[1m\033[93maborted\033[0m\n")
        else:
            sys.stdout.write("\033[1m\033[91mfail\033[0m\n")
        sys.stdout.flush()
