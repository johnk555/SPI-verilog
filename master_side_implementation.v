""module SPI_Master (
    input wire clk,                 // System clock
    input wire rst,                 // Reset signal
    input wire start,               // Start transaction
    input wire [7:0] data_in,       // Data to send
    output reg [7:0] data_out,      // Data received
    output reg sck,                 // SPI Clock
    output reg mosi,                // Master Out Slave In
    input wire miso,                // Master In Slave Out
    output reg cs                   // Chip Select (Active Low)
);

    // SPI clock divider
    parameter DIV = 4;
    reg [2:0] clk_count;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;

    // State Machine
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
                            if (bit_count == 7) begin
                                state <= RECEIVE;
                            end
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                RECEIVE: begin
                    if (clk_count == DIV) begin
                        clk_count <= 0;
                        sck <= ~sck;
                        if (!sck) begin
                            data_out <= {data_out[6:0], miso};
                            bit_count <= bit_count + 1;
                            if (bit_count == 7) begin
                                state <= DONE;
                            end
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DONE: begin
                    cs <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
""
