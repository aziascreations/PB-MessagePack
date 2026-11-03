// Writes and reads the workload shared with the PureBasic tests, see `../_Workload.pbi`.
// Uses the low-level MessagePackWriter/MessagePackReader from MessagePack-CSharp, pinned in the .csproj.
using System.Buffers;
using MessagePack;

const int TotalSize = 33_554_432;

foreach (int size in new[] { 8, 1024, 65536 })
{
	int count = TotalSize / size;
	string text = new string('a', size);
	byte[] encoded = WriteStrings(text, count);
	Perf.Run($"str-{size}-write", count, () => WriteStrings(text, count).Length);
	Perf.Run($"str-{size}-read", count, () => ReadStrings(encoded, count));
}

foreach (int size in new[] { 1024, 1048576 })
{
	int count = TotalSize / size;
	byte[] data = new byte[size];
	Array.Fill(data, (byte)0xAB);
	byte[] output = new byte[size];
	byte[] encoded = WriteBinaries(data, count);
	Perf.Run($"bin-{size}-write", count, () => WriteBinaries(data, count).Length);
	Perf.Run($"bin-{size}-read", count, () => ReadBinaries(encoded, count, output));
}
return 0;


static byte[] WriteStrings(string text, int count)
{
	var buffer = new ArrayBufferWriter<byte>();
	var writer = new MessagePackWriter(buffer);
	for (int i = 0; i < count; i++)
	{
		writer.Write(text);
	}
	writer.Flush();
	return buffer.WrittenSpan.ToArray();
}

static long ReadStrings(byte[] encoded, int count)
{
	var reader = new MessagePackReader(encoded);
	long total = 0;
	for (int i = 0; i < count; i++)
	{
		total += reader.ReadString()!.Length;
	}
	return total;
}

static byte[] WriteBinaries(byte[] data, int count)
{
	var buffer = new ArrayBufferWriter<byte>();
	var writer = new MessagePackWriter(buffer);
	for (int i = 0; i < count; i++)
	{
		writer.Write(data);
	}
	writer.Flush();
	return buffer.WrittenSpan.ToArray();
}

// Copies each field into `output`, like the PureBasic test.
static long ReadBinaries(byte[] encoded, int count, byte[] output)
{
	var reader = new MessagePackReader(encoded);
	long total = 0;
	for (int i = 0; i < count; i++)
	{
		var bytes = reader.ReadBytes()!.Value;
		bytes.CopyTo(output);
		total += bytes.Length;
	}
	return total;
}
