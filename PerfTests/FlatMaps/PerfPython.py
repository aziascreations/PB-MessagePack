# Writes and reads the workload shared with the PureBasic tests, see `_Workload.pbi`.
# The maps are packed from and unpacked to dicts, how they're usually handled in Python.
import sys
from pathlib import Path

import msgpack

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from _PerfTesting import run

MAPS = 100_000
MAP = {f"Key{i:02}": i for i in range(16)}


def write():
    packer = msgpack.Packer(autoreset=False)
    pack = packer.pack
    for _ in range(MAPS):
        pack(MAP)
    return packer.bytes()


def read():
    unpacker = msgpack.Unpacker(raw=False)
    unpacker.feed(ENCODED)
    unpack = unpacker.unpack
    total = 0
    for _ in range(MAPS):
        for key, value in unpack().items():
            total += len(key) + value
    return total


ENCODED = write()

run("write", MAPS, lambda: len(write()))
run("read", MAPS, read)
