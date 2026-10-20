print("=== LOGGING DIAGNOSTICS ===")

root = logging.getLogger()

print("Root Level:", root.level)
print("Root Handlers:", root.handlers)
print("Logger Name:", logger.name)
print("Logger Effective Level:", logger.getEffectiveLevel())
print("Logger Disabled:", logger.disabled)
print("Logging Global Disable:", logging.root.manager.disable)

print("=== TEST ===")
print("Normal print works")
logger.debug("DEBUG TEST")
logger.info("INFO TEST")
logger.warning("WARNING TEST")
logger.error("ERROR TEST")