"""Register this batch; see registration.md for hash-bound reviews and safe pruning."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / 'tools'))
from registration import main

if __name__ == '__main__':
    main()
