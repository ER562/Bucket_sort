# Bucket sort implementation on FPGA

This project contains module source files and test files.

# Running the project

This project was created using Vivado 2018.3. To open it, simply open the "bucket_sort.xpr" file. Then run the simulation.

The result of the simulation will appear in the Tcl console.

If nothing appears, then run the simulation longer, as the time needed for completion is dependent on module parameters, which are:

* DATA_WIDTH - size of a single data point in bits
* DATA_VOLUME - number of data points
* DECISION_BITS - number of bits that take part in segregating incoming data into buckets