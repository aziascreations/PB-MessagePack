# Writes, reads and skips the workload shared with the PureBasic tests, see `_Workload.pbi`.
import sys
from pathlib import Path

import msgpack

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from _PerfTesting import run

RECORDS = 125_000
FIELDS = RECORDS * 8


def write():
    packer = msgpack.Packer(autoreset=False)
    pack = packer.pack
    for _ in range(RECORDS):
        pack(42)
        pack(-5)
        pack(200)
        pack(-1000)
        pack(70000)
        pack(-1099511627776)
        pack(3.14)
        pack("Hello")
    return packer.bytes()


def read():
    unpacker = msgpack.Unpacker(raw=False)
    unpacker.feed(ENCODED)
    unpack = unpacker.unpack
    total = 0
    for _ in range(RECORDS):
        total += unpack() + unpack() + unpack() + unpack() + unpack() + unpack()
        total += int(unpack())
        total += len(unpack())
    return total


def skip():
    unpacker = msgpack.Unpacker(raw=False)
    unpacker.feed(ENCODED)
    skip_field = unpacker.skip
    for _ in range(FIELDS):
        skip_field()
    return FIELDS


ENCODED = write()

run("write", FIELDS, lambda: len(write()))
run("read", FIELDS, read)
run("skip", FIELDS, skip)
