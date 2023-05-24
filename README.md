# Cache Bank-Aware DoS Attacks

This repository contains code for recreating the experimental results in our paper "Cache Bank-Aware Denial-of-Service Attacks on Multicore ARM Processors", which can be found [here](http://www.ittc.ku.edu/~heechul/papers/cachebank-rtas2023-camera.pdf).

Note that we only provide code for the experiments run with a synthetic workload as the victim task.

## Prerequisites

We assume that the LLC can be partitioned in these experiments. In our case, we used [PALLOC](https://github.com/heechul/palloc), which requires a kernel patch to work. Likewise, we use the [MemGuard](https://github.com/heechul/memguard) kernel module to perform bandwidth throttling. More detailed installation instructions for both tools can be found at their respective GitHub pages.

For MemGuard, the following changes on lines 534 and 535 are necessary to perform LLC bandwidth throttling for Figure 10 instead of the default DRAM bandwidth throttling used in Figure 6:

	533 struct perf_event_attr sched_perf_hw_attr = {
	534		/* use generalized hardware abstraction */
	535		.type           = PERF_TYPE_RAW,	// <- Change to this
	536		.config         = 0x03, // <- Change to this
	537		.size		= sizeof(struct perf_event_attr),
	538		.pinned		= 1,
	539		.disabled	= 1,
	540		.exclude_kernel = 1,   /* TODO: 1 mean, no kernel mode counting */
	541 };
	
Lastly, we use gnuplot to generate the figures for each test:

	$ sudo apt install gnuplot

## Setup

The synthetic benchmarks we use can be built as follows:

	$ cd workloads
	$ make
	$ cd ..
	
Note that we use hardware performance counters to track and measure LLC statistics (hits, misses, etc.), but that the counter names differ between the Raspberry Pi 4 and Nvidia Jetson Nano that we test. As such, you will need to comment/uncomment the following lines in the "functions" file to match the platform you are testing:

	8  # Performance counters for measuring LLC statistics
	9  count=armv8_cortex_a72/l2d_cache_refill/,armv8_cortex_a72/l2d_cache/		# For Pi 4
	10 #count=armv8_pmuv3/l2d_cache_refill/,armv8_pmuv3/l2d_cache/				# For Jetson Nano
	
## Running Tests

Each figure from the paper has their own respective test scripts that can be run to recreate their results. For example, the Figure 4 script can be run as follows:

	$ sudo ./Fig4.sh
	
Note that running the scripts with root permissions is required as the victim workloads are run as real-time tasks.

Once finished, each script will output the necessary results to a .dat file in the figures directory (e.g. figures/Fig4-Slowdown.dat, etc.).

## Plotting the Figures

The figures can all be plotted at the same time as follows:

	$ cd figures/
	$ gnuplot gen.gp
