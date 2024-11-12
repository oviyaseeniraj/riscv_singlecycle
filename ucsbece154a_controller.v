// ucsbece154a_controller.v
// All Rights Reserved
// Copyright (c) 2023 UCSB ECE
// Distribution Prohibited


module ucsbece154a_controller (
    input         [6:0] op_i, 
    input         [2:0] funct3_i,
    input               funct7b5_i,
    input 	        zero_i,
    output wire          RegWrite_o,
    output wire          ALUSrc_o,
    output wire          MemWrite_o,
    output wire    [1:0] ResultSrc_o,
    output reg     [2:0] ALUControl_o,
    output wire          PCSrc_o,
    output wire    [2:0] ImmSrc_o
);


 `include "ucsbece154a_defines.vh"


// DONE: Generate properly PCSrc by replacing all `z` values with the correct values

 wire branch, jump;
 wire intermediatePCSrc = branch & zero_i;
 assign PCSrc_o = intermediatePCSrc | jump;


//  DONE: Implement main decoder 
//  • Replace all `z` values with the correct values
//  • Extend the code to implement jal and lui 

 reg [11:0] controls;
 wire [1:0] ALUOp;


 assign {RegWrite_o,	
	ImmSrc_o,
        ALUSrc_o,
        MemWrite_o,
        ResultSrc_o,
	branch, 
	ALUOp,
	jump} = controls;

 always @ * begin
   case (op_i)
	instr_lw_op:        controls = 12'b1_000_1_0_01_0_00_0;       
	instr_sw_op:        controls = 12'b0_001_1_1_xx_0_00_0;  
	instr_Rtype_op:     controls = 12'b1_xxx_0_0_00_0_10_0;   
	instr_beq_op:       controls = 12'b0_010_0_0_xx_1_01_0;   
	instr_ItypeALU_op:  controls = 12'b1_000_1_0_00_0_10_0;
    instr_jal_op:       controls = 12'b1_011_x_0_10_x_xx_1;
    instr_lui_op:       controls = 12'b1_100_1_0_00_0_10_0;  
	default: begin	    
                            controls = 12'bx_xxx_x_x_xx_x_xx_x;       
            `ifdef SIM
                $warning("Unsupported op given: %h", op_i);
            `else
            ;
            `endif
            
        end 
   endcase
 end

//  DONE: Implement ALU decoder by replacing all `z` values with the correct values

 wire RtypeSub;

 assign RtypeSub = funct7b5_i & op_i[5];

 always @ * begin
 case(ALUOp)
   ALUop_mem:                 ALUControl_o = 3'b000; // lw and sw are memory/stack operations
   ALUop_beq:                 ALUControl_o = 3'b001;
   ALUop_other:
       case(funct3_i)
           instr_addsub_funct3: 
                 if(RtypeSub) ALUControl_o = 3'b001;
                 else         ALUControl_o = 3'b000;
           instr_slt_funct3:  ALUControl_o = 3'b101;  
           instr_or_funct3:   ALUControl_o = 3'b011;
           instr_and_funct3:  ALUControl_o = 3'b010;  
           default: begin
                              ALUControl_o = 3'bxxx;
               `ifdef SIM
                   $warning("Unsupported funct3 given: %h", funct3_i);
               `else
                  ;
               `endif  
           end
       endcase
   default: 
      `ifdef SIM
          $warning("Unsupported ALUop given: %h", ALUOp);
      `else
          ;
      `endif   
  endcase
 end





endmodule

