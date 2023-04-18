`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2023 01:13:51 PM
// Design Name: 
// Module Name: control_unit
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

module isa_to_alu_opcode (
    input [7:0] isa_instr,
    output reg [3:0] alu_opcode
);

    // Extract the opcode from the ISA instruction
    wire [7:0] opcode_8bit = isa_instr[7:0];
    wire [3:0] opcode_4bit = isa_instr[7:4];
    wire [2:0] opcode_3bit = isa_instr[7:5];

    always @* begin
        case (opcode_8bit)
            8'b11110110: alu_opcode = 4'b0101; // SHL
            8'b11110111: alu_opcode = 4'b0110; // SHR
            8'b11111000: alu_opcode = 4'b0111; // SHL4
            8'b11111001: alu_opcode = 4'b1000; // ROL
            8'b11111010: alu_opcode = 4'b1001; // ROR
            8'b11111100: alu_opcode = 4'b1010; // DEC
            8'b11111110: alu_opcode = 4'b1011; // INV
            8'b11111101: alu_opcode = 4'b1100; // CLR

            default: begin
                case (opcode_4bit)
                    4'b1110: alu_opcode = 4'b0000; // ADDI

                    default: begin
                        case (opcode_3bit)
                            3'b010: alu_opcode = 4'b0000; // ADD
                            3'b011: alu_opcode = 4'b0001; // SUB
                            3'b100: alu_opcode = 4'b0010; // AND
                            3'b101: alu_opcode = 4'b0011; // OR
                            3'b110: alu_opcode = 4'b0100; // XOR

                            default: alu_opcode = 4'b0000; // Undefined or not an ALU operation
                        endcase
                    end
                endcase
            end
        endcase
    end

endmodule

module control_unit (
    input wire clk, // Clock input
    input wire rst, // Reset input
    input wire processor_enable, // Processor enable signal
    output reg processor_halted, // Processor halted signal
    input wire [7:0] instruction, // Input from the Instruction Register (IR)
    input wire ZF, // Zero Flag input, true when ACC is zero
    
    output reg PC_write_enable, // Enables writing to the PC
    output reg [1:0] PC_mux_select, // Selects the input for the PC multiplexer
    // 00: PC + 1 (FETCH cycle)
    // 01: ACC (JMP, JSR)
    // 10: PC - 3 (BEQ_BWD, BNE_BWD)
    // 11: PC + 2 (BEQ_FWD, BNE_FWD)
    
    output reg ACC_write_enable, // Enables writing to the ACC
    output reg [1:0] ACC_mux_select, // Selects the input for the ACC multiplexer
    // 00: ALU output
    // 01: Memory contents (LDA, LDAR)
    // 10: PC (JSR)
    
    output reg IR_load_enable, // Enables loading new instruction into IR from memory
    
    output wire [3:0] ALU_opcode, // Control signal specifying the ALU operation
    output reg ALU_inputB_mux_select, // Selects input B for the ALU multiplexer
    // 0: Memory contents (ADD, SUB, AND, OR, XOR)
    // 1: Immediate (ADDI)
    
    output reg Memory_write_enable, // Enables writing to memory (STA)
    output reg [1:0] Memory_address_mux_select, // Selects input for memory address multiplexer
    // 00: IR[4:0] (LDA, STA, ADD, SUB, AND, OR, XOR)
    // 01: ACC (LDAR)
    // 10: PC (Instruction fetching)
    
    // Scan chain signals
    input wire scan_enable, // Scan chain enable signal
    input wire scan_in, // Scan chain input
    output wire scan_out // Scan chain output
);



// Define state constants
  localparam STATE_RESET = 3'b000;
  localparam STATE_FETCH = 3'b001;
  localparam STATE_EXECUTE = 3'b010;
  localparam STATE_HALT = 3'b100;

  // Instantiate shift register for state storage (one-hot encoding)
  reg [2:0] state_in;
  wire [2:0] state_out;
  shift_register #(
    .WIDTH(3)
  ) state_register (
    .clk(clk),
    .rst(rst),
    .enable(processor_enable),
    .data_in(state_in),
    .data_out(state_out),
    .scan_enable(scan_enable),
    .scan_in(scan_in),
    .scan_out(scan_out)
  );

  // Combinational logic for state_in
  always @(*) begin
    // Default state: stay in the current state
    state_in = state_out;
    processor_halted = 0;

    // Only advance state if processor_enable is asserted
    if (processor_enable) begin
      case (state_out)
        STATE_RESET: begin
          // Move to STATE_FETCH when reset occurs
          if (!rst) begin
            state_in = STATE_FETCH;
          end
        end

        STATE_FETCH: begin
          // If the processor is halted, stay in the HALT state
          if (instruction == 8'b11111111) begin
            state_in = STATE_HALT;
          end
          // Otherwise, move to the EXECUTE state
          else begin
            state_in = STATE_EXECUTE;
          end
        end

        STATE_EXECUTE: begin
          // If the processor is halted, move to the HALT state
          if (instruction == 8'b11111111) begin
            state_in = STATE_HALT;
          end
          // Otherwise, move back to the FETCH state
          else begin
            state_in = STATE_FETCH;
          end
        end

        STATE_HALT: begin
        processor_halted = 1;
          // Stay in HALT state unless reset occurs
          if (rst) begin
            state_in = STATE_FETCH;
          end
        end

        default: begin
          // Default behavior (should never be reached in this implementation)
          state_in = STATE_FETCH;
        end
      endcase
    end
  end

  // Control signals go here
  // Instantiate ALU ISA decoder
    isa_to_alu_opcode isa_decoder (
        .isa_instr(instruction),
        .alu_opcode(ALU_opcode)
    );
  
  always @(*) begin
    // Default values
    PC_write_enable = 1'b0;
    PC_mux_select = 2'b00;
    if(processor_enable) begin
        case (state_out)
            STATE_FETCH: begin
                PC_write_enable = 1'b1;
                PC_mux_select = 2'b00;
            end
            STATE_EXECUTE: begin
                case (instruction[7:0])
                    8'b11110000: begin // JMP
                        PC_write_enable = 1'b1;
                        PC_mux_select = 2'b01;
                    end
                    8'b11110001: begin // JSR
                        PC_write_enable = 1'b1;
                        PC_mux_select = 2'b01;
                    end
                    8'b11110010: begin // BEQ_FWD
                        if (ZF) begin
                            PC_write_enable = 1'b1;
                            PC_mux_select = 2'b11;
                        end
                    end
                    8'b11110011: begin // BEQ_BWD
                        if (ZF) begin
                            PC_write_enable = 1'b1;
                            PC_mux_select = 2'b10;
                        end
                    end
                    8'b11110100: begin // BNE_FWD
                        if (!ZF) begin
                            PC_write_enable = 1'b1;
                            PC_mux_select = 2'b11;
                        end
                    end
                    8'b11110101: begin // BNE_BWD
                        if (!ZF) begin
                            PC_write_enable = 1'b1;
                            PC_mux_select = 2'b10;
                        end
                    end
                endcase
            end
        endcase
    end
end


always @(*) begin
  // Default values
  ACC_write_enable = 1'b0;
  ACC_mux_select = 2'b00;
  if(processor_enable) begin
      // Check if the current state is EXECUTE
      if (state_out == STATE_EXECUTE) begin
        // Immediate Data Manipulation Instructions
        if (instruction[7:4] == 4'b1110) begin // ADDI
          ACC_write_enable = 1'b1;
          ACC_mux_select = 2'b00; // ALU output
        end
    
        // Instructions with Variable-Data Operands
        case (instruction[7:5])
          3'b000: begin // LDA
            ACC_write_enable = 1'b1;
            ACC_mux_select = 2'b01; // Memory contents
          end
          3'b001: ; // STA (No effect on ACC)
          3'b010,
          3'b011,
          3'b100,
          3'b101,
          3'b110: ACC_write_enable = 1'b1; // ADD, SUB, AND, OR, XOR
        endcase
    
        // Control and Branching Instructions
        case (instruction)
          8'b11110001: begin // JSR
            ACC_write_enable = 1'b1;
            ACC_mux_select = 2'b10; // PC
          end
        endcase
    
        // Data Manipulation Instructions
        case (instruction)
          8'b11110110,
          8'b11110111,
          8'b11111000,
          8'b11111001,
          8'b11111010,
          8'b11111100,
          8'b11111101,
          8'b11111110: ACC_write_enable = 1'b1; // SHL, SHR, SHL4, ROL, ROR, DEC, CLR, INV
          8'b11111011: begin // LDAR
            ACC_write_enable = 1'b1;
            ACC_mux_select = 2'b01; // Memory contents
          end
        endcase
    
      end // if (state_out == STATE_EXECUTE)
   end
end

always @(*) begin
    // Default: IR_load_enable is 0 (disabled)
    IR_load_enable = 1'b0;

    // During FETCH cycle, set IR_load_enable to 1 (enabled)
    if (processor_enable && state_out == STATE_FETCH) begin
        IR_load_enable = 1'b1;
    end
end

always @(*) begin
    // Default: ALU_inputB_mux_select is 0 (memory contents)
    ALU_inputB_mux_select = 1'b0;

    // Immediate Data Manipulation Instructions
    if (processor_enable && instruction[7:4] == 4'b1110) begin // ADDI
        ALU_inputB_mux_select = 1'b1; // Select immediate value as input B
    end
end

always @(*) begin
    // Default: Memory_write_enable is 0 (disabled)
    Memory_write_enable = 1'b0;

    // Default: Memory_address_mux_select is 00 (IR[4:0])
    Memory_address_mux_select = 2'b00;

    if(processor_enable) begin
        if (state_out == STATE_EXECUTE) begin
            // Instructions with Variable-Data Operands
            case (instruction[7:5])
                3'b001: begin // STA
                    Memory_write_enable = 1'b1; // Enable writing to memory
                end
            endcase
    
            // Data Manipulation Instructions
            case (instruction[7:0])
                8'b11111011: begin // LDAR
                    Memory_address_mux_select = 2'b01; // Select ACC as memory address
                end
            endcase
        end
    
        // Instruction fetching
        if (state_out == STATE_FETCH) begin
            Memory_address_mux_select = 2'b10; // Select PC as memory address
        end
    end
end



endmodule
