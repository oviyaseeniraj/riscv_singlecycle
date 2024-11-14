// ucsbece154a_controller.v
// All Rights Reserved
// Copyright (c) 2023 UCSB ECE
// Distribution Prohibited

module ucsbece154a_controller (
    input         [6:0] op_i, 
    input         [2:0] funct3_i,
    input               funct7b5_i,
    input               zero_i,
    output wire         RegWrite_o,
    output wire         ALUSrc_o,
    output wire         MemWrite_o,
    output wire   [1:0] ResultSrc_o,
    output reg    [2:0] ALUControl_o,
    output wire         PCSrc_o,
    output wire   [2:0] ImmSrc_o
);

`include "ucsbece154a_defines.vh"

// Generate PCSrc by combining branch and jump logic
wire branch, jump;
assign PCSrc_o = (branch & zero_i) | jump;

// Main decoder
reg [11:0] controls;
wire [1:0] ALUOp;

assign {RegWrite_o, ImmSrc_o, ALUSrc_o, MemWrite_o, ResultSrc_o, branch, ALUOp, jump} = controls;

always @ * begin
    case (op_i)
        instr_lw_op:       controls = 12'b1_000_1_0_01_0_00_0; // Load Word
        instr_sw_op:       controls = 12'b0_001_1_1_xx_0_00_0; // Store Word
        instr_Rtype_op:    controls = 12'b1_xxx_0_0_00_0_10_0; // R-type ALU Operations
        instr_beq_op:      controls = 12'b0_010_0_0_xx_1_01_0; // Branch Equal (set ImmSrc to 010)
        instr_ItypeALU_op: controls = 12'b1_000_1_0_00_0_10_0; // I-type ALU Operations
        instr_jal_op:      controls = 12'b1_011_x_0_10_x_xx_1;  // JAL
        instr_lui_op:      controls = 12'b1_100_1_0_11_0_10_0; // LUI
        default:           controls = 12'b0_000_0_0_00_0_00_0; // Default case for unsupported opcodes
    endcase
end

// ALU Control Logic
wire RtypeSub;
assign RtypeSub = funct7b5_i & op_i[5];

always @ * begin
    case (ALUOp)
        ALUop_mem:     ALUControl_o = ALUcontrol_add;   // lw/sw use add
        ALUop_beq:     ALUControl_o = ALUcontrol_sub;   // Branch compares using subtraction
        ALUop_other:   // R-type and I-type ALU Operations
            case (funct3_i)
                instr_addsub_funct3: ALUControl_o = (RtypeSub) ? ALUcontrol_sub : ALUcontrol_add;
                instr_slt_funct3:    ALUControl_o = ALUcontrol_slt;
                instr_or_funct3:     ALUControl_o = ALUcontrol_or;
                instr_and_funct3:    ALUControl_o = ALUcontrol_and;
                default:             ALUControl_o = ALUcontrol_add; // Default to add
            endcase
        default: ALUControl_o = ALUcontrol_add; // Default case to avoid warnings
    endcase
end

endmodule
