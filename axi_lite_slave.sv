`timescale 1 ns / 1 ps

module AXI_APEX_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,// Read address (issued by master, acceped by Slave)
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg0,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg1,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg2,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg3,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg4,
    output wire [C_S_AXI_DATA_WIDTH-1:0] o_slv_reg5

);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
reg         axi_awready;
reg         axi_wready;
reg [1 : 0] axi_bresp;
reg         axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
reg         axi_arready;
reg [1 : 0] axi_rresp;
reg         axi_rvalid;

assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY  = axi_wready;
assign S_AXI_BRESP   = axi_bresp;
assign S_AXI_BVALID  = axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RRESP   = axi_rresp;
assign S_AXI_RVALID  = axi_rvalid;

//======================================================================
// localparam 
//======================================================================
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 2;

//======================================================================
// 6 Registers
//======================================================================
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // Control
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // A base
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  // B base
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // Length
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;  // Output
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;  // Status

integer byte_index;

//======================================================================
// Write address and data channel: 1. AWVALID, 2. WVALID, 3. BREADY
//======================================================================
reg [1:0] state_write;
localparam [1:0] Idle=2'b00, Waddr=2'b10, Wdata=2'b11; // 与官方相同

always @(posedge S_AXI_ACLK) begin
  if (!S_AXI_ARESETN) begin
    axi_awready <= 0;   
    axi_wready  <= 0;   
    axi_bvalid  <= 0;   
    axi_bresp   <= 0;   
    axi_awaddr  <= 0;   
    state_write <= Idle;
  end else begin
    case(state_write)
      Idle: begin
        if(S_AXI_ARESETN == 1) begin
          axi_awready <= 1'b1;
          axi_wready  <= 1'b1;
          state_write <= Waddr;
        end
      end
      Waddr: begin
        if (S_AXI_AWVALID && S_AXI_AWREADY) begin
          axi_awaddr <= S_AXI_AWADDR;
          if(S_AXI_WVALID) begin
            axi_awready <= 1'b1;
            state_write <= Waddr;
            axi_bvalid  <= 1'b1;
          end else begin
            axi_awready <= 1'b0;
            state_write <= Wdata;
            if (S_AXI_BREADY && axi_bvalid)
              axi_bvalid <= 1'b0;
          end
        end else begin
          if (S_AXI_BREADY && axi_bvalid)
            axi_bvalid <= 1'b0;
        end
      end
      Wdata: begin
        if (S_AXI_WVALID) begin
          state_write <= Waddr;
          axi_bvalid  <= 1'b1;
          axi_awready <= 1'b1;
        end else begin
          if (S_AXI_BREADY && axi_bvalid)
            axi_bvalid <= 1'b0;
        end
      end
    endcase
  end
end

//======================================================================
// Write data channel: 1. WVALID, 2. BREADY
//======================================================================
always @(posedge S_AXI_ACLK) begin
  if (!S_AXI_ARESETN) begin
    slv_reg0 <= 0;
    slv_reg1 <= 0;
    slv_reg2 <= 0;
    slv_reg3 <= 0;
    slv_reg4 <= 0;
    slv_reg5 <= 0;
  end else begin
    if(S_AXI_WVALID) begin
      case( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] 
                            : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] )
        3'h0: begin
          // slv_reg0 => Control
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg0[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        3'h1: begin
          // slv_reg1 => Vector A base
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg1[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        3'h2: begin
          // slv_reg2 => Vector B base
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg2[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        3'h3: begin
          // slv_reg3 => Vector length
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg3[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        3'h4: begin
          // slv_reg4 => Output address
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg4[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        3'h5: begin
          // slv_reg5 => Status
          for(byte_index=0; byte_index< (C_S_AXI_DATA_WIDTH/8); byte_index=byte_index+1) begin
            if(S_AXI_WSTRB[byte_index] == 1) begin
              slv_reg5[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            end
          end
        end
        default: begin
        end
      endcase
    end
  end
end

//======================================================================
// Read address and data channel: 1. ARVALID, 2. RREADY
//======================================================================
reg [1:0] state_read;
localparam [1:0] Idle_r=2'b00, Raddr=2'b10, Rdata=2'b11;

always @(posedge S_AXI_ACLK) begin
  if (!S_AXI_ARESETN) begin
    axi_arready <= 1'b0;
    axi_rvalid  <= 1'b0;
    axi_rresp   <= 2'b00;
    state_read  <= Idle_r;
  end else begin
    case(state_read)
      Idle_r: begin
        if(S_AXI_ARESETN == 1) begin
          state_read  <= Raddr;
          axi_arready <= 1'b1;
        end
      end
      Raddr: begin
        if (S_AXI_ARVALID && S_AXI_ARREADY) begin
          state_read  <= Rdata;
          axi_araddr  <= S_AXI_ARADDR;
          axi_rvalid  <= 1'b1;
          axi_arready <= 1'b0;
        end
      end
      Rdata: begin
        if (S_AXI_RVALID && S_AXI_RREADY) begin
          axi_rvalid  <= 1'b0;
          axi_arready <= 1'b1;
          state_read  <= Raddr;
        end
      end
    endcase
  end
end

//======================================================================
// Regitser Mappingg
//======================================================================
assign S_AXI_RDATA = 
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h0) ? slv_reg0 :
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h1) ? slv_reg1 :
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h2) ? slv_reg2 :
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h3) ? slv_reg3 :
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h4) ? slv_reg4 :
  (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] == 3'h5) ? slv_reg5 :
  32'hDEADBEEF;

assign o_slv_reg0 = slv_reg0;
assign o_slv_reg1 = slv_reg1;
assign o_slv_reg2 = slv_reg2;
assign o_slv_reg3 = slv_reg3;
assign o_slv_reg4 = slv_reg4;
assign o_slv_reg5 = slv_reg5;

endmodule
