`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/16 19:37:02
// Design Name: 
// Module Name: CsrFile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CsrFile(
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire read_en,
    input wire [11:0] addr1,
    input wire [31:0] wb_data,
    output wire [31:0] read_data,
    output reg [31:0] out_to_WB
    );

    reg [31 : 0] csrs[4095 : 0];
    integer i;

    // init register file
    initial
    begin
        out_to_WB <= 32'b0;
        for(i = 0; i < 4095; i = i + 1) 
            csrs[i][31:0] <= 32'b0;
    end

    // write in clk negedge, reset in rst posedge
    // if write register in clk posedge,
    // new wb data also write in clk posedge,
    // so old wb data will be written to register
    always@(negedge clk or posedge rst) 
    begin 
        if (rst)
            for (i = 1; i < 32; i = i + 1) 
                csrs[i][31:0] <= 32'b0;
        else if(write_en)
            csrs[addr1] <= wb_data;   
    end
    always@(negedge clk or posedge rst) 
    begin 
        if (rst) 
            out_to_WB <= 32'b0;
        else 
            out_to_WB <= read_data;   
    end

    // read data changes when address changes
    assign read_data = (read_en) ? csrs[addr1]:32'h00000000;
endmodule
