`timescale 1ns / 1ps
module tb_dot_product;

reg clk = 0;
reg rstn = 0;

// Clock generation
always #5 clk = ~clk;

// --------------------- AXI-Lite Master Interface ---------------------
reg [4:0] S_AXI_AWADDR;
reg [2:0] S_AXI_AWPROT = 0;
reg       S_AXI_AWVALID = 0;
wire      S_AXI_AWREADY;
reg [31:0] S_AXI_WDATA;
reg [3:0]  S_AXI_WSTRB = 4'hF;
reg        S_AXI_WVALID = 0;
wire       S_AXI_WREADY;
wire [1:0] S_AXI_BRESP;
wire       S_AXI_BVALID;
reg        S_AXI_BREADY = 1;
reg [4:0]  S_AXI_ARADDR;
reg [2:0]  S_AXI_ARPROT = 0;
reg        S_AXI_ARVALID = 0;
wire       S_AXI_ARREADY;
wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;
wire        S_AXI_RVALID;
reg         S_AXI_RREADY = 1;

// --------------------- AXI Master Interface ---------------------
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

// --------------------- Memory model ---------------------
reg [31:0] mem [0:255];

// --------------------- DUT Instance ---------------------
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

// --------------------- AXI-Lite Write Task ---------------------
task axi_lite_write(input [4:0] addr, input [31:0] data);
begin
    @(posedge clk);
    S_AXI_AWADDR  <= addr << 2;
    S_AXI_WDATA   <= data;
    S_AXI_AWVALID <= 1;
    S_AXI_WVALID  <= 1;
    wait (S_AXI_AWREADY && S_AXI_WREADY);
    @(posedge clk);
    S_AXI_AWVALID <= 0;
    S_AXI_WVALID  <= 0;
end
endtask

// --------------------- AXI Memory Read/Write Simulation ---------------------
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

// --------------------- Verification Task ---------------------
task verify_dot_product(input integer baseA, input integer baseB, input integer out_addr, input integer len);
    integer i;
    integer result;
begin
    result = 0;
    for (i = 0; i < len; i = i + 1) begin
        result = result + $signed(mem[baseA + 2*i]) * $signed(mem[baseB + 2*i]);
    end
    $display("Result in memory[%0d] = %0d", out_addr, $signed(mem[out_addr]));
    if ($signed(mem[out_addr]) !== result) begin
        $display("Dot product incorrect! Expect: %0d", result);
        $fatal;
    end else begin
        $display("Dot product correct!");
    end
end
endtask

// --------------------- Main Test Sequence ---------------------
initial begin
    $display("Starting testbench...");
    rstn = 0;
    repeat(5) @(posedge clk);
    rstn = 1;

    // ==== Test 1: Single Mode ====
    mem[16] = 3;
    mem[17] = 4;
    mem[18] = -5;
    mem[19] = 6;
    mem[20] = 7;
    mem[21] = -8;

    axi_lite_write(5'd1, 16*4); // A base
    axi_lite_write(5'd2, 17*4); // B base
    axi_lite_write(5'd3, 3);    // length
    axi_lite_write(5'd4, 32*4); // output
    axi_lite_write(5'd0, 32'h1);// control: start, single

    #500;
    verify_dot_product(16, 17, 32, 3);

    // Clear Control Signal
    axi_lite_write(5'd0, 32'h0);// control: start, single

    // ==== Test 2: Burst Mode ====
    mem[40] = 1;
    mem[41] = -2;
    mem[42] = 3;
    mem[43] = 4;
    mem[44] = -5;
    mem[45] = 6;

    axi_lite_write(5'd1, 40*4); // A base
    axi_lite_write(5'd2, 41*4); // B base
    axi_lite_write(5'd3, 3);    // length
    axi_lite_write(5'd4, 48*4); // output
    axi_lite_write(5'd0, 32'h3);// control: start + burst

    #400;
    verify_dot_product(40, 41, 48, 3);

    $display("All tests passed!");
    $finish;
end

endmodule
