import asyncio
import sys

from .main import main

asyncio.run(main(sys.argv[1:]))
