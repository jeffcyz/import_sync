
import sys

print("=== STREAM TEST ===")

print("TEST 1: print works")

try:
    sys.stdout.write("TEST 2: stdout.write works\n")
    sys.stdout.flush()
except Exception as e:
    print("stdout error:", str(e))

try:
    sys.stderr.write("TEST 3: stderr.write works\n")
    sys.stderr.flush()
except Exception as e:
    print("stderr error:", str(e))

print("=== END ===")




import logging

class ASAPHandler(logging.Handler):
    def emit(self, record):
        try:
            print(self.format(record))
        except Exception as e:
            print("Logging error: {}".format(e))

logger = logging.getLogger("asap_waterfall")
logger.setLevel(logging.DEBUG)
logger.disabled = False
logger.propagate = False

for h in list(logger.handlers):
    logger.removeHandler(h)

handler = ASAPHandler()
handler.setLevel(logging.DEBUG)
handler.setFormatter(logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
))

logger.addHandler(handler)

_info = logger.info
_debug = logger.debug
_warn = logger.warning




