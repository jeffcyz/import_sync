
Stop retrying the kb-build command blindly.

The previous terminal became unavailable, and the initial
execution failed with "No module named asap_calc_replica".

Please diagnose and fix the execution environment first.

1. Confirm the actual repository root and working directory.
2. Inspect pyproject.toml and the src/asap_calc_replica package.
3. Identify the active Python interpreter and environment.
4. Configure a persistent editable package installation
   using `python -m pip install -e .` if appropriate,
   rather than relying on a temporary PYTHONPATH.
5. Verify that `python -m asap_calc_replica.cli --help`
   works before attempting kb-build.
6. Check whether the previous kb-build process is still
   running before starting another one.
7. Use a fresh terminal if the previous terminal is dead.
8. Only after the environment is verified, run:
   python -m asap_calc_replica.cli kb-build --full

Monitor the execution, capture the actual exit status,
and verify the expected KB outputs.

If the build takes a long time, do not repeatedly restart
it or lose track of the active process.

Do not modify the calculation logic or KB architecture
unless necessary to resolve the execution issue.
