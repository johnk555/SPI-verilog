# SPI Master and SPI Slave Implementations

SPI Master Module
The SPI Master module handles:

Clock Generation (SCK): Generates the clock signal for synchronous communication.

Chip Select (CS): Activates the slave for data transfer.

Data Transmission (MOSI): Sends out data bit by bit on each clock cycle.

Data Reception (MISO): Receives data from the slave device.

State Machine Logic: Manages states (IDLE, SEND, RECEIVE, DONE) to control the flow.

SPI Slave Module
The SPI Slave module handles:

Data Reception (MOSI): Receives data from the master, bit by bit, on the negative edge of SCK.

Data Transmission (MISO): Sends out data to the master on the positive edge of SCK.

Chip Select (CS): Communication only happens when CS is active low.

Shift Register Logic: Buffers incoming and outgoing data for synchronous transfer.
