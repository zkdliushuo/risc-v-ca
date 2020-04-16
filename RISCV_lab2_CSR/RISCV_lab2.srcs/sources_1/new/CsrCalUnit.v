`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/16 21:26:50
// Design Name: 
// Module Name: CsrCalUnit
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


module CsrCalUnit(
    input wire [31:0] CSR_EX_op1,csr_rdata,
    input wire [1:0] CSR_func,
    output reg [31:0] CSR_EX_out
    );

    always@(*) begin
        case (CSR_func)
            // csrrw rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=x[rs1]; x[rd]=t
            2'b01 : CSR_EX_out = CSR_EX_op1;
            // csrrs rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=t|x[rs1]; x[rd]=t
            2'b10 : CSR_EX_out = csr_rdata | CSR_EX_op1;
            // csrrc rd,csr,rs1 t=CSRs[csr]; CSRs[csr]=t&~x[rs1]; x[rd]=t
            2'b11 : CSR_EX_out = csr_rdata & ~CSR_EX_op1;
            default: CSR_EX_out = csr_rdata;
        endcase // (func3)
    end

endmodule
