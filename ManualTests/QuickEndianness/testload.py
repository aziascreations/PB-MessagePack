import msgpack

with open("./test.mpack", "rb") as f:
    for value in msgpack.Unpacker(f):
        print(hex(value))

input()