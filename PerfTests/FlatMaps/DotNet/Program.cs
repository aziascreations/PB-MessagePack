// Writes and reads the workload shared with the PureBasic tests, see `../_Workload.pbi`.
// Uses the low-level MessagePackWriter/MessagePackReader from MessagePack-CSharp, pinned in the .csproj.
using System.Buffers;
using MessagePack;

const int Maps = 100_000;
const int Entries = 16;

string[] keys = Enumerable.Range(0, Entries).Select(i => $"Key{i:D2}").ToArray();
byte[] encoded = Write(keys);

Perf.Run("write", Maps, () => Write(keys).Length);
Perf.Run("read", Maps, () => Read(encoded));
return 0;


static byte[] Write(string[] keys)
{
	var buffer = new ArrayBufferWriter<byte>();
	var writer = new MessagePackWriter(buffer);
	for (int i = 0; i < Maps; i++)
	{
		writer.WriteMapHeader(Entries);
		for (int j = 0; j < Entries; j++)
		{
			writer.Write(keys[j]);
			writer.Write(j);
		}
	}
	writer.Flush();
	return buffer.WrittenSpan.ToArray();
}

static long Read(byte[] encoded)
{
	var reader = new MessagePackReader(encoded);
	long total = 0;
	for (int i = 0; i < Maps; i++)
	{
		int count = reader.ReadMapHeader();
		for (int j = 0; j < count; j++)
		{
			total += reader.ReadString()!.Length;
			total += reader.ReadInt64();
		}
	}
	return total;
}
