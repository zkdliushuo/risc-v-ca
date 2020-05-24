`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/07 20:15:32
// Design Name: 
// Module Name: cache_miss_count
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


module cache_miss_count(
    input wire clk,
    input wire rst,
    input wire miss,
    input wire cache_write,
    input wire cache_read,
    output reg [63:0] miss_count,
    output reg [63:0] cache_access_count
    );

    reg miss_old;
    reg cache_read_old,cache_write_old;

    always@(posedge clk or posedge rst) 
    begin 
        if (rst)
            cache_access_count<=0;
        else if(cache_read&&!cache_read_old || cache_write&&!cache_write_old) begin
            cache_access_count<=cache_access_count+1;
        end
    end
    always@(posedge clk or posedge rst) 
    begin 
        if (rst)
            cache_read_old<=0;
        else begin
            cache_read_old<=cache_read;
        end
    end
     always@(posedge clk or posedge rst) 
    begin 
        if (rst)
            cache_write_old<=0;
        else begin
            cache_write_old<=cache_write;
        end
    end
    

    always@(posedge clk or posedge rst) 
    begin 
        if (rst)
            miss_count<=0;
        else if(miss&&!miss_old) begin
            miss_count<=miss_count+1;
        end
    end
    always@(posedge clk or posedge rst) 
    begin 
        if (rst)
            miss_old<=0;
        else begin
            miss_old<=miss;
        end
    end
endmodule
