// spi_slave.v
module spi_slave (
    input clk,            // System clock
    input rst_n,          // Asynchronous reset (active low)

    // SPI bus signals
    input sclk,           // Serial Clock
    input ss_n,           // Slave Select (active low)
    input mosi,           // Master Out Slave In
    output reg miso,      // Master In Slave Out

    // Slave configuration
    input [7:0] slave_tx_data, // Data slave will transmit back
    output reg [7:0] slave_rx_data, // Data received by slave
    output reg data_received     // Indicates data has been received
);

    // --- State Machine Registers ---
    reg [1:0] current_slave_state, next_slave_state;
    localparam SLAVE_IDLE      = 2'b00;
    localparam SLAVE_ACTIVE    = 2'b01;
    localparam SLAVE_COMPLETE  = 2'b10;

    reg [7:0] slave_shift_reg;   // Shift register for MOSI data (data received by slave)
    reg [7:0] slave_miso_reg;    // Register for MISO data (data slave will transmit)
    reg [3:0] bit_counter;

    reg prev_sclk; // To detect rising/falling edges of SCLK
    reg prev_ss_n; // To detect rising/falling edges of SS_N

    // Detect SCLK and SS_N edges synchronously
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sclk <= 0;
            prev_ss_n <= 1; // SS_N is typically high when idle
        end else begin
            prev_sclk <= sclk;
            prev_ss_n <= ss_n;
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

    // Synchronous data processing for slave (MOSI capture, RX data commit, and counter reset)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_shift_reg <= 8'b0;
            slave_rx_data   <= 8'b0;
            bit_counter     <= 0;
            data_received   <= 0; // Reset data_received
        end else begin
            // Reset bit_counter and data_received when SS_n goes high (end of transfer)
            // This is crucial for handling multiple transfers
            if (ss_n == 1 && prev_ss_n == 0) begin // Detect rising edge of SS_n
                bit_counter <= 0; // Reset counter for the next transfer
                data_received <= 1; // Assert data_received for one cycle when SS_n goes high
                                    // This makes it a pulse, which is often more useful
                slave_rx_data <= slave_shift_reg; // Commit the data when SS_n goes high
            end else if (data_received == 1) begin
                data_received <= 0; // Clear data_received after one cycle (make it a pulse)
            end

            // When slave is active and SCLK is rising edge (for MOSI capture)
            if (current_slave_state == SLAVE_ACTIVE && sclk == 1 && prev_sclk == 0) begin
                if (bit_counter < 8) begin // Only capture if less than 8 bits
                    slave_shift_reg[7 - bit_counter] <= mosi; // Capture MOSI bit
                    bit_counter <= bit_counter + 1; // Increment bit counter
                end
            end

            // We moved slave_rx_data commitment to the ss_n rising edge detection for robustness
            // No need for redundant assignments here.
        end
    end

    // Next State Logic and Output Logic (Combinational)
    always @(*) begin
        next_slave_state = current_slave_state;
        // data_received is now handled synchronously in the other always block
        miso             = 1'bz; // Default to high-z if not explicitly driven in current state

        case (current_slave_state)
            SLAVE_IDLE: begin
                // Ensure bit_counter is 0 before starting a new transfer
                // This is now handled by the prev_ss_n edge detection
                if (!ss_n) begin // Slave selected (SS_n low)
                    next_slave_state = SLAVE_ACTIVE;
                    slave_miso_reg = slave_tx_data; // Load data to be sent for THIS transfer
                end
                miso = 1'bz; // MISO is high-Z when slave is idle/deselected
            end

            SLAVE_ACTIVE: begin
                if (ss_n) begin // Master deselected slave prematurely or at end of transfer
                    next_slave_state = SLAVE_IDLE;
                    // data_received handled by prev_ss_n edge detection
                end else if (bit_counter == 8) begin // All 8 bits received
                    next_slave_state = SLAVE_COMPLETE;
                end else begin
                    // MISO driving logic for CPOL=0, CPHA=0
                    // MISO changes on falling edge of SCLK and is stable on rising edge.
                    // The bit_counter is incremented on the rising edge, so it points to the NEXT bit to be received.
                    // Therefore, for MISO, we want to output the bit corresponding to the current state of the bit_counter.
                    miso = slave_miso_reg[7 - bit_counter]; // Drive the current bit to be sent
                end
            end

            SLAVE_COMPLETE: begin
                // data_received will remain high for one cycle via the synchronous block.
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
