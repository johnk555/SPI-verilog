// SPI Master Module
module SPI_Master (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    output reg sck,
    output reg mosi,
    input wire miso,
    output reg cs
);

    parameter DIV = 4;
    reg [2:0] clk_count;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        SEND = 2'b01,
        RECEIVE = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sck <= 0;
            cs <= 1;
            clk_count <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            data_out <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    cs <= 1;
                    sck <= 0;
                    if (start) begin
                        shift_reg <= data_in;
                        cs <= 0;
                        state <= SEND;
                    end
                end

                SEND: begin
                    if (clk_count == DIV) begin
                        clk_count <= 0;
                        sck <= ~sck;
                        if (sck) begin
                            mosi <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_count <= bit_count + 1;
                            if (bit_count == 7) state <= RECEIVE;
                        end
                    end else clk_count <= clk_count + 1;
                end

                RECEIVE: begin
                    if (clk_count == DIV) begin
                        clk_count <= 0;
                        sck <= ~sck;
                        if (!sck) begin
                            data_out <= {data_out[6:0], miso};
                            bit_count <= bit_count + 1;
                            if (bit_count == 7) state <= DONE;
                        end
                    end else clk_count <= clk_count + 1;
                end

                DONE: begin
                    cs <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

// SPI Slave Module
module SPI_Slave (
    input wire clk,
    input wire rst,
    input wire sck,
    input wire mosi,
    output reg miso,
    input wire cs,
    output reg [7:0] data_out,
    input wire [7:0] data_in
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
            if (bit_count == 7) data_out <= shift_reg;
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

// Testbench
module SPI_Testbench;
    reg clk, rst, start;
    reg [7:0] master_data_in, slave_data_in;
    wire [7:0] master_data_out, slave_data_out;
    wire sck, mosi, miso, cs;

    // Instantiate SPI Master
    SPI_Master master (
        .clk(clk), .rst(rst), .start(start),
        .data_in(master_data_in), .data_out(master_data_out),
        .sck(sck), .mosi(mosi), .miso(miso), .cs(cs)
    );

    // Instantiate SPI Slave
    SPI_Slave slave (
        .clk(clk), .rst(rst), .sck(sck), 
        .mosi(mosi), .miso(miso), .cs(cs),
        .data_out(slave_data_out), .data_in(slave_data_in)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        master_data_in = 8'b10101010;
        slave_data_in = 8'b11001100;
        #20 rst = 0;

        // Start SPI transaction
        #10 start = 1;
        #10 start = 0;

        // Wait for completion
        #200;

        // Check results
        $display("Master Sent: %b", master_data_in);
        $display("Slave Sent: %b", slave_data_in);
        $display("Master Received: %b", master_data_out);
        $display("Slave Received: %b", slave_data_out);

        // Test completion
        #20 $stop;
    end
endmodule

