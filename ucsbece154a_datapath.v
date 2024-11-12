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



/// Your code here
// --- Program Counter ---
always @(posedge clk or posedge reset) begin
    if (reset) 
        pc_o <= 0;
    else if (PCSrc_i)
        pc_o <= pc_o + (sign_extended_imm); // Branch/Jump target
    else
        pc_o <= pc_o + 4; // Default PC increment
end

// --- Register File ---
wire [31:0] rd1, rd2;  // Read data
ucsbece154a_rf rf (
    .clk(clk),
    .a1_i(instr_i[19:15]),  // rs1
    .a2_i(instr_i[24:20]),  // rs2
    .a3_i(instr_i[11:7]),   // rd
    .rd1_o(rd1),
    .rd2_o(rd2),
    .we3_i(RegWrite_i),
    .wd3_i(writeback_data)
);

assign writedata_o = rd2;

// --- Immediate Generation ---
wire [31:0] sign_extended_imm;
assign sign_extended_imm = (ImmSrc_i == 0'b000) ? {{20{instr_i[11]}}, instr_i[11:0]} :  // Sign-extended immediate for I-type
                           (ImmSrc_i == 0'b001) ? {{20{instr_i[11]}}, instr_i[11:5], instr_i[4:0]} :  // S-type (sw)
                           (ImmSrc_i == 0'b010) ? {{21{instr_i[12]}}, instr_i[10:5], instr_i[4:1], instr_i[11]} :  // B-type 
                           (ImmSrc_i == 0'b011) ? {{13{instr_i[20]}}, instr_i[10:1], instr_i[11], instr_i[19:12]} :  // J-type (jal)
                           (ImmSrc_i == 0'b100) ? {{12{instr_i[31]}}, instr_i[31:12]} :  // U-type (lui)
                           32'b0;  // Default to zero if unrecognized

// --- ALU Input Selection ---
wire [31:0] alu_b;
assign alu_b = (ALUSrc_i) ? sign_extended_imm : rd2;  // ALU source controlled by ALUSrc

// --- ALU Integration ---
ucsbece154a_alu alu_inst (
    .a_i(rd1),
    .b_i(alu_b),
    .alucontrol_i(ALUControl_i),
    .result_o(aluresult_o),
    .zero_o(zero_o)  // Use ALU's zero flag for branch decisions
);

// --- Result Selection ---
wire [31:0] writeback_data;
assign writeback_data = (ResultSrc_i == 2'b00) ? aluresult_o :  // ALU result
                        (ResultSrc_i == 2'b01) ? readdata_i :   // Memory read data
                        (ResultSrc_i == 2'b10) ? pc_o + sign_extended_imm :  // Immediate (for LUI)
                        32'b0;  // Default case to zero

endmodule
// Use name "rf" for a register file module so testbench file work properly (or modify testbench file) 

