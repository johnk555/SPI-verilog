`timescale 1ns / 1ps

module SPI_Testbench;
    // Clock and Reset
    reg clk;
    reg rst;
    
    // Master Interface
    reg start;
    reg [7:0] master_data_in;
    wire [7:0] master_data_out;
    wire sck, mosi, cs;

    // Slave Interface
    wire miso;
    reg [7:0] slave_data_in;
    wire [7:0] slave_data_out;

    // Instantiate Master and Slave
    SPI_Master master (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(master_data_in),
        .data_out(master_data_out),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    SPI_Slave slave (
        .clk(clk),
        .rst(rst),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .data_out(slave_data_out),
        .data_in(slave_data_in)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        master_data_in = 8'h00;
        slave_data_in = 8'h00;
        
        // Apply Reset
        #10;
        rst = 0;

        // Test Case 1: Send 8'hA5 from Master to Slave
        #10;
        master_data_in = 8'hA5;
        slave_data_in = 8'h5A;
        start = 1;
        
        #10;
        start = 0;

        // Wait for the transaction to complete
        #200;
        
        // Display the results
        $display("Master sent: 0x%h", 8'hA5);
        $display("Slave received: 0x%h", slave_data_out);
        $display("Slave sent: 0x%h", 8'h5A);
        $display("Master received: 0x%h", master_data_out);

        // Test Case 2: Send 8'h3C from Master to Slave
        #20;
        master_data_in = 8'h3C;
        slave_data_in = 8'hC3;
        start = 1;
        
        #10;
        start = 0;

        // Wait for the transaction to complete
        #200;

        // Display the results
        $display("Master sent: 0x%h", 8'h3C);
        $display("Slave received: 0x%h", slave_data_out);
        $display("Slave sent: 0x%h", 8'hC3);
        $display("Master received: 0x%h", master_data_out);

        $finish;
    end
endmodule

