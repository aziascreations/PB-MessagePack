# Writes and reads the workload shared with the PureBasic tests, see `_Workload.pbi`.
import sys
from pathlib import Path

import msgpack

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from _PerfTesting import run

TOTAL_SIZE = 33_554_432


def write(value, count):
    packer = msgpack.Packer(autoreset=False)
    pack = packer.pack
    for _ in range(count):
        pack(value)
    return packer.bytes()


def read(encoded, count):
    unpacker = msgpack.Unpacker(raw=False, max_buffer_size=len(encoded))
    unpacker.feed(encoded)
    unpack = unpacker.unpack
    total = 0
    for _ in range(count):
        total += len(unpack())
    return total


def run_scenarios(name, value):
    count = TOTAL_SIZE // len(value)
    encoded = write(value, count)
    run(f"{name}-{len(value)}-write", count, lambda: len(write(value, count)))
    run(f"{name}-{len(value)}-read", count, lambda: read(encoded, count))


for size in (8, 1024, 65536):
    run_scenarios("str", "a" * size)

for size in (1024, 1048576):
    run_scenarios("bin", b"\xab" * size)
