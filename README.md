# SPI Master and SPI Slave Implementations
=================
SPI Master Module.
The SPI Master module handles:

1. Clock Generation (SCK): Generates the clock signal for synchronous communication.

2. Chip Select (CS): Activates the slave for data transfer.

3. Data Transmission (MOSI): Sends out data bit by bit on each clock cycle.

4. Data Reception (MISO): Receives data from the slave device.

5. State Machine Logic: Manages states (IDLE, SEND, RECEIVE, DONE) to control the flow.

SPI Slave Module
The SPI Slave module handles:

1. Data Reception (MOSI): Receives data from the master, bit by bit, on the negative edge of SCK.

2. Data Transmission (MISO): Sends out data to the master on the positive edge of SCK.

3. Chip Select (CS): Communication only happens when CS is active low.

4. Shift Register Logic: Buffers incoming and outgoing data for synchronous transfer.
