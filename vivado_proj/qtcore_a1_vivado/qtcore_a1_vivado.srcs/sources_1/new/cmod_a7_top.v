`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2023 10:12:49 AM
// Design Name: 
// Module Name: cmod_a7_top
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
module cmod_a7_top(
    input wire spi_clk,
    input wire spi_mosi,
    input wire spi_cs_scan, spi_cs_proc,
    input wire [1:0] btn,
    
    output wire led0_b, led0_r, led0_g,
    output wire [1:0] led,
    output wire spi_miso
    );
    
wire rst = btn[1];

wire [6:0] led_out;

wire [7:0] io_in;
wire [7:0] io_out;

assign io_in[0] = spi_clk;
assign io_in[1] = rst;
assign io_in[2] = spi_cs_scan; //SPI uses active low
assign io_in[3] = spi_cs_proc; //SPI uses active low
assign io_in[4] = spi_mosi;
assign io_in[5] = btn[0];

assign spi_miso = io_out[7];
assign led_out = io_out[6:0];
assign led0_b = led_out[0];
assign led0_r = led_out[1];
assign led0_g = led_out[2];
assign led[0] = led_out[3];
assign led[1] = led_out[4];

kiwih_tt_top kiwih_tt_top (
    .io_in(io_in),
    .io_out(io_out)    
);

endmodule
