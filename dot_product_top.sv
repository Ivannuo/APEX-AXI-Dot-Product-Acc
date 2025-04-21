`timescale 1 ns / 1 ps
`timescale 1 ns / 1 ps

module dot_product_top #(
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32
)(
    // AXI-Lite
    input  wire                                 S_AXI_ACLK      ,
    input  wire                                 S_AXI_ARESETN   ,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]      S_AXI_AWADDR    ,
    input  wire [2 : 0]                         S_AXI_AWPROT    ,
    input  wire                                 S_AXI_AWVALID   ,
    output wire                                 S_AXI_AWREADY   ,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]      S_AXI_WDATA     ,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]  S_AXI_WSTRB     ,
    input  wire                                 S_AXI_WVALID    ,
    output wire                                 S_AXI_WREADY    ,
    output wire [1 : 0]                         S_AXI_BRESP     ,
    output wire                                 S_AXI_BVALID    ,
    input  wire                                 S_AXI_BREADY    ,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]      S_AXI_ARADDR    ,
    input  wire [2 : 0]                         S_AXI_ARPROT    ,
    input  wire                                 S_AXI_ARVALID   ,
    output wire                                 S_AXI_ARREADY   ,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]      S_AXI_RDATA     ,
    output wire [1 : 0]                         S_AXI_RRESP     ,
    output wire                                 S_AXI_RVALID    ,
    input  wire                                 S_AXI_RREADY    ,

    // AXI Master
    input  wire                                 M_AXI_ACLK      ,
    input  wire                                 M_AXI_ARESETN   ,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR    ,
    output wire                                 M_AXI_AWVALID   ,
    input  wire                                 M_AXI_AWREADY   ,
    output wire [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA     ,
    output wire [(C_M_AXI_DATA_WIDTH/8)-1 : 0]  M_AXI_WSTRB     ,
    output wire                                 M_AXI_WVALID    ,
    input  wire                                 M_AXI_WREADY    ,
    input  wire [1 : 0]                         M_AXI_BRESP     ,
    input  wire                                 M_AXI_BVALID    ,
    output wire                                 M_AXI_BREADY    ,

    output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR    ,
    output wire                                 M_AXI_ARVALID   ,
    input  wire                                 M_AXI_ARREADY   ,
    input  wire [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_RDATA     ,
    input  wire                                 M_AXI_RVALID    ,
    output wire                                 M_AXI_RREADY    ,
    input  wire [1 : 0]                         M_AXI_RRESP
);

// --- internal wires from slave ---
wire [31:0] slv_reg0_ctrl, slv_reg1_a, slv_reg2_b, slv_reg3_len, slv_reg4_out, slv_reg5_status;

// --- simplified interface between FSM and adapter ---
wire read_req, read_data_valid, write_req, write_done;
wire burst_mode = slv_reg0_ctrl[1];
wire [31:0] read_addr, M_AXI_RDATA, write_addr, write_data;

// === Instantiate AXI-Lite Slave ===
AXI_APEX_slave_lite_v1_0_S00_AXI axi_slave_inst (
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
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
    .o_slv_reg0(slv_reg0_ctrl),
    .o_slv_reg1(slv_reg1_a),
    .o_slv_reg2(slv_reg2_b),
    .o_slv_reg3(slv_reg3_len),
    .o_slv_reg4(slv_reg4_out),
    .o_slv_reg5(slv_reg5_status)
);

// === Instantiate FSM ===
dot_product_fsm fsm_inst (
    .clk(M_AXI_ACLK),
    .resetn(M_AXI_ARESETN),
    .start_in(slv_reg0_ctrl[0]),
    .burst_mode(burst_mode),
    .addr_a_in(slv_reg1_a),
    .addr_b_in(slv_reg2_b),
    .length_in(slv_reg3_len),
    .addr_out_in(slv_reg4_out),
    .status_out(slv_reg5_status),
    .read_req(read_req),
    .read_addr(read_addr),
    .read_data(M_AXI_RDATA),
    .read_data_valid(read_data_valid),
    .write_req(write_req),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_done(write_done)
);

// === Instantiate Adapter ===
axi_adapter adapter_inst (
    .clk(M_AXI_ACLK),
    .resetn(M_AXI_ARESETN),
    .read_req(read_req),
    .read_addr(read_addr),
    //.read_data(read_data),
    .read_data_valid(read_data_valid),
    .write_req(write_req),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_done(write_done),
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .M_AXI_RDATA(M_AXI_RDATA),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_RREADY(M_AXI_RREADY),
    .M_AXI_AWADDR(M_AXI_AWADDR),
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_AWREADY(M_AXI_AWREADY),
    .M_AXI_WDATA(M_AXI_WDATA),
    .M_AXI_WSTRB(M_AXI_WSTRB),
    .M_AXI_WVALID(M_AXI_WVALID),
    .M_AXI_WREADY(M_AXI_WREADY),
    .M_AXI_BVALID(M_AXI_BVALID),
    .M_AXI_BREADY(M_AXI_BREADY)
);

endmodule
