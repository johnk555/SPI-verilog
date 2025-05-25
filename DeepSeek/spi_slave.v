module spi_slave (
    input      sclk,    
    input      rst,     
    input      ss,      
    input      mosi,    
    output reg miso     
);

reg [7:0] shift_reg;    // Shift register for transmission
reg [7:0] tx_data = 8'hA5; // Data to send (0xA5)

// Reload shift_reg when ss activates (falling edge of ss)
always @(negedge ss or posedge rst) begin
    if (rst) begin
        shift_reg <= tx_data; // Initialize on reset
    end else begin
        shift_reg <= tx_data; // Reload at start of transaction
    end
end

// Shift left on RISING edge of SCLK (critical fix)
always @(posedge sclk) begin
    if (!ss) begin
        shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left
    end
end

// Output MSB of shift_reg
always @(*) begin
    if (!ss) begin
        miso = shift_reg[7]; // Immediate output when selected
    end else begin
        miso = 1'bz; // High-Z when deselected
    end
end

endmodule
