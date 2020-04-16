`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Controller Decoder
// Tool Versions: Vivado 2017.4.1
// Description: Controller Decoder Module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  对指令进行译码，将其翻译成控制信号，传输给各个部件
// 输入
    // Inst              待译码指令
// 输出
    // jal               jal跳转指令
    // jalr              jalr跳转指令
    // op2_src           ALU的第二个操作数来源。为1时，op2选择imm，为0时，op2选择reg2
    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_npc          写回寄存器的值的来源（PC或者ALU计算结果）, load_npc == 1时选择PC
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果），wb_select == 1时选择cache内容
    // load_type         load类型
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache
    // imm_type          指令中立即数类型
    // alu_src1          alu操作数1来源，alu_src1 == 1表示来自reg1，alu_src1 == 0表示来自PC
    // alu_src2          alu操作数2来源，alu_src2 == 2’b00表示来自reg2，alu_src2 == 2'b01表示来自reg2地址(shamt)，alu_src2 == 2'b10表示来自立即数
// 实验要求
    // 补全模块


`include "Parameters.v"   
module ControllerDecoder(
    input wire [31:0] inst,
    output wire jal,
    output wire jalr,
    output wire op2_src,
    output reg [3:0] ALU_func,
    output reg [2:0] br_type,
    output wire load_npc,
    output wire wb_select,
    output reg [2:0] load_type,
    output reg [1:0] src_reg_en,
    output reg reg_write_en,
    output reg [3:0] cache_write_en,
    output wire alu_src1,
    output wire [1:0] alu_src2,
    output reg [2:0] imm_type
    );
    // initial begin
    //     {jal,jalr,op2_src,load_npc,wb_select,alu_src1,alu_src2}=8'b00000000;
    // end
    // TODO: Complete this module
    assign jal=(inst[6:0]==7'b1101111)?1'b1:1'b0;
    assign jalr=(inst[6:0]==7'b1100111)?1'b1:1'b0;
    // 只有R类指令op2_src为0，选择reg2
    assign op2_src=(inst[6:0]==7'b0110011)?1'b0:1'b1;
    // 只有jal和jalr指令需要选择PC+4的内容作为Result最终写到reg里
    assign load_npc=({inst[6:4],inst[2:0]}==6'b110111)?1'b1:1'b0;
    // 只有load指令需要把data cache里的内容写回reg里
    assign wb_select=(inst[6:0]==7'b0000011)?1'b1:1'b0;
    // 只有auipc指令需要让src1是PCE-4，jal和branch不需要因为有branch adder
    assign alu_src1=(inst[6:0]==7'b0010111)?1'b0:1'b1;
    // 如果是R型的指令，alu_src2为00；如果是移位指令，位01；如果是立即数指令、csr、B指令，alu_src=10
    assign alu_src2=(inst[6:0]==7'b0110011)?2'b00:
                                            (({inst[13:12],inst[6:0]}==9'b010010011)?2'b01:2'b10);

    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_type         load类型,非load命令为NOREGWRITE
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache Datacache已经实现为非对齐写入
    // imm_type          指令中立即数类型
    always@(*)
    begin
        case (inst[6:0])
            7'b0110111: begin//LUI
                ALU_func=`LUI;
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b00;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`UTYPE;
            end
            7'b0010111: begin//AUIPC
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b00;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`UTYPE;
            end
            7'b0010011: begin//立即数ALU指令
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b10;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`ITYPE;
                case (inst[14:12])
                    3'b000:begin
                        ALU_func=`ADD;
                    end
                    3'b010:begin
                        ALU_func=`SLT;
                    end
                    3'b011:begin
                        ALU_func=`SLTU;
                    end
                    3'b100:begin
                        ALU_func=`XOR;
                    end
                    3'b110:begin
                        ALU_func=`OR;
                    end
                    3'b111:begin
                        ALU_func=`AND;
                    end
                    3'b001:begin
                        ALU_func=`SLL;
                    end
                    3'b101:begin
                        if(inst[30]==1)
                            ALU_func=`SRA;
                        else
                            ALU_func=`SRL;
                    end
                    default:ALU_func=`ADD;
                endcase
            end
            7'b0110011: begin//寄存器ALU指令
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b11;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`RTYPE;
                case (inst[14:12])
                    3'b000:begin
                        if(inst[30]==1)
                            ALU_func=`SUB;
                        else
                            ALU_func=`ADD;
                    end
                    3'b010:begin
                        ALU_func=`SLT;
                    end
                    3'b011:begin
                        ALU_func=`SLTU;
                    end
                    3'b100:begin
                        ALU_func=`XOR;
                    end
                    3'b110:begin
                        ALU_func=`OR;
                    end
                    3'b111:begin
                        ALU_func=`AND;
                    end
                    3'b001:begin
                        ALU_func=`SLL;
                    end
                    3'b101:begin
                        if(inst[30]==1)
                            ALU_func=`SRA;
                        else
                            ALU_func=`SRL;
                    end
                    default:ALU_func=`ADD;
                endcase        
            end
            7'b1101111: begin//JAL 在BR adder计算有效地址
            // alu_src1 = 0; alu_src2 = 10(立即数)
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b00;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`JTYPE;
            end 
            7'b1100111: begin//JALR 在ALU计算有效地址
                // alu_src1 = 0(reg1); alu_src2 = 10(立即数)
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                load_type=`LW;
                src_reg_en=2'b10;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`ITYPE;
            end
            7'b1100011: begin//有条件跳转指令
                ALU_func=`ADD;
                load_type=`NOREGWRITE;
                src_reg_en=2'b11;
                reg_write_en=1'b0;
                cache_write_en=4'b0000;
                imm_type=`BTYPE;   
                case (inst[14:12])
                    3'b000:begin
                        br_type=`BEQ;
                    end
                    3'b001:begin
                        br_type=`BNE;
                    end
                    3'b100:begin
                        br_type=`BLT;
                    end
                    3'b101:begin
                        br_type=`BGE;
                    end
                    3'b110:begin
                        br_type=`BLTU;
                    end
                    3'b111:begin
                        br_type=`BGEU;
                    end
                    default:br_type=`NOBRANCH;
                endcase     
            end
            7'b0000011: begin//Load指令
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                src_reg_en=2'b10;
                reg_write_en=1'b1;
                cache_write_en=4'b0000;
                imm_type=`ITYPE;
                case (inst[14:12])
                    3'b000:begin
                        load_type=`LB;
                    end
                    3'b001:begin
                        load_type=`LH;
                    end
                    3'b010:begin
                        load_type=`LW;
                    end
                    3'b100:begin
                        load_type=`LBU;
                    end
                    3'b101:begin
                        load_type=`LHU;
                    end
                    default:load_type=`NOREGWRITE;
                endcase
            end
            7'b0100011: begin//Store指令
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                load_type=`NOREGWRITE;
                src_reg_en=2'b11;
                reg_write_en=1'b0;
                imm_type=`STYPE;  
                case (inst[14:12])
                    3'b000:begin
                        cache_write_en=4'b0001;
                    end
                    3'b001:begin
                        cache_write_en=4'b0011;
                    end
                    3'b010:begin
                        cache_write_en=4'b1111;
                    end
                    default:cache_write_en=4'b0000; 
                endcase      
            end
            default: begin
                ALU_func=`ADD;
                br_type=`NOBRANCH;
                load_type=`NOREGWRITE;
                src_reg_en=2'b00;
                reg_write_en=1'b0;
                cache_write_en=4'b0000;
                imm_type=`RTYPE;
            end
        endcase
    end
endmodule
