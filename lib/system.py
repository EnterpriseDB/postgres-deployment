import logging
import os
import subprocess

def exec_shell(args, environ=os.environ, cwd=None):
    logging.info("Executing command: %s", ' '.join(args))
    return subprocess.check_output(
        ' '.join(args),
        stderr=subprocess.STDOUT,
        shell=True,
        cwd=cwd,
        env=environ
    )

def exec_shell_live(args, environ=os.environ, cwd=None):
    logging.info("Executing command: %s", ' '.join(args))
    logging.debug("environ=%s", environ)
    process = subprocess.Popen(
        ' '.join(args),
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=cwd,
        env=environ
    )

    rc = 0
    while True:
        output = process.stdout.readline()
        if output:
            logging.info(output.decode("utf-8").strip())
        rc = process.poll()
        if rc is not None:
            break

    return rc
