// Writes, reads and skips the workload shared with the PureBasic tests, see `../_Workload.pbi`.
// Uses the low-level MessagePackWriter/MessagePackReader from MessagePack-CSharp, pinned in the .csproj.
using System.Buffers;
using MessagePack;

const int Records = 125_000;
const int Fields = Records * 8;

byte[] encoded = Write();

Perf.Run("write", Fields, () => Write().Length);
Perf.Run("read", Fields, () => Read(encoded));
Perf.Run("skip", Fields, () => Skip(encoded));
return 0;


static byte[] Write()
{
	var buffer = new ArrayBufferWriter<byte>();
	var writer = new MessagePackWriter(buffer);
	for (int i = 0; i < Records; i++)
	{
		writer.Write(42);
		writer.Write(-5);
		writer.Write(200);
		writer.Write(-1000);
		writer.Write(70000);
		writer.Write(-1099511627776L);
		writer.Write(3.14);
		writer.Write("Hello");
	}
	writer.Flush();
	return buffer.WrittenSpan.ToArray();
}

static long Read(byte[] data)
{
	var reader = new MessagePackReader(data);
	long total = 0;
	for (int i = 0; i < Records; i++)
	{
		total += reader.ReadInt64();
		total += reader.ReadInt64();
		total += reader.ReadInt64();
		total += reader.ReadInt64();
		total += reader.ReadInt64();
		total += reader.ReadInt64();
		total += (long)reader.ReadDouble();
		total += reader.ReadString()!.Length;
	}
	return total;
}

static long Skip(byte[] data)
{
	var reader = new MessagePackReader(data);
	for (int i = 0; i < Fields; i++)
	{
		reader.Skip();
	}
	return Fields;
}
