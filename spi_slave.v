// spi_slave.v
module spi_slave (
    input clk,          // System clock
    input rst_n,        // Asynchronous reset (active low)

    // SPI bus signals
    input sclk,         // Serial Clock
    input ss_n,         // Slave Select (active low)
    input mosi,         // Master Out Slave In
    output reg miso,    // Master In Slave Out

    // Slave configuration
    input [7:0] slave_tx_data, // Data slave will transmit back
    output reg [7:0] slave_rx_data, // Data received by slave
    output reg data_received    // Indicates data has been received
);

    // --- State Machine Registers ---
    reg [1:0] current_slave_state, next_slave_state; // <-- THIS LINE MUST BE PRESENT
    localparam SLAVE_IDLE      = 2'b00;
    localparam SLAVE_ACTIVE    = 2'b01;
    localparam SLAVE_COMPLETE  = 2'b10;

    reg [7:0] slave_shift_reg;  // Shift register for MOSI data (data received by slave)
    reg [7:0] slave_miso_reg;   // Register for MISO data (data slave will transmit)
    reg [3:0] bit_counter;

    reg prev_sclk; // To detect rising/falling edges of SCLK

    // Detect SCLK edges synchronously
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sclk <= 0;
        end else begin
            prev_sclk <= sclk;
        end
    end

    // Slave State Register (Synchronous)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_slave_state <= SLAVE_IDLE;
        end else begin
            current_slave_state <= next_slave_state;
        end
    end

    // Synchronous data processing for slave (MOSI capture and RX data commit)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_shift_reg <= 8'b0;
            slave_rx_data   <= 8'b0;
            bit_counter     <= 0;
            // slave_miso_reg  <= 8'b0; // This is loaded combinatorially when slave is selected
        end else begin
            // When slave is active and SCLK is rising edge (for MOSI capture)
            if (current_slave_state == SLAVE_ACTIVE && sclk == 1 && prev_sclk == 0) begin
                slave_shift_reg[7 - bit_counter] <= mosi; // Capture MOSI bit
                bit_counter <= bit_counter + 1; // Increment bit counter
            end

            // When SS_n goes high or 8 bits are received, commit the received data
            // It's safer to commit when the state transitions out of ACTIVE/COMPLETE to IDLE
            if (current_slave_state == SLAVE_ACTIVE && bit_counter == 8) begin
                 slave_rx_data <= slave_shift_reg; // Commit the received data after all 8 bits
            end else if (current_slave_state == SLAVE_COMPLETE && next_slave_state == SLAVE_IDLE) begin
                 slave_rx_data <= slave_shift_reg; // Ensure final data is committed at the end of transfer
            end
        end
    end


    // Next State Logic and Output Logic (Combinational)
    always @(*) begin
        next_slave_state = current_slave_state;
        data_received    = 0;
        miso             = 1'bz; // Default to high-z if not explicitly driven in current state

        case (current_slave_state)
            SLAVE_IDLE: begin
                if (!ss_n) begin // Slave selected (SS_n low)
                    next_slave_state = SLAVE_ACTIVE;
                    slave_miso_reg = slave_tx_data; // Load data to be sent for THIS transfer
                end
                miso = 1'bz; // MISO is high-Z when slave is idle/deselected
            end

            SLAVE_ACTIVE: begin
                if (ss_n) begin // Master deselected slave prematurely or at end of transfer
                    next_slave_state = SLAVE_IDLE;
                    data_received = 1; // Indicate data was processed (even if partial)
                end else begin
                    // MISO driving logic for CPOL=0, CPHA=0
                    // MISO changes on falling edge of SCLK and is stable on rising edge.
                    // When SCLK is low, MISO should be the bit that the Master will sample on the *upcoming* rising edge.
                    // The bit_counter is incremented on the rising edge, so it points to the NEXT bit to be received.
                    // Therefore, for MISO, we want to output the bit corresponding to the current state of the bit_counter.
                    if (bit_counter <= 7) begin // Ensure we don't access out of bounds for the 8 bits
                        miso = slave_miso_reg[7 - bit_counter]; // Drive the current bit to be sent
                    end else begin
                        miso = 1'b0; // After 8 bits, if SS_n is still low, drive 0 (or 1'bz if that's your protocol's idle value)
                    end
                end
            end

            SLAVE_COMPLETE: begin
                data_received = 1; // Keep high until SS_n goes high
                if (ss_n) begin // Master deselected slave
                    next_slave_state = SLAVE_IDLE;
                end
                miso = 1'bz; // MISO is high-Z when slave is finished and waiting for deselect
            end

            default: begin
                next_slave_state = SLAVE_IDLE;
                miso = 1'bz;
            end
        endcase
    end

endmodule
