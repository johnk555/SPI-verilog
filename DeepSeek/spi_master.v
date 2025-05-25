module spi_master (
    input        clk,      // System clock
    input        rst,      // System reset
    input        start,    // Start transfer signal
    input  [7:0] data_in,  // Data to transmit
    input        miso,     // Master In Slave Out
    output reg   sclk,     // SPI Clock
    output reg   mosi,     // Master Out Slave In
    output reg   ss,       // Slave Select (Active Low)
    output reg [7:0] data_out, // Received data
    output reg   busy      // Busy flag
);

reg [2:0] bit_count;      // Bit counter (0-7)
reg [7:0] tx_reg;         // Transmit shift register
reg [7:0] rx_reg;         // Receive shift register

// State machine parameters
localparam IDLE      = 2'b00;
localparam TRANSFER  = 2'b01;

reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state      <= IDLE;
        ss         <= 1'b1;
        sclk       <= 1'b0;
        mosi       <= 1'b0;
        busy       <= 1'b0;
        bit_count  <= 3'd0;
        data_out   <= 8'h00;
        tx_reg     <= 8'h00;
        rx_reg     <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin
                    ss       <= 1'b0;       // Activate slave
                    tx_reg   <= data_in;    // Load transmit data
                    busy     <= 1'b1;
                    state    <= TRANSFER;
                    sclk     <= 1'b0;       // Start with SCLK low (Mode 0)
                    bit_count <= 3'd0;
                end
            end

            TRANSFER: begin
                sclk <= ~sclk; // Toggle SCLK every clock cycle

                if (sclk) begin 
                    // Falling edge: Update MOSI
                    mosi   <= tx_reg[7];
                    tx_reg <= {tx_reg[6:0], 1'b0};
                end else begin 
                    // Rising edge: Sample MISO into MSB
                    rx_reg    <= {miso, rx_reg[7:1]}; // Shift right, MSB first
                    bit_count <= bit_count + 1;

                    // Check for completion after 8 bits
                    if (bit_count == 3'd7) begin
                        ss       <= 1'b1; // Deassert slave select
                        busy     <= 1'b0;
                        data_out <= rx_reg;
                        state    <= IDLE;
                    end
                end
            end
        endcase
    end
end

endmodule
