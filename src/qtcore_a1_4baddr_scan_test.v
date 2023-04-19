`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2023 07:50:28 AM
// Design Name: 
// Module Name: qtcore_a1_4baddr_scan_test
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
module qtcore_a1_4baddr_scan_test(

    );
    
 localparam CLK_PERIOD = 10;
    localparam CLK_HPERIOD = CLK_PERIOD/2;

    localparam MEM_SIZE = 18;
    localparam SCAN_CHAIN_SIZE = 24 + (MEM_SIZE * 8);
    wire [7:0] io_in;
    wire [7:0] io_out;

    reg clk_in, rst_in, scan_enable_in, scan_in, proc_en_in, btn_in;
    wire scan_out, halt_out;
    wire [6:0] led_out;
    kiwih_tt_top dut
    (
        .io_in(io_in),
        .io_out(io_out)
    );

    assign io_in[0] = clk_in;
    assign io_in[1] = rst_in;
    assign io_in[2] = !scan_enable_in;
    assign io_in[3] = !proc_en_in;
    assign io_in[4] = scan_in;
    assign io_in[5] = btn_in;

    assign scan_out = io_out[7];
    assign led_out = io_out[6:0];
    
    
    reg [SCAN_CHAIN_SIZE-1:0] scan_chain;     
    //2:0   - state
    //7:3   - PC
    //15:8  - IR
    //23:16 - ACC
    //31:24 - MEM[0]    
    //etc
    reg spi_miso_cap;
    integer i;
    integer fid;

    initial begin
        scan_chain = 'b0;

        // TEST PART 1: LOAD SCAN CHAIN

        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h1;    //PC = 1
        scan_chain[15:8] = 8'he0; //IR = ADDI 0 (NOP), should get overrwritten by MEM[2]
        scan_chain[23:16] = 8'h01; //ACC = 0x01
        scan_chain[31:24] = 8'he0; //MEM[0] = 0xE0
        scan_chain[39:32] = 8'he1; //MEM[1] = 0xE1 (ADDI 1)
        scan_chain[47:40] = 8'he2; //MEM[2] = 0xE2 (ADDI 2)
        scan_chain[55:48] = 8'he3; //MEM[3] = 0xE3 (ADDI 3)
        scan_chain[63:56] = 8'he4; //MEM[4] = 0xE4 (ADDI 4)

        scan_chain[SCAN_CHAIN_SIZE-1 -: 8] = 8'hF0;
        
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        
        //TEST 1: reset the processor
        rst_in = 1;
        #CLK_PERIOD;
        rst_in = 0;
        #CLK_PERIOD;
        
        
        scan_enable_in = 1; //asert low chip select
        for (i = 0; i < SCAN_CHAIN_SIZE; i = i + 1) begin
            scan_in = scan_chain[SCAN_CHAIN_SIZE-1];
            #(CLK_PERIOD / 2);
            clk_in = 1;
            spi_miso_cap = scan_out;
            #(CLK_PERIOD / 2);
            clk_in = 0;
            scan_chain = {scan_chain[SCAN_CHAIN_SIZE-2:0], spi_miso_cap};
        end
        #(CLK_PERIOD);
        scan_enable_in = 0;
        
        if(dut.qtcore.cu_inst.state_register.internal_data != 3'b001) begin
            $display("Wrong state reg value");
            $finish;
        end
        if(dut.qtcore.PC_inst.internal_data != 5'h1) begin
            $display("Wrong PC reg value");
            $finish;
        end
        if(dut.qtcore.IR_inst.internal_data != 8'he0) begin
            $display("Wrong IR reg value");
            $finish;
        end
        if(dut.qtcore.ACC_inst.internal_data != 8'h01) begin
            $display("Wrong ACC reg value");
            $finish;
        end
        if(dut.qtcore.memory_inst.memory[0].mem_cell.internal_data != 8'he0) begin
            $display("Wrong mem[0] reg value");
            $finish;
        end
        if(dut.qtcore.memory_inst.memory[1].mem_cell.internal_data != 8'he1) begin
            $display("Wrong mem[1] reg value");
            $finish;
        end
        if(dut.qtcore.memory_inst.memory[2].mem_cell.internal_data != 8'he2) begin
            $display("Wrong mem[2] reg value");
            $finish;
        end
        if(dut.qtcore.memory_inst.memory[3].mem_cell.internal_data != 8'he3) begin
            $display("Wrong mem[3] reg value");
            $finish;
        end
        if(led_out != 7'b1111000) begin
            $display("Wrong LED data out, got %b", led_out);
            $finish;
        end
        
        $display("Scan load successful");
        
        //TEST PART 2: RUN PROCESSOR
        
        proc_en_in = 1;
        for (i = 0; i < 8; i = i + 1) begin //two cycles per instruction, this should execute 4 instr
            #(CLK_PERIOD / 2);
            clk_in = 1;
            #(CLK_PERIOD / 2);
            clk_in = 0;
        end
        proc_en_in = 0;
        if(dut.qtcore.ACC_inst.internal_data != 8'hb) begin
            $display("Wrong ACC reg value %d", dut.qtcore.ACC_inst.internal_data);
           
            $finish;
        end
        
        $display("Instruction operation successful");
        scan_chain = 'b0;

        //TEST PART 3: UNLOAD SCAN CHAIN 
        
        scan_enable_in = 1; //asert low chip select
        for (i = 0; i < SCAN_CHAIN_SIZE; i = i + 1) begin
            scan_in = scan_chain[SCAN_CHAIN_SIZE-1];
            #(CLK_PERIOD / 2);
            clk_in = 1;
            spi_miso_cap = scan_out;
            #(CLK_PERIOD / 2);
            clk_in = 0;
            scan_chain = {scan_chain[SCAN_CHAIN_SIZE-2:0], spi_miso_cap};
        end
        #(CLK_PERIOD);
        scan_enable_in = 0;
        
        if(scan_chain[2:0] != 3'b001) begin
            $display("Wrong unloaded state reg");
            $finish;
        end
        if(scan_chain[7:3] != 5'h5) begin
            $display("Wrong unloaded PC");
            $finish;
        end
        if(scan_chain[15:8] != 8'he4) begin
            $display("Wrong unloaded IR");
            $finish;
        end
        if(scan_chain[23:16] != 8'hb) begin
            $display("Wrong unloaded ACC");
            $finish;
        end
        if(scan_chain[31:24] != 8'he0) begin
            $display("Wrong unloaded MEM[0]");
            $finish;
        end
        if(scan_chain[39:32] != 8'he1) begin
            $display("Wrong unloaded MEM[1]");
            $finish;
        end
        if(scan_chain[47:40] != 8'he2) begin
            $display("Wrong unloaded MEM[2]");
            $finish;
        end
        if(scan_chain[55:48] != 8'he3) begin
            $display("Wrong unloaded MEM[3]");
            $finish;
        end
        if(scan_chain[63:56] != 8'he4) begin
            $display("Wrong unloaded MEM[4]");
            $finish;
        end
        
        $display("Unload scan chain successful");
        
        fid = $fopen("TEST_PASSES.txt", "w");
        $fwrite(fid, "TEST_PASSES");
        $display("TEST_PASSES");
        $fclose(fid);
     end
    
endmodule
