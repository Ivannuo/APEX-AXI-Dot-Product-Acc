`timescale 1ns / 1ps

//AXI Master Module
module axi_adapter (
    input   wire            clk                ,
    input   wire            resetn             ,
    input   wire            read_req           ,
    input   wire    [31:0]  read_addr          ,
    //output  wire    [31:0]  read_data          ,
    output  reg             read_data_valid    ,
    input   wire            write_req          ,
    input   wire    [31:0]  write_addr         ,
    input   wire    [31:0]  write_data         ,
    output  reg             write_done         ,
    output  wire    [31:0]  M_AXI_ARADDR       ,
    output  reg             M_AXI_ARVALID      ,
    input   wire            M_AXI_ARREADY      ,
    input   wire    [31:0]  M_AXI_RDATA        ,
    input   wire            M_AXI_RVALID       ,
    output  reg             M_AXI_RREADY       ,
    output  reg     [31:0]  M_AXI_AWADDR       ,
    output  reg             M_AXI_AWVALID      ,
    input   wire            M_AXI_AWREADY      ,
    output  reg     [31:0]  M_AXI_WDATA        ,
    output  reg     [3:0]   M_AXI_WSTRB        ,
    output  reg             M_AXI_WVALID       ,
    input   wire            M_AXI_WREADY       ,
    input   wire            M_AXI_BVALID       ,
    output  reg             M_AXI_BREADY
);

reg [2:0] state;
localparam IDLE=0, READ=1, READ_WAIT=2, WRITE=3, WRITE_WAIT=4;

assign M_AXI_ARADDR = read_addr;
//assign read_data = M_AXI_RDATA;

always @(posedge clk) begin
    if (!resetn) begin
        state <= IDLE;
        M_AXI_ARVALID <=    0;
        M_AXI_RREADY <=     0;
        M_AXI_AWVALID <=    0;
        M_AXI_WVALID <=     0;
        M_AXI_BREADY <=     0;
        read_data_valid <=  0;
        write_done <=       0;
    end else begin
        case(state)
            IDLE: begin
                read_data_valid <= 0;
                write_done <= 0;
                M_AXI_RREADY <= 0;
                if (read_req) begin
                    M_AXI_ARVALID <= 1;
                    state <= READ;
                end else if (write_req) begin
                    M_AXI_AWADDR <= write_addr;
                    M_AXI_AWVALID <= 1;
                    M_AXI_WDATA <= write_data;
                    M_AXI_WSTRB <= 4'hF;
                    M_AXI_WVALID <= 1;
                    state <= WRITE;
                end
            end
            READ: begin
                if (M_AXI_ARREADY) begin
                    M_AXI_ARVALID <= 0;
                    M_AXI_RREADY <= 1;
                    state <= READ_WAIT;
                end
            end
            READ_WAIT: begin
                if (M_AXI_RVALID) begin
                    M_AXI_ARVALID <= 0;
                    read_data_valid <= 1;
                    M_AXI_RREADY <= 0;
                    state <= IDLE;
                end
            end
            WRITE: begin
                if (M_AXI_AWREADY && M_AXI_WREADY) begin
                    M_AXI_AWVALID <= 0;
                    M_AXI_WVALID <= 0;
                    M_AXI_BREADY <= 1;
                    state <= WRITE_WAIT;
                end
            end
            WRITE_WAIT: begin
                if (M_AXI_BVALID) begin
                    M_AXI_BREADY <= 0;
                    write_done <= 1;
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule