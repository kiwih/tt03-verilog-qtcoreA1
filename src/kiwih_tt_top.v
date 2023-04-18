`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2023 05:48:45 AM
// Design Name: 
// Module Name: tt_top
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

`default_nettype none
module kiwih_tt_top(
    input wire [7:0] io_in,
    output wire [7:0] io_out
    );
    
wire clk = io_in[0];
wire rst = io_in[1];

wire scan_enable_in = !io_in[2]; //SPI uses active low
wire proc_enable_in = !io_in[3]; //SPI uses active low
wire scan_in = io_in[4];
wire scan_out, halt_out;

wire miso = scan_enable_in ? scan_out :
            proc_enable_in ? halt_out :
            0;

assign io_out[7] = miso;
assign io_out[6:0] = 0;

accumulator_microcontroller #(
        .MEM_SIZE(16)
)
qtcore
(
    .clk(clk),
    .rst(rst),
    .scan_enable(scan_enable_in),
    .scan_in(scan_in),
    .scan_out(scan_out),
    .proc_en(proc_enable_in),
    .halt(halt_out)
);
endmodule
