`timescale 1ns / 1ps

module tb_spi;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg [7:0] master_tx_data_tb;
    reg start_transfer_tb;

    // SPI bus connections
    wire sclk_tb;
    wire ss_n_tb;
    wire mosi_tb;
    wire miso_tb;

    wire [7:0] master_rx_data_tb;
    wire master_transfer_done_tb;

    wire [7:0] slave_rx_data_tb;
    wire slave_data_received_tb;
    reg [7:0] slave_tx_data_tb;

    // Instantiate Master
    spi_master UUT_MASTER (
        .clk              (clk),
        .rst_n            (rst_n),
        .tx_data          (master_tx_data_tb),
        .start_transfer   (start_transfer_tb),
        .transfer_done    (master_transfer_done_tb),
        .sclk             (sclk_tb),
        .ss_n             (ss_n_tb),
        .mosi             (mosi_tb),
        .miso             (miso_tb),
        .rx_data          (master_rx_data_tb)
    );

    // Instantiate Slave
    spi_slave UUT_SLAVE (
        .clk              (clk),
        .rst_n            (rst_n),
        .sclk             (sclk_tb),
        .ss_n             (ss_n_tb),
        .mosi             (mosi_tb),
        .miso             (miso_tb),
        .slave_tx_data    (slave_tx_data_tb),
        .slave_rx_data    (slave_rx_data_tb),
        .data_received    (slave_data_received_tb)
    );

    // Clock generation
    parameter CLK_PERIOD = 10; // 10ns for 100MHz clock
    initial begin
        clk = 0;
        forever #((CLK_PERIOD)/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        rst_n = 0; // Assert reset
        master_tx_data_tb = 8'h00;
        start_transfer_tb = 0;
        slave_tx_data_tb = 8'hAA; // Slave will send this data back

        #(CLK_PERIOD * 2);
        rst_n = 1; // Release reset
        #(CLK_PERIOD * 2);

        $display("--- Starting SPI Transfer 1 ---");
        master_tx_data_tb = 8'h5A; // Master sends 0x5A
        start_transfer_tb = 1;
        #(CLK_PERIOD);
        start_transfer_tb = 0; // De-assert start_transfer

        // Wait for master to complete transfer
        @(posedge master_transfer_done_tb);
        $display("Master Transfer 1 Done. Master RX: 0x%h, Slave RX: 0x%h", master_rx_data_tb, slave_rx_data_tb);

        #(CLK_PERIOD * 10); // Wait a bit

        $display("--- Starting SPI Transfer 2 ---");
        master_tx_data_tb = 8'hC3; // Master sends 0xC3
        slave_tx_data_tb = 8'hB5; // Slave will send this data back
        start_transfer_tb = 1;
        #(CLK_PERIOD);
        start_transfer_tb = 0;

        @(posedge master_transfer_done_tb);
        $display("Master Transfer 2 Done. Master RX: 0x%h, Slave RX: 0x%h", master_rx_data_tb, slave_rx_data_tb);

        #(CLK_PERIOD * 10);

        $display("--- Starting SPI Transfer 3 (Slave no data) ---");
        master_tx_data_tb = 8'h12; // Master sends 0x12
        slave_tx_data_tb = 8'h00; // Slave sends 0x00 back
        start_transfer_tb = 1;
        #(CLK_PERIOD);
        start_transfer_tb = 0;

        @(posedge master_transfer_done_tb);
        $display("Master Transfer 3 Done. Master RX: 0x%h, Slave RX: 0x%h", master_rx_data_tb, slave_rx_data_tb);

        #(CLK_PERIOD * 20);

        $finish;
    end

    // Monitoring signals (optional, for debugging)
    initial begin
        $monitor("Time: %0t, CLK: %b, RST_N: %b, SCLK: %b, SS_N: %b, MOSI: %b, MISO: %b, Master_State: %b, Slave_State: %b, Master_TX: %h, Master_RX: %h, Slave_RX: %h, UUT_MASTER.current_state: %h, UUT_SLAVE.current_slave_state: %h",
                 $time, clk, rst_n, sclk_tb, ss_n_tb, mosi_tb, miso_tb, UUT_MASTER.current_state, UUT_SLAVE.current_slave_state,
                 UUT_MASTER.master_tx_data, UUT_MASTER.master_rx_data, UUT_SLAVE.slave_rx_data, UUT_MASTER.current_state, UUT_SLAVE.current_slave_state);
    end

endmodule
