`timescale 1ns / 1ps
// Dot Product FSM
module dot_product_fsm(
    input   wire        clk             ,
    input   wire        resetn          ,
    input   wire        start_in        ,
    input   wire [31:0] addr_a_in       ,
    input   wire [31:0] addr_b_in       ,
    input   wire [31:0] length_in       ,
    input   wire [31:0] addr_out_in     ,
    output  reg  [31:0] status_out      ,
    output  reg         read_req        ,
    output  reg  [31:0] read_addr       ,
    input   wire [31:0] read_data       ,
    input   wire        read_data_valid ,
    output  reg         write_req       ,
    output  reg  [31:0]  write_addr     ,
    output  reg  [31:0]  write_data     ,
    input   wire write_done
);

reg [2:0]                   state;
reg [31:0]  a_addr, b_addr, count;
reg signed [31:0]     a_val, b_val;
reg signed [31:0]             acc;

reg  start_r1;
reg read_data_valid_r;

localparam IDLE=0, READ_A=1, READ_B=2, MULT=3, CHECK=4, WRITE=5, DONE=6;

// Generate Flag Signal for the rising edge of start_in
always @(posedge clk) start_r1 <= start_in;
assign start_edge = ~start_r1 && start_in;

// State Transition Logic of FSM
always @(posedge clk) begin
    if (!resetn) begin
        state <= IDLE;
        acc <= 0;
        read_req <= 0;
        write_req <= 0;
        status_out <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (start_edge) begin
                    a_addr <= addr_a_in;
                    b_addr <= addr_b_in;
                    count <= length_in;
                    acc <= 0;
                    read_req <= 1;
                    read_addr <= addr_a_in;                   
                    state <= READ_A;
                end
                else begin
                    state <= IDLE;
                    read_req <= 0;
                end
            end
            READ_A: begin
                if (read_data_valid) begin
                    a_val <= $signed(read_data[31:0]);
                    read_req <= 1;
                    read_addr <= b_addr;
                    state <= READ_B;
                end
            end
            READ_B: begin
                if (read_data_valid) begin
                    b_val <= $signed(read_data[31:0]);
                    read_req <= 0;
                    read_addr <= a_addr + 8;
                    state <= MULT;
                end
            end
            MULT: begin
                acc <= acc + a_val * b_val;
                count <= count - 1;
                if (count == 1) begin
                    state <= WRITE;
                    write_req <= 1;
                    write_addr <= addr_out_in;
                    write_data <= acc + a_val * b_val;
                end else begin
                    read_req <= 1;
                    a_addr <= a_addr + 8;
                    b_addr <= b_addr + 8;
                    state <= READ_A;
                end
            end
            WRITE: begin
                if (write_done) begin
                    write_req <= 0;
                    state <= DONE;
                end
            end
            DONE: begin
                status_out <= 32'h2;
                state <= IDLE;
            end
        endcase
    end
end
endmodule