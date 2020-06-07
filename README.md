# quWaveFunctionCollapse
A quantum implementation of the Wave Function Collapse algorithm 

## Running Procedure
To run a simple test case for VQE, execute the following command (NOTE: likely will not finish running):

`python host.py quantum`

To run a simple test with quantum random numbers on the classical algorithm, the following command
is reccomended:

`python .\host.py --outwidth 64 --outheight 64 --imgwidth 512 --imgheight 512 --qrng classical`


### Tests
Simply run the following command to test our encoding and variational circuit:

`python test.py`

This script acts as a unit test for small parts of the program. The `host.py` file
above runs the true algorithm.

## Algorithm Description
For the classical  algorithm, see the main repository [here](https://github.com/Chocomunk/WaveFunctionCollapse)

