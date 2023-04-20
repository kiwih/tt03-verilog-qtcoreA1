`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: Hammond Pearce
// 
// Last Edited Date: 04/19/2023
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module qtcore_a1_4baddr_scan_test (

    );
    
 localparam CLK_PERIOD = 50;
    localparam CLK_HPERIOD = CLK_PERIOD/2;

    localparam FULL_MEM_SIZE = 18; //includes the IO register
    localparam SCAN_CHAIN_SIZE = 24 + (FULL_MEM_SIZE * 8);
    wire [7:0] io_in;
    wire [7:0] io_out;

    reg clk_in, rst_in, scan_enable_in, scan_in, proc_en_in, btn_in;
    wire scan_out, halt_out;
    wire [6:0] led_out;
    kiwih_tt_top dut
    (
`ifdef USE_POWER_PINS
        .vccd1(1'b1),
        .vssd1(1'b0),
`endif
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

    task xchg_scan_chain;
    begin
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
    end
    endtask

    task reset_processor;
    begin
        rst_in = 1;
        #(CLK_PERIOD);
        rst_in = 0;
        #(CLK_PERIOD);
    end
    endtask

    task run_processor_until_halt(
        input integer max_cycles,
        output integer n_cycles
    );
    begin
        proc_en_in = 1;
        for (n_cycles = 0; n_cycles < max_cycles && (n_cycles < 4 || scan_out == 0) ; n_cycles = n_cycles + 1) begin //two cycles per instruction, this should execute 4 instr
            #(CLK_PERIOD / 2);
            clk_in = 1;
            #(CLK_PERIOD / 2);
            clk_in = 0;
        end
        proc_en_in = 0;
    end
    endtask

    initial begin
        $dumpfile("qtcore_a1_4baddr_scan_test.vcd");
        $dumpvars(0, qtcore_a1_4baddr_scan_test);
        scan_chain = 'b0;
        `ifdef SCAN_ONLY
            $display("SCAN ONLY");
        `endif
        $display("TEST 1");

        // TEST PART 1: LOAD SCAN CHAIN

        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h1;    //PC = 1
        scan_chain[15:8] = 8'he0; //IR = ADDI 0 (NOP), should get overrwritten by MEM[2]
        scan_chain[23:16] = 8'h01; //ACC = 0x01
        scan_chain[31 -: 8] = 8'he0; //MEM[0] = 0xE0
        scan_chain[39 -: 8] = 8'he1; //MEM[1] = 0xE1 (ADDI 1)
        scan_chain[47 -: 8] = 8'he2; //MEM[2] = 0xE2 (ADDI 2)
        scan_chain[55 -: 8] = 8'he3; //MEM[3] = 0xE3 (ADDI 3)
        scan_chain[63 -: 8] = 8'he4; //MEM[4] = 0xE4 (ADDI 4)

        scan_chain[SCAN_CHAIN_SIZE-1 -: 8] = 8'hF0; //write to the IO register
        
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        clk_in = 0;
        rst_in = 0;
        btn_in = 0;
        
        //TEST 1: reset the processor
        reset_processor;
        
        xchg_scan_chain;
        
        `ifndef SCAN_ONLY
            $display("scan not enabled, running internal checks");
            if(dut.qtcore.cu_inst.state_register.internal_data !== 3'b001) begin
                $display("Wrong state reg value");
                $finish;
            end
            if(dut.qtcore.PC_inst.internal_data !== 5'h1) begin
                $display("Wrong PC reg value");
                $finish;
            end
            if(dut.qtcore.IR_inst.internal_data !== 8'he0) begin
                $display("Wrong IR reg value");
                $finish;
            end
            if(dut.qtcore.ACC_inst.internal_data !== 8'h01) begin
                $display("Wrong ACC reg value");
                $finish;
            end
            if(dut.qtcore.memory_inst.memory[0].mem_cell.internal_data !== 8'he0) begin
                $display("Wrong mem[0] reg value");
                $finish;
            end
            if(dut.qtcore.memory_inst.memory[1].mem_cell.internal_data !== 8'he1) begin
                $display("Wrong mem[1] reg value");
                $finish;
            end
            if(dut.qtcore.memory_inst.memory[2].mem_cell.internal_data !== 8'he2) begin
                $display("Wrong mem[2] reg value");
                $finish;
            end
            if(dut.qtcore.memory_inst.memory[3].mem_cell.internal_data !== 8'he3) begin
                $display("Wrong mem[3] reg value");
                $finish;
            end
        `endif

        if(led_out !== 7'b1111000) begin
            $display("Wrong LED data out, got %b", led_out);
            $finish;
        end
    
        $display("Scan load successful");
        
        //TEST PART 2: RUN PROCESSOR
        
        run_processor_until_halt(8, i); //two cycles per instruction, this should execute 4 instr

        `ifndef SCAN_ONLY
            $display("ACC is: %b", dut.qtcore.ACC_inst.internal_data);
            if(dut.qtcore.ACC_inst.internal_data !== 8'hb) begin
                $display("Wrong ACC reg value %d", dut.qtcore.ACC_inst.internal_data);
               
                $finish;
            end
        
            $display("Instruction operation successful");
        `endif
        scan_chain = 'b0;

        //TEST PART 3: UNLOAD SCAN CHAIN 
        
        xchg_scan_chain;
        
        if(scan_chain[2:0] !== 3'b001) begin
            $display("Wrong unloaded state reg");
            $finish;
        end
        if(scan_chain[7:3] !== 5'h5) begin
            $display("Wrong unloaded PC");
            $finish;
        end
        if(scan_chain[15:8] !== 8'he4) begin
            $display("Wrong unloaded IR");
            $finish;
        end
        if(scan_chain[23:16] !== 8'hb) begin
            $display("Wrong unloaded ACC");
            $finish;
        end
        if(scan_chain[31 -: 8] !== 8'he0) begin
            $display("Wrong unloaded MEM[0]");
            $finish;
        end
        if(scan_chain[31+8*1 -: 8] !== 8'he1) begin
            $display("Wrong unloaded MEM[1]");
            $finish;
        end
        if(scan_chain[31+8*2 -: 8] !== 8'he2) begin
            $display("Wrong unloaded MEM[2]");
            $finish;
        end
        if(scan_chain[31+8*3 -: 8] !== 8'he3) begin
            $display("Wrong unloaded MEM[3]");
            $finish;
        end
        if(scan_chain[31+8*4 -: 8] !== 8'he4) begin
            $display("Wrong unloaded MEM[4]");
            $finish;
        end
        
        $display("Unload scan chain successful");

        $display("TEST 2");

        scan_chain = 'b0;
        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h0;    //PC = 0
        scan_chain[15:8] = 8'h00; //IR = 0
        scan_chain[23:16] = 8'h00; //ACC = 0x00
        scan_chain[31 -: 8] = 8'b00001111;
        scan_chain[39 -: 8] = 8'b11110010;
        scan_chain[47 -: 8] = 8'b11111100;
        scan_chain[55 -: 8] = 8'b00101111;
        scan_chain[63 -: 8] = 8'b11110101;
        scan_chain[71 -: 8] = 8'b11101111;
        scan_chain[79 -: 8] = 8'b11111000;
        scan_chain[87 -: 8] = 8'b11101111;
        scan_chain[95 -: 8] = 8'b11100001;
        scan_chain[103 -: 8] = 8'b00101110;
        scan_chain[111 -: 8] = 8'b11110011;
        scan_chain[119 -: 8] = 8'b11111111;
        scan_chain[127 -: 8] = 8'b00000000;
        scan_chain[135 -: 8] = 8'b00000000;
        scan_chain[143 -: 8] = 8'b00000000;
        scan_chain[151 -: 8] = 8'b00010000;
        scan_chain[159 -: 8] = 8'b00000000;

        //RESET PROCESSOR
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        reset_processor;
        //SCAN
        xchg_scan_chain;
        //RUN PROCESSOR UNTIL HALT
        run_processor_until_halt(256, i);
        if(scan_out != 1) begin
            $display("Program failed to halt");
            $finish;
        end
        $display("Program halted after %d clock cycles", i);
        //SCAN OUT
        xchg_scan_chain;

        if(scan_chain[31+8*15 -: 8] !== 8'h0) begin
            $display("MEM[15] wrong value");
            $finish;
        end
        if(scan_chain[31+8*14 -: 8] !== 8'h1) begin
            $display("MEM[14] wrong value %d", scan_chain[24+16*8 -: 8]);
            $finish;
        end
        $display("Memory values correct after scanout");

        $display("TEST 3");

        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h0;    //PC = 0
        scan_chain[15:8] = 8'h00; //IR = 0
        scan_chain[23:16] = 8'h00; //ACC = 0x00
        scan_chain[31 -: 8] = 8'b00010000;
        scan_chain[39 -: 8] = 8'b11100001;
        scan_chain[47 -: 8] = 8'b00100000;
        scan_chain[55 -: 8] = 8'b01010000;
        scan_chain[63 -: 8] = 8'b00100001;
        scan_chain[71 -: 8] = 8'b01110000;
        scan_chain[79 -: 8] = 8'b00100010;
        scan_chain[87 -: 8] = 8'b10001111;
        scan_chain[95 -: 8] = 8'b00100011;
        scan_chain[103 -: 8] = 8'b10101110;
        scan_chain[111 -: 8] = 8'b00100100;
        scan_chain[119 -: 8] = 8'b11001101;
        scan_chain[127 -: 8] = 8'b00100101;
        scan_chain[135 -: 8] = 8'b11111111;
        scan_chain[143 -: 8] = 8'b00000100;
        scan_chain[151 -: 8] = 8'b00001111;
        scan_chain[159 -: 8] = 8'b00001010;

        //RESET PROCESSOR
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        reset_processor;
        //SCAN
        xchg_scan_chain;
        //RUN PROCESSOR UNTIL HALT
        run_processor_until_halt(256, i);
        if(scan_out != 1) begin
            $display("Program failed to halt");
            $finish;
        end
        $display("Program halted after %d clock cycles", i);
        //SCAN OUT
        xchg_scan_chain;

        if(scan_chain[31+8*0 -: 8] !== 11) begin
            $display("MEM[0] wrong value");
            $finish;
        end
        if(scan_chain[31+8*1 -: 8] !== 21) begin
            $display("MEM[1] wrong value");
            $finish;
        end
        if(scan_chain[31+8*2 -: 8] !== 11) begin
            $display("MEM[2] wrong value");
            $finish;
        end
        if(scan_chain[31+8*3 -: 8] !== 11) begin
            $display("MEM[3] wrong value");
            $finish;
        end
        if(scan_chain[31+8*4 -: 8] !== 15) begin
            $display("MEM[4] wrong value");
            $finish;
        end
        if(scan_chain[31+8*5 -: 8] !== 8'hf0) begin
            $display("MEM[5] wrong value");
            $finish;
        end
        $display("Memory values correct after scanout");

        $display("TEST 4");

        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h0;    //PC = 0
        scan_chain[15:8] = 8'h00; //IR = 0
        scan_chain[23:16] = 8'h00; //ACC = 0x00
        scan_chain[31 -: 8] = 8'b00010000;
        scan_chain[39 -: 8] = 8'b11110110;
        scan_chain[47 -: 8] = 8'b00100000;
        scan_chain[55 -: 8] = 8'b11110111;
        scan_chain[63 -: 8] = 8'b00100001;
        scan_chain[71 -: 8] = 8'b11111000;
        scan_chain[79 -: 8] = 8'b00100010;
        scan_chain[87 -: 8] = 8'b11111001;
        scan_chain[95 -: 8] = 8'b00100011;
        scan_chain[103 -: 8] = 8'b11111010;
        scan_chain[111 -: 8] = 8'b00100100;
        scan_chain[119 -: 8] = 8'b11111100;
        scan_chain[127 -: 8] = 8'b00100101;
        scan_chain[135 -: 8] = 8'b11111101;
        scan_chain[143 -: 8] = 8'b11111110;
        scan_chain[151 -: 8] = 8'b00100110;
        scan_chain[159 -: 8] = 8'b00001010;


        //RESET PROCESSOR
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        reset_processor;
        //SCAN
        xchg_scan_chain;
        //RUN PROCESSOR UNTIL HALT
        run_processor_until_halt(256, i);
        if(scan_out != 1) begin
            $display("Program failed to halt");
            $finish;
        end
        $display("Program halted after %d clock cycles", i);
        //SCAN OUT
        xchg_scan_chain;

        if(scan_chain[31+8*0 -: 8] !== 20) begin
            $display("MEM[0] wrong value");
            $finish;
        end
        if(scan_chain[31+8*1 -: 8] !== 10) begin
            $display("MEM[1] wrong value");
            $finish;
        end
        if(scan_chain[31+8*2 -: 8] !== 160) begin
            $display("MEM[2] wrong value");
            $finish;
        end
        if(scan_chain[31+8*3 -: 8] !== 65) begin
            $display("MEM[3] wrong value");
            $finish;
        end
        if(scan_chain[31+8*4 -: 8] !== 160) begin
            $display("MEM[4] wrong value");
            $finish;
        end
        if(scan_chain[31+8*5 -: 8] !== 159) begin
            $display("MEM[5] wrong value");
            $finish;
        end
        if(scan_chain[31+8*6 -: 8] !== 255) begin
            $display("MEM[5] wrong value");
            $finish;
        end
        $display("Memory values correct after scanout");

        $display("TEST 5: BTN/LED");

        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h0;    //PC = 0
        scan_chain[15:8] = 8'h00; //IR = 0
        scan_chain[23:16] = 8'h00; //ACC = 0x00
        scan_chain[31 -: 8] = 8'b00010001;
        scan_chain[39 -: 8] = 8'b10010000;
        scan_chain[47 -: 8] = 8'b11110101;
        scan_chain[55 -: 8] = 8'b00010001;
        scan_chain[63 -: 8] = 8'b10010000;
        scan_chain[71 -: 8] = 8'b11110011;
        scan_chain[79 -: 8] = 8'b00001110;
        scan_chain[87 -: 8] = 8'b11010000;
        scan_chain[95 -: 8] = 8'b00101110;
        scan_chain[103 -: 8] = 8'b11101110;
        scan_chain[111 -: 8] = 8'b11111011;
        scan_chain[119 -: 8] = 8'b00110001;
        scan_chain[127 -: 8] = 8'b11111101;
        scan_chain[135 -: 8] = 8'b11110000;
        scan_chain[143 -: 8] = 8'b00000000;
        scan_chain[151 -: 8] = 8'b00011000;
        scan_chain[159 -: 8] = 8'b00000001;


        //RESET PROCESSOR
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        reset_processor;
        //SCAN
        xchg_scan_chain;
        //RUN PROCESSOR FOR 32 cycles at a time (should not halt)
        btn_in = 0;
        run_processor_until_halt(32, i);
        btn_in = 1;
        run_processor_until_halt(32, i);
        
        if(led_out != 7'h0c) begin
            $display("LEDs wrong value");
            $finish;
        end

        btn_in = 0;
        run_processor_until_halt(32, i);
        btn_in = 1;
        run_processor_until_halt(32, i);
        
        if(led_out != 7'h00) begin
            $display("LEDs wrong value");
            $finish;
        end

        btn_in = 0;
        run_processor_until_halt(32, i);
        btn_in = 1;
        run_processor_until_halt(32, i);
        
        if(led_out != 7'h0c) begin
            $display("LEDs wrong value");
            $finish;
        end

        btn_in = 0;
        run_processor_until_halt(32, i);
        btn_in = 0;
        run_processor_until_halt(32, i);
        
        if(led_out != 7'h0c) begin
            $display("LEDs wrong value (should not have changed, btn=1 missing)");
            $finish;
        end
        
        $display("BTN/LED values correct");

        $display("TEST 6: 7SEG");
        scan_chain[2:0] = 3'b001;  //state = fetch
        scan_chain[7:3] = 5'h0;    //PC = 0
        scan_chain[15:8] = 8'h00; //IR = 0
        scan_chain[23:16] = 8'h00; //ACC = 0x00
        scan_chain[31 -: 8] = 8'b00010000;
        scan_chain[39 -: 8] = 8'b01010010;
        scan_chain[47 -: 8] = 8'b11111011;
        scan_chain[55 -: 8] = 8'b00110001;
        scan_chain[63 -: 8] = 8'b00010000;
        scan_chain[71 -: 8] = 8'b11100001;
        scan_chain[79 -: 8] = 8'b00110000;
        scan_chain[87 -: 8] = 8'b11111101;
        scan_chain[95 -: 8] = 8'b11110000;
        scan_chain[103 -: 8] = 8'b00000000;
        scan_chain[111 -: 8] = 8'b00000000;
        scan_chain[119 -: 8] = 8'b00000000;
        scan_chain[127 -: 8] = 8'b00000000;
        scan_chain[135 -: 8] = 8'b00000000;
        scan_chain[143 -: 8] = 8'b00000000;
        scan_chain[151 -: 8] = 8'b00000000;
        scan_chain[159 -: 8] = 8'b00000000;


        //RESET PROCESSOR
        scan_enable_in = 0;
        proc_en_in = 0;
        scan_in = 0;
        reset_processor;
        //SCAN
        xchg_scan_chain;
        //RUN PROCESSOR FOR 16 cycles at a time (should not halt)
        run_processor_until_halt(18, i);
        if(led_out != 7'b0111111) begin //first output value: "0"
            $display("LEDs wrong value 0: %b", led_out);
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b0000110) begin //first output value: "1"
            $display("LEDs wrong value 1");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1011011) begin //first output value: "2"
            $display("LEDs wrong value 2");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1001111) begin //first output value: "3"
            $display("LEDs wrong value 3 %b", led_out);
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1100110) begin //first output value: "4"
            $display("LEDs wrong value 4");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1101101) begin //first output value: "5"
            $display("LEDs wrong value 5");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1111100) begin //first output value: "6"
            $display("LEDs wrong value");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b0000111) begin //first output value: "7"
            $display("LEDs wrong value");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1111111) begin //first output value: "8"
            $display("LEDs wrong value");
            $finish;
        end
        run_processor_until_halt(18, i);
        if(led_out != 7'b1100111) begin //first output value: "9"
            $display("LEDs wrong value");
            $finish;
        end

        $display("All segment counting correct");
        
        fid = $fopen("TEST_PASSES.txt", "w");
        $fwrite(fid, "TEST_PASSES");
        $display("TEST_PASSES");
        $fclose(fid);
     end
    
endmodule
