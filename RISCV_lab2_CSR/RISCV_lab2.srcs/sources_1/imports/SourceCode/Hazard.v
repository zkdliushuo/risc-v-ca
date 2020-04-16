`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Hazard Module
// Tool Versions: Vivado 2017.4.1
// Description: Hazard Module is used to control flush, bubble and bypass
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  识别流水线中的数据冲突，控制数据转发，和flush、bubble信号
// 输入
    // rst               CPU的rst信号
    // reg1_srcD         ID阶段的源reg1地址
    // reg2_srcD         ID阶段的源reg2地址
    // reg1_srcE         EX阶段的源reg1地址
    // reg2_srcE         EX阶段的源reg2地址
    // reg_dstE          EX阶段的目的reg地址
    // reg_dstM          MEM阶段的目的reg地址
    // reg_dstW          WB阶段的目的reg地址
    // br                是否branch
    // jalr              是否jalr
    // jal               是否jal
    // src_reg_en        指令中的源reg1和源reg2地址是否有效
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果）
    // reg_write_en_MEM  MEM阶段的寄存器写使能信号
    // reg_write_en_WB   WB阶段的寄存器写使能信号
    // alu_src1          ALU操作数1来源：0表示来自reg1，1表示来自PC
    // alu_src2          ALU操作数2来源：2’b00表示来自reg2，2'b01表示来自reg2地址，2'b10表示来自立即数
// 输出
    // flushF            IF阶段的flush信号
    // bubbleF           IF阶段的bubble信号
    // flushD            ID阶段的flush信号
    // bubbleD           ID阶段的bubble信号
    // flushE            EX阶段的flush信号
    // bubbleE           EX阶段的bubble信号
    // flushM            MEM阶段的flush信号
    // bubbleM           MEM阶段的bubble信号
    // flushW            WB阶段的flush信号
    // bubbleW           WB阶段的bubble信号
    // op1_sel           ALU的操作数1来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自PC，2'b11表示来自reg1
    // op2_sel           ALU的操作数2来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自reg2地址，2'b11表示来自reg2或立即数
    // reg2_sel          reg2的来源
// 实验要求
    // 补全模块


module HarzardUnit(
    input wire rst,
    input wire [4:0] reg1_srcD, reg2_srcD, reg1_srcE, reg2_srcE, reg_dstE, reg_dstM, reg_dstW,
    // 除wb_select外没标注阶段名字的都是EX阶段的
    input wire br, jalr, jal,
    input wire [1:0] src_reg_en,
    input wire wb_select,
    input wire reg_write_en_MEM,
    input wire reg_write_en_WB,
    input wire alu_src1,
    input wire [1:0] alu_src2,
    input wire CSR_op1_src,
    output reg flushF, bubbleF, flushD, bubbleD, flushE, bubbleE, flushM, bubbleM, flushW, bubbleW,
    output reg [1:0] op1_sel, op2_sel, reg2_sel, CSR_sel
    );

    // TODO: Complete this module
    // Bubble & Flush
    always@(*)
    begin
        if (rst) begin
            {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW}<=5'b00000;
            {flushF, flushD, flushE, flushM, flushW}<=5'b11111;
        end 
        else begin
            if (br || jalr) 
            begin //br jalr控制相关
                {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW}<=5'b00000;
                {flushF, flushD, flushE, flushM, flushW}<=5'b01100;
            end            
            else if ((src_reg_en[0] && reg2_srcE==reg_dstM && wb_select) || (src_reg_en[1] && reg1_srcE==reg_dstM && wb_select) ) 
            begin //Load冲突 F\D\E stall,M flush
                {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW}<=5'b11100;
                {flushF, flushD, flushE, flushM, flushW}<=5'b00010;
            end
            else if (jal) begin //jal 控制相关
                {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW}<=5'b00000;
                {flushF, flushD, flushE, flushM, flushW}<=5'b01000;
            end
            else begin //无相关
                {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW}<=5'b00000;
                {flushF, flushD, flushE, flushM, flushW}<=5'b00000;
            end
        end             
    end
    // forward Op1 & Op2 & Reg2
    // Op1_sel
    always@(*)
    begin
        // 如果EX用reg1,reg1和mem阶段dst相同且不为零号，mem指令不是load指令，mem指令需要写回寄存器
        // 就选择AluOut
        if (src_reg_en[1] && reg1_srcE==reg_dstM && reg1_srcE!=0  && !wb_select && reg_write_en_MEM ) 
            op1_sel=2'b00;
        // 类似
        else if (src_reg_en[1] && reg1_srcE==reg_dstW && reg1_srcE!=0 && reg_write_en_WB) 
            op1_sel=2'b01;
        else 
            // 为了方便我把alu_src1在controller里面取了个反 其实可以在这里直接取反的
            op1_sel={1'b1,alu_src1};
    end
    // Op2_sel
    always@(*)
    begin
        if (src_reg_en[0] && reg2_srcE==reg_dstM && reg2_srcE!=0  && !wb_select && reg_write_en_MEM && alu_src2==2'b00) 
            op2_sel=2'b00;
        // 类似
        else if (src_reg_en[0] && reg2_srcE==reg_dstW && reg2_srcE!=0 && reg_write_en_WB && alu_src2==2'b00) 
            op2_sel=2'b01;
        else 
            op2_sel={1'b1,~alu_src2[0]};
    end
    // Reg2_sel
    always@(*)
    begin
        if (src_reg_en[0] && reg2_srcE==reg_dstM && reg2_srcE!=0  && !wb_select && reg_write_en_MEM) 
            reg2_sel=2'b00;
        // 类似
        else if (src_reg_en[0] && reg2_srcE==reg_dstW && reg2_srcE!=0 && reg_write_en_WB) 
            reg2_sel=2'b01;
        else 
            reg2_sel=2'b10;
    end
    // CSR_sel
    always@(*)
    begin
        if (src_reg_en[1] && reg1_srcE==reg_dstM && reg1_srcE!=0  && !wb_select && reg_write_en_MEM) 
            CSR_sel=2'b00;
        // 类似
        else if (src_reg_en[1] && reg1_srcE==reg_dstW && reg1_srcE!=0 && reg_write_en_WB) 
            CSR_sel=2'b01;
        else 
            CSR_sel={1'b1,CSR_op1_src};
    end
endmodule