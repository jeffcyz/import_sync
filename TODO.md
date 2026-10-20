import logging
import sys

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.disabled = False

# Remove old handlers attached to this logger
for handler in list(logger.handlers):
    logger.removeHandler(handler)

# Redirect logging to ASAP OUTPUT
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)

handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))

logger.addHandler(handler)
logger.propagate = False

# Test
logger.debug("DEBUG TEST")
logger.info("INFO TEST")
logger.warning("WARNING TEST")
logger.error("ERROR TEST")