`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: ChatGPT GPT-4 Mar 23 version; Hammond Pearce (prompting)
// 
// Last Edited Date: 04/19/2023
//////////////////////////////////////////////////////////////////////////////////

module memory_bank #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8,
    parameter MEM_SIZE = 31, // Reduce memory size by 1 to accommodate IO
    parameter IO_ADDR = MEM_SIZE
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire write_enable,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire scan_enable,
    input wire scan_in,
    output wire scan_out,
    input wire btn_in, // Button input
    output wire [6:0] led_out // 7-bit LED output
);

    // Generate an array of shift registers for the memory
    wire [DATA_WIDTH-1:0] mem_data_out [0:MEM_SIZE-1];
    wire mem_scan_out [0:MEM_SIZE-1]; 

    genvar i;
    generate
        for (i = 0; i < MEM_SIZE; i = i + 1) begin : memory
            shift_register #(
                .WIDTH(DATA_WIDTH)
            ) mem_cell (
                .clk(clk),
                .rst(rst),
                .enable(write_enable && (address == i)),
                .data_in(data_in),
                .data_out(mem_data_out[i]),
                .scan_enable(scan_enable),
                .scan_in(i == 0 ? scan_in : mem_scan_out[i-1]),
                .scan_out(mem_scan_out[i])
            );
        end
    endgenerate

    // IO shift registers
    wire [6:0] led_data_out;
    wire btn_data_out;
    wire io_scan_out; // New wire to connect scan_out of led_shift_register to scan_in of btn_shift_register
    
    shift_register #(
        .WIDTH(7)
    ) led_shift_register (
        .clk(clk),
        .rst(rst),
        .enable(write_enable && (address == IO_ADDR)),
        .data_in(data_in[7:1]), // Read from upper 7 bits of data_in
        .data_out(led_data_out),
        .scan_enable(scan_enable),
        .scan_in(mem_scan_out[MEM_SIZE-1]),
        .scan_out(io_scan_out) // Connect the new wire to the scan_out
    );

    shift_register #(
        .WIDTH(1)
    ) btn_shift_register (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Enable the btn_shift_register, always read the status of the button input
        .data_in(btn_in),
        .data_out(btn_data_out),
        .scan_enable(scan_enable),
        .scan_in(io_scan_out), // Connect the new wire to the scan_in
        .scan_out(scan_out) // Connect the scan_out to the top-level module
    );

    // Read operation
    always @(*) begin
        if (address < MEM_SIZE) begin
            data_out = mem_data_out[address];
        end else case (address)
            IO_ADDR: data_out = {led_data_out, btn_data_out}; // Place btn_data_out at the LSB
            IO_ADDR + 1: data_out = IO_ADDR + 2; // Return IO_ADDR + 2 for address IO_ADDR + 1
            IO_ADDR + 2: data_out = {7'b0111111, 1'b0}; // 0
            IO_ADDR + 3: data_out = {7'b0000110, 1'b0}; // 1
            IO_ADDR + 4: data_out = {7'b1011011, 1'b0}; // 2
            IO_ADDR + 5: data_out = {7'b1001111, 1'b0}; // 3
            IO_ADDR + 6: data_out = {7'b1100110, 1'b0}; // 4
            IO_ADDR + 7: data_out = {7'b1101101, 1'b0}; // 5
            IO_ADDR + 8: data_out = {7'b1111100, 1'b0}; // 6
            IO_ADDR + 9: data_out = {7'b0000111, 1'b0}; // 7
            IO_ADDR + 10: data_out = {7'b1111111, 1'b0}; // 8
            IO_ADDR + 11: data_out = {7'b1100111, 1'b0}; // 9
            default: data_out = 8'b00000001; // Return "00000001" for all other memory addresses outside the range
        endcase
    end


    // Assign LED output
    assign led_out = led_data_out;

endmodule
