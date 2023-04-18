`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2023 04:00:20 PM
// Design Name: 
// Module Name: memory_bank
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


module memory_bank #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8,
    parameter MEM_SIZE = 32
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

    output wire [6:0] led_out
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

    // Read operation
    integer idx;
    always @(*) begin
//        data_out = {DATA_WIDTH{1'b0}};
//        for (idx = 0; idx < MEM_SIZE; idx = idx + 1) begin
//            if (address == idx) begin
//                data_out = mem_data_out[idx];
//            end
//        end
        data_out = mem_data_out[address];
    end

    // Scan chain output
    assign scan_out = mem_scan_out[MEM_SIZE-1];
    
    assign led_out = mem_data_out[15][6:0];
    
//    reg [7:0] register_bank [0:31];

//    integer i;
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            for (i = 0; i < 32; i = i + 1) begin
//                register_bank[i] <= 8'b0;
//            end
//        end else begin
//            if (scan_enable) begin
//                if (shift_left) begin
//                    for (i = 0; i < 31; i = i + 1) begin
//                        register_bank[i] <= register_bank[i + 1];
//                    end
//                    register_bank[31] <= data_in;
//                end else begin
//                    for (i = 31; i > 0; i = i - 1) begin
//                        register_bank[i] <= register_bank[i - 1];
//                    end
//                    register_bank[0] <= data_in;
//                end
//            end else begin
//                register_bank[addr] <= data_in;
//            end
//        end
//    end

//    assign data_out = register_bank[addr];

endmodule



