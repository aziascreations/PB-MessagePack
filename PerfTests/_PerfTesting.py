# Shared by the Python performance tests, see `_PerfTesting.pbi` for the output format.
import statistics
import time

RUNS = 5


def run(scenario, operations, function):
    """Runs `function` once to warm up, then `RUNS` times, and prints its median."""
    check = function()
    times = []
    for _ in range(RUNS):
        start = time.perf_counter()
        check = function()
        times.append((time.perf_counter() - start) * 1000)
    median = statistics.median(times)
    print(f"python,{scenario},{median:.1f},{median * 1_000_000 / operations:.1f},{check}", flush=True)
