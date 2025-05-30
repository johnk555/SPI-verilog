module SPI_Slave (
    input wire clk,                 // System clock
    input wire rst,                 // Reset signal
    input wire sck,                 // SPI Clock from Master
    input wire mosi,                // Master Out Slave In
    output reg miso,                // Master In Slave Out
    input wire cs,                  // Chip Select (Active Low)
    output reg [7:0] data_out,      // Data received
    input wire [7:0] data_in        // Data to send back
);

    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    always @(negedge sck or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            bit_count <= 0;
            data_out <= 0;
        end else if (!cs) begin
            shift_reg <= {shift_reg[6:0], mosi};
            bit_count <= bit_count + 1;
            if (bit_count == 7) begin
                data_out <= shift_reg;
            end
        end
    end

    always @(posedge sck or posedge rst) begin
        if (rst) begin
            miso <= 0;
        end else if (!cs) begin
            miso <= data_in[7 - bit_count];
        end
    end
endmodule
""
