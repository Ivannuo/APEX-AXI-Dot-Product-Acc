
`timescale 1ns / 1ps

module tb_dot_product;

reg clk = 0;
reg rstn = 0;

// Clock generation
always #5 clk = ~clk;

// AXI-Lite interface
reg [4:0] S_AXI_AWADDR;
reg [2:0] S_AXI_AWPROT = 0;
reg       S_AXI_AWVALID = 0;
wire      S_AXI_AWREADY;// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
reg [31:0] S_AXI_WDATA;// Write address valid. This signal indicates that the master signaling valid write address and control information.
reg [3:0]  S_AXI_WSTRB = 4'hF;
reg        S_AXI_WVALID = 0;
wire       S_AXI_WREADY;// Write ready. This signal indicates that the slave can accept the write data.
wire [1:0] S_AXI_BRESP;
wire       S_AXI_BVALID;
reg        S_AXI_BREADY = 1;// Response ready. This signal indicates that the master can accept a write response.
reg [4:0]  S_AXI_ARADDR;
reg [2:0]  S_AXI_ARPROT = 0;
reg        S_AXI_ARVALID = 0;
wire       S_AXI_ARREADY;
wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;
wire        S_AXI_RVALID;
reg         S_AXI_RREADY = 1;

// AXI Master interface
wire [31:0] M_AXI_AWADDR;
wire        M_AXI_AWVALID;
reg         M_AXI_AWREADY = 1;
wire [31:0] M_AXI_WDATA;
wire [3:0]  M_AXI_WSTRB;
wire        M_AXI_WVALID;
reg         M_AXI_WREADY = 1;
reg  [1:0]  M_AXI_BRESP = 0;
reg         M_AXI_BVALID = 0;
wire        M_AXI_BREADY;
wire [31:0] M_AXI_ARADDR;
wire        M_AXI_ARVALID;
reg         M_AXI_ARREADY = 1;
reg [31:0]  M_AXI_RDATA = 0;
reg         M_AXI_RVALID = 0;
wire        M_AXI_RREADY;
reg  [1:0]  M_AXI_RRESP = 0;

// Memory model
reg [31:0] mem [0:255];

// Connect DUT
dot_product_top dut (
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .M_AXI_ACLK(clk),
    .M_AXI_ARESETN(rstn),
    .M_AXI_AWADDR(M_AXI_AWADDR),
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_AWREADY(M_AXI_AWREADY),
    .M_AXI_WDATA(M_AXI_WDATA),
    .M_AXI_WSTRB(M_AXI_WSTRB),
    .M_AXI_WVALID(M_AXI_WVALID),
    .M_AXI_WREADY(M_AXI_WREADY),
    .M_AXI_BRESP(M_AXI_BRESP),
    .M_AXI_BVALID(M_AXI_BVALID),
    .M_AXI_BREADY(M_AXI_BREADY),
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .M_AXI_RDATA(M_AXI_RDATA),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_RREADY(M_AXI_RREADY),
    .M_AXI_RRESP(M_AXI_RRESP)
);

// AXI-Lite write task
task axi_lite_write(input [4:0] addr, input [31:0] data);
begin
    @(posedge clk);
    S_AXI_AWADDR <= addr << 2;
    S_AXI_WDATA  <= data;
    S_AXI_AWVALID <= 1;
    S_AXI_WVALID  <= 1;
    wait (S_AXI_AWREADY && S_AXI_WREADY);
    @(posedge clk);
    S_AXI_AWVALID <= 0;
    S_AXI_WVALID  <= 0;
end
endtask

// Correct Result of Dot Product
integer base_a = 16;
integer base_b = 17;
integer length = 4;
integer output_addr = 32;

function [31:0] expected_dot_product;
    input integer base_a;
    input integer base_b;
    input integer length;
    integer i;
    begin
        expected_dot_product = 0;
        for (i = 0; i < length; i = i + 1) begin
            expected_dot_product = expected_dot_product + $signed(mem[base_a + 2*i] * mem[base_b + 2*i]);
        end
    end
endfunction


// Memory read/write responder
always @(posedge clk) begin
    if (M_AXI_ARVALID) begin
        M_AXI_RVALID <= 1;
        M_AXI_RDATA  <= mem[M_AXI_ARADDR >> 2];
    end else if (M_AXI_RVALID && M_AXI_RREADY) begin
        M_AXI_RVALID <= 0;
    end

    if (M_AXI_AWVALID && M_AXI_WVALID) begin
        mem[M_AXI_AWADDR >> 2] <= M_AXI_WDATA;
        M_AXI_BVALID <= 1;
    end else if (M_AXI_BVALID && M_AXI_BREADY) begin
        M_AXI_BVALID <= 0;
    end
end

// Test
initial begin
    $display("Start testbench...");
    rstn = 0;
    repeat(5) @(posedge clk);
    rstn = 1;

    // Preload memory A and B
    mem[16] = 32'sd3; // A[0]
    mem[17] = 32'sd4; // B[0]
    mem[18] = -32'sd5; // A[1]
    mem[19] = 32'sd6; // B[1]
    mem[20] = -32'sd7;
    mem[21] = 32'sd8;
    mem[22] = 32'sd9;
    mem[23] = 32'sd10;

    // AXI-Lite config
    axi_lite_write(5'd1, 16*4); // A address
    axi_lite_write(5'd2, 17*4); // B address
    axi_lite_write(5'd3, 4);    // length = 4
    axi_lite_write(5'd4, 32*4); // output address
    axi_lite_write(5'd0, 32'h1); // start

    // Wait
    #500;
    
    // Show results
    $display("Result in memory[%0d] = %d", output_addr, mem[output_addr]);
        if (mem[output_addr] !== expected_dot_product(base_a, base_b, length)) begin
            $fatal("Dot product incorrect!Should be %d.",expected_dot_product(base_a, base_b, length));
        end else begin
            $display("Dot product correct!");
    end

    #100;

    $finish;
end
endmodule