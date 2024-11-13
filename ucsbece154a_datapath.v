// ucsbece154a_datapath.v
// All Rights Reserved
// Copyright (c) 2023 UCSB ECE
// Distribution Prohibited

module ucsbece154a_datapath (
    input               clk, reset,
    input               RegWrite_i,
    input         [2:0] ImmSrc_i,
    input               ALUSrc_i,
    input               PCSrc_i,
    input         [1:0] ResultSrc_i,
    input         [2:0] ALUControl_i,
    output              zero_o,
    output reg   [31:0] pc_o,
    input        [31:0] instr_i,
    output wire  [31:0] aluresult_o, writedata_o,
    input        [31:0] readdata_i
);

`include "ucsbece154a_defines.vh"

// Program Counter (PC)
always @(posedge clk or posedge reset) begin
    if (reset) 
        pc_o <= 0;
    else if (PCSrc_i)
        pc_o <= pc_o + sign_extended_imm; // Branch/Jump target
    else
        pc_o <= pc_o + 4; // Default PC increment
end

// Immediate Generation
wire [31:0] sign_extended_imm;
assign sign_extended_imm = (ImmSrc_i == imm_Itype) ? {{20{instr_i[31]}}, instr_i[31:20]} :
                           (ImmSrc_i == imm_Stype) ? {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]} :
                           (ImmSrc_i == imm_Btype) ? {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0} :
                           (ImmSrc_i == imm_Jtype) ? {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0} :
                           (ImmSrc_i == imm_Utype) ? {instr_i[31:12], 12'b0} : 32'b0;

// Register File
wire [31:0] rd1, rd2;
ucsbece154a_rf rf (
    .clk(clk),
    .a1_i(instr_i[19:15]),
    .a2_i(instr_i[24:20]),
    .a3_i(instr_i[11:7]),
    .rd1_o(rd1),
    .rd2_o(rd2),
    .we3_i(RegWrite_i),
    .wd3_i(result)
);

assign writedata_o = rd2;

// ALU Integration
wire [31:0] alu_b;
assign alu_b = (ALUSrc_i) ? sign_extended_imm : rd2;

ucsbece154a_alu alu_inst (
    .a_i(rd1),
    .b_i(alu_b),
    .alucontrol_i(ALUControl_i),
    .result_o(aluresult_o),
    .zero_o(zero_o)
);

// Data Memory
wire [31:0] readdata;
assign readdata = readdata_i;

// Result Selection MUX
wire [31:0] result;
assign result = (ResultSrc_i == ResultSrc_ALU) ? aluresult_o :
                (ResultSrc_i == ResultSrc_load) ? readdata :
                (ResultSrc_i == ResultSrc_jal) ? (pc_o + 4) :
                (ResultSrc_i == ResultSrc_lui) ? sign_extended_imm : 32'b0;

endmodule
