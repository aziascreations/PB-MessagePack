// Shared by the .NET performance tests, see `_PerfTesting.pbi` for the output format.
using System.Diagnostics;

static class Perf
{
	const int Runs = 5;

	// Runs `function` once to warm up, then `Runs` times, and prints its median.
	public static void Run(string scenario, long operations, Func<long> function)
	{
		long check = function();
		var times = new double[Runs];
		for (int i = 0; i < Runs; i++)
		{
			var stopwatch = Stopwatch.StartNew();
			check = function();
			times[i] = stopwatch.Elapsed.TotalMilliseconds;
		}
		Array.Sort(times);
		double median = times[Runs / 2];
		Console.WriteLine($"dotnet,{scenario},{median:F1},{median * 1_000_000 / operations:F1},{check}");
	}
}
