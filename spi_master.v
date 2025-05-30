module spi_master (
    input clk,          // System clock
    input rst_n,        // Asynchronous reset (active low)

    // Master configuration
    input [7:0] tx_data,   // Data to transmit
    input start_transfer,  // Signal to start a new transfer
    output reg transfer_done, // Indicates transfer is complete

    // SPI bus signals
    output wire sclk,    // Serial Clock
    output reg ss_n,    // Slave Select (active low)
    output reg mosi,    // Master Out Slave In
    input miso,         // Master In Slave Out

    // Output the received data
    output reg [7:0] rx_data // THIS LINE IS NOW CORRECTLY 'output reg'
);

    // SPI State Machine States
    localparam IDLE         = 2'b00;
    localparam START_SS     = 2'b01;
    localparam SHIFT_DATA   = 2'b10;
    localparam END_SS       = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] bit_counter;    // Counter for 8 bits (0 to 7)
    reg [7:0] master_tx_data; // Internal register for data to send
    reg [7:0] master_rx_data; // Internal register for received data (will be assigned to rx_data)

    // Clock divider for SCLK (adjust 'SCLK_DIV_FACTOR' for desired SCLK frequency)
    // SCLK_freq = clk_freq / (2 * SCLK_DIV_FACTOR)
    parameter SCLK_DIV_FACTOR = 2; // For example, if clk = 100MHz, SCLK = 5MHz
    reg [SCLK_DIV_FACTOR-1:0] sclk_counter;
    reg sclk_toggle;

    // --- SCLK Generation ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_counter <= 0;
            sclk_toggle <= 0;
        end else begin
            if (current_state == SHIFT_DATA) begin // Only generate SCLK during data transfer
                if (sclk_counter == SCLK_DIV_FACTOR - 1) begin
                    sclk_counter <= 0;
                    sclk_toggle <= ~sclk_toggle; // This register will flip its value
                end else begin
                    sclk_counter <= sclk_counter + 1;
                end
            end else begin
                sclk_counter <= 0;
                sclk_toggle <= 0; // Keep sclk_toggle low when idle
            end
        end
    end
    
    assign sclk = sclk_toggle; // sclk output will directly follow sclk_toggle

    // --- State Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // --- Next State Logic and Output Logic ---
    always @(*) begin
        next_state     = current_state;
        transfer_done  = 0;
        ss_n           = 1;  // Default to high (inactive)
        mosi           = 1'bz; // Default to high-z (master will drive only when needed)
        // rx_data is assigned synchronously in the always @(posedge clk) block for current_state logic
        // or just assigned directly from master_rx_data below.

        case (current_state)
            IDLE: begin
                if (start_transfer) begin
                    next_state       = START_SS;
                    master_tx_data   = tx_data; // Load data to send
                    master_rx_data   = 8'b0;    // Clear received data register
                    bit_counter      = 0;
                end
                ss_n = 1; // SS_n high
            end

            START_SS: begin
                ss_n = 0; // Pull SS_n low to select slave
                next_state = SHIFT_DATA;
            end

            SHIFT_DATA: begin
                ss_n = 0; // Keep SS_n low
                mosi = master_tx_data[7 - bit_counter]; // MOSI: MSB first
                
                if (sclk_counter == SCLK_DIV_FACTOR - 1 && sclk_toggle == 1) begin // After a full SCLK period (falling edge)
                    if (bit_counter == 7) begin // All 8 bits transferred
                        next_state = END_SS;
                    end else begin
                        bit_counter = bit_counter + 1;
                    end
                end
            end

            END_SS: begin
                ss_n = 1; // Pull SS_n high to deselect slave
                transfer_done = 1; // Signal transfer completion
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // --- Synchronous MISO data capture and Master RX data assignment ---
    reg prev_sclk; // Add this to detect edges robustly

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sclk <= 0;
            master_rx_data <= 8'b0;
            rx_data <= 8'b0;
        end else begin
            prev_sclk <= sclk; // Update previous SCLK value

            if (current_state == SHIFT_DATA) begin
                // Capture MISO on the rising edge of SCLK (for CPOL=0, CPHA=0)
                if (sclk == 1 && prev_sclk == 0) begin // Detect rising edge of SCLK
                     master_rx_data[7 - bit_counter] <= miso;
                end
            end

            // Assign rx_data to the output once the transfer is truly done
            //if (current_state == END_SS && next_state == IDLE) begin // When the master transitions from END_SS back to IDLE
            // Assign rx_data to the output only when the transfer is truly done
            // AND hold it until a new transfer starts
            if (transfer_done == 1'b1) begin // This condition is true for one clock cycle when transfer is done
                rx_data <= master_rx_data;
            //end else if (current_state == IDLE) begin
            end else if (start_transfer == 1'b1) begin // Clear only when a new transfer begins
                rx_data <= 8'b0; // Clear output when idle
            end
        end
    end

endmodule
