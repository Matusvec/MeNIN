import os

# Tests never read homer/.env, never call Claude, and never touch SpacetimeDB.
os.environ["HOMER_DOTENV"] = "0"
os.environ["HOMER_WARM"] = "0"
for name in ("STDB_TOKEN", "HOMER_SERVICE_KEY", "ANTHROPIC_API_KEY"):
    os.environ.pop(name, None)
for name in ("HOMER_APP_KEY", "HOMER_APP_KEY_REQUIRED"):
    os.environ.pop(name, None)
