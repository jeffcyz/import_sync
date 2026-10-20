
import logging

# Custom logging handler for ASAP OUTPUT
class ASAPHandler(logging.Handler):
    def emit(self, record):
        try:
            msg = self.format(record)
            print(msg)
        except Exception as e:
            print("Logging error: {}".format(e))


# Configure logger
logger = logging.getLogger("asap_waterfall")

logging.disable(logging.NOTSET)
logger.disabled = False
logger.setLevel(logging.DEBUG)
logger.propagate = False

# Remove existing handlers
for h in list(logger.handlers):
    logger.removeHandler(h)

# Add custom ASAP handler
handler = ASAPHandler()
handler.setLevel(logging.DEBUG)
handler.setFormatter(
    logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
)

logger.addHandler(handler)

# Keep existing function aliases
_info = logger.info
_debug = logger.debug
_warn = logger.warning

# Diagnostics
print("=== LOGGING TEST START ===")
print("Logger:", logger.name)
print("Effective Level:", logger.getEffectiveLevel())
print("Handler Count:", len(logger.handlers))
print("DEBUG Enabled:", logger.isEnabledFor(logging.DEBUG))

logger.debug("DEBUG TEST")
logger.info("INFO TEST")
logger.warning("WARNING TEST")
logger.error("ERROR TEST")

print("=== LOGGING TEST END ===")
