`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: ChatGPT GPT-4 Mar 23 version; Hammond Pearce (prompting + assembly + top-level module definition)
// 
// Last Edited Date: 04/19/2023
//////////////////////////////////////////////////////////////////////////////////


module accumulator_microcontroller #(
    parameter MEM_SIZE = 32
) 
(
    input wire clk,
    input wire rst,
    input wire scan_enable,
    input wire scan_in,
    output wire scan_out,
    input wire proc_en,
    output wire halt,

    input wire btn_in,
    output wire [6:0] led_out
);
    // Declare wires for ALU, memory, PC, ACC, and IR connections
    wire [7:0] alu_A;
    wire [7:0] alu_B;
    wire [7:0] alu_Y;
    reg [4:0] memory_address;
    wire [7:0] memory_data_in;
    wire [7:0] memory_data_out;
    reg [4:0] pc_data_in;
    wire [4:0] pc_data_out;
    reg [7:0] acc_data_in;
    wire [7:0] acc_data_out;
    wire [7:0] ir_data_in;
    wire [7:0] ir_data_out;
    wire cu_PC_write_enable;
    wire [1:0] cu_PC_mux_select;
    wire cu_ACC_write_enable;
    wire [1:0] cu_ACC_mux_select;
    wire cu_IR_load_enable;
    wire [3:0] cu_ALU_opcode;
    wire cu_ALU_inputB_mux_select;
    wire cu_Memory_write_enable;
    wire [1:0] cu_Memory_address_mux_select;
    wire cu_ZF;
    wire control_unit_scan_out;
    wire pc_scan_out;
    wire acc_scan_out;
    wire ir_scan_out;
    wire memory_scan_out;
    wire zero_flag;

    // Instantiate ALU
    alu ALU_inst (
        .A(alu_A),
        .B(alu_B),
        .opcode(cu_ALU_opcode),
        .Y(alu_Y)
    );

    // Instantiate ALU Input A multiplexer (connected to ACC)
    assign alu_A = acc_data_out;

    // Instantiate ALU Input B multiplexer
    wire [7:0] immediate;
    assign immediate = {4'b0000, ir_data_out[3:0]}; // Immediate value is IR[3:0] with four zero-extended MSBs

    assign alu_B = cu_ALU_inputB_mux_select ? immediate : memory_data_out;

    // Remaining module instantiations and connections go here
    // Instantiate PC
    shift_register #(
        .WIDTH(5)
    ) PC_inst (
        .clk(clk),
        .rst(rst),
        .enable(cu_PC_write_enable),
        .data_in(pc_data_in),
        .data_out(pc_data_out),
        .scan_enable(scan_enable),
        .scan_in(control_unit_scan_out),
        .scan_out(pc_scan_out)
    );
    
    // Instantiate PC multiplexer
    wire [4:0] pc_plus_one = pc_data_out + 5'b1;
    wire [4:0] pc_minus_three = pc_data_out - 5'b11;
    // Declare additional wires for PC mux
    wire [4:0] pc_plus_two = pc_data_out + 5'b10;

    // Instantiate PC multiplexer
    always @(*) begin
        case(cu_PC_mux_select)
            2'b00: pc_data_in = pc_plus_one;
            2'b01: pc_data_in = acc_data_out[4:0];
            2'b10: pc_data_in = pc_minus_three;
            default: pc_data_in = pc_plus_two;
        endcase
    end

    
    // Instantiate IR
    shift_register #(
        .WIDTH(8)
    ) IR_inst (
        .clk(clk),
        .rst(rst),
        .enable(cu_IR_load_enable),
        .data_in(memory_data_out),
        .data_out(ir_data_out),
        .scan_enable(scan_enable),
        .scan_in(pc_scan_out),
        .scan_out(ir_scan_out)
    );
    
    // Instantiate ACC
    shift_register #(
        .WIDTH(8)
    ) ACC_inst (
        .clk(clk),
        .rst(rst),
        .enable(cu_ACC_write_enable),
        .data_in(acc_data_in),
        .data_out(acc_data_out),
        .scan_enable(scan_enable),
        .scan_in(ir_scan_out),
        .scan_out(acc_scan_out)
    );
    
    // Instantiate ACC multiplexer
    always @(*) begin
        case(cu_ACC_mux_select)
            2'b00: acc_data_in = alu_Y;
            2'b01: acc_data_in = memory_data_out;
            default: acc_data_in = {3'b000, pc_data_out};
        endcase
    end

    
    // Instantiate Memory Bank
    memory_bank #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(8),
        .MEM_SIZE(MEM_SIZE)
    ) memory_inst (
        .clk(clk),
        .rst(rst),
        .address(memory_address),
        .data_in(acc_data_out),
        .write_enable(cu_Memory_write_enable),
        .data_out(memory_data_out),
        .scan_enable(scan_enable),
        .scan_in(acc_scan_out),
        .scan_out(memory_scan_out),

        // Connect btn_in and led_out
        .btn_in(btn_in),
        .led_out(led_out)
    );

    
    // Instantiate Memory Address Multiplexer
    always @(*) begin
        case(cu_Memory_address_mux_select)
            2'b00: memory_address = ir_data_out[4:0];
            2'b01: memory_address = acc_data_out[4:0];
            default: memory_address = pc_data_out;
        endcase
    end

    
    // Instantiate Control Unit
    control_unit cu_inst (
        .clk(clk),
        .rst(rst),
        .processor_enable(proc_en),
        .processor_halted(halt),
        .instruction(ir_data_out),
        .ZF(zero_flag),
    
        .PC_write_enable(cu_PC_write_enable),
        .PC_mux_select(cu_PC_mux_select),
    
        .ACC_write_enable(cu_ACC_write_enable),
        .ACC_mux_select(cu_ACC_mux_select),
    
        .IR_load_enable(cu_IR_load_enable),
    
        .ALU_opcode(cu_ALU_opcode),
        .ALU_inputB_mux_select(cu_ALU_inputB_mux_select),
    
        .Memory_write_enable(cu_Memory_write_enable),
        .Memory_address_mux_select(cu_Memory_address_mux_select),
    
        .scan_enable(scan_enable),
        .scan_in(scan_in),
        .scan_out(control_unit_scan_out)
    );
    
    
    // Generate zero_flag
    assign zero_flag = (acc_data_out == 8'b0);
    
    // Connect top-level scan_out
    assign scan_out = memory_scan_out;


endmodule
