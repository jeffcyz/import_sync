OUTPUT_FILE.write_text(
    combined,
    encoding="utf-8",
)

actual = OUTPUT_FILE.read_text(encoding="utf-8")

assert actual == combined


############


# Write exact UTF-8 bytes without newline conversion
OUTPUT_FILE.write_bytes(combined.encode("utf-8"))

# Read exact bytes without universal newline conversion
actual = OUTPUT_FILE.read_bytes().decode("utf-8")

assert actual == combined
