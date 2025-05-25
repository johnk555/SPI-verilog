`timescale 1ns / 1ps

module spi_tb;

// Testbench signals
reg        clk;
reg        rst;
reg        start;
reg  [7:0] master_data_in;
wire [7:0] master_data_out;
wire       master_busy;
wire       sclk;
wire       mosi;
wire       ss;
wire       miso;

// Instantiate master and slave
spi_master master (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data_in(master_data_in),
    .miso(miso),
    .sclk(sclk),
    .mosi(mosi),
    .ss(ss),
    .data_out(master_data_out),
    .busy(master_busy)
);

spi_slave slave (
    .sclk(sclk),
    .rst(rst),    // Connected to system reset
    .ss(ss),
    .mosi(mosi),
    .miso(miso)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
end

// Test sequence
initial begin
    // Initialize inputs
    rst = 1;
    start = 0;
    master_data_in = 0;
    
    // Reset system
    #20;
    rst = 0;
    
    // Start transmission
    #10;
    master_data_in = 8'h12; // Send 0x12
    start = 1;
    #10;
    start = 0;
    
    // Wait for completion
    wait(master_busy == 0);
    #10;
    
    // Verify results
    $display("Master received: 0x%h", master_data_out);
    if (master_data_out === 8'hA5) 
        $display("Test PASSED - Correct data received");
    else 
        $display("Test FAILED - Incorrect data");
     $finish;
end

initial begin
    $monitor("Time=%0t: ss=%b, sclk=%b, miso=%b, data_out=0x%h", 
             $time, ss, sclk, miso, master_data_out);
end

endmodule
