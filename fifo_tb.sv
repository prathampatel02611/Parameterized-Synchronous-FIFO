//=============================================================================
// Module: fifo_tb
// Description: SystemVerilog self-checking testbench for synchronous FIFO
// Author: Pratham Patel P
// Simulator: ModelSim
//=============================================================================

`timescale 1ns / 1ps

module fifo_tb;

    //=========================================================================
    // Parameters
    //=========================================================================
    parameter DATA_W     = 8;
    parameter ADDR_W     = 4;
    parameter FIFO_DEPTH = 16;
    parameter CLK_PERIOD = 20;

    //=========================================================================
    // Signals — using 'logic' (SystemVerilog)
    //=========================================================================
    logic                   clk;
    logic                   rst_n;
    logic                   wr_en;
    logic [DATA_W-1:0]     wr_data;
    logic                   rd_en;
    logic [DATA_W-1:0]     rd_data;
    logic                   full;
    logic                   empty;
    logic                   almost_full;
    logic                   almost_empty;
    logic                   overflow;
    logic                   underflow;
    logic [ADDR_W:0]       word_count;

    // Scoreboard — expected data queue
    logic [DATA_W-1:0]     expected_queue [$];
    logic [DATA_W-1:0]     expected_data;

    // Tracking
    integer                 errors;
    integer                 test_num;
    integer                 total_tests;
    integer                 i;
    string                  test_name;

    //=========================================================================
    // DUT instantiation
    //=========================================================================
    synchronous_fifo dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .wr_en          (wr_en),
        .wr_data        (wr_data),
        .rd_en          (rd_en),
        .rd_data        (rd_data),
        .full           (full),
        .empty          (empty),
        .almost_full    (almost_full),
        .almost_empty   (almost_empty),
        .overflow       (overflow),
        .underflow      (underflow),
        .word_count     (word_count)
    );

    defparam dut.DATA_W     = DATA_W;
    defparam dut.ADDR_W     = ADDR_W;
    defparam dut.FIFO_DEPTH = FIFO_DEPTH;

    //=========================================================================
    // Clock generation
    //=========================================================================
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //=========================================================================
    // Task: apply_reset
    //=========================================================================
    task automatic apply_reset();
        begin
            $display("  [INFO] Applying reset...");
            rst_n   = 1'b0;
            wr_en   = 1'b0;
            rd_en   = 1'b0;
            wr_data = '0;
            expected_queue = {};  // clear scoreboard
            repeat(3) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
            $display("  [INFO] Reset released");
        end
    endtask

    //=========================================================================
    // Task: write_one — write single data to FIFO
    //=========================================================================
    task automatic write_one(input logic [DATA_W-1:0] data);
        begin
            @(posedge clk);
            wr_en   = 1'b1;
            wr_data = data;
            @(posedge clk);
            wr_en   = 1'b0;
        end
    endtask

    //=========================================================================
    // Task: read_one — read single data from FIFO
    //=========================================================================
    task automatic read_one();
        begin
            @(posedge clk);
            rd_en = 1'b1;
            @(posedge clk);
            rd_en = 1'b0;
        end
    endtask

    //=========================================================================
    // Task: write_burst — write N items sequentially
    //=========================================================================
    task automatic write_burst(input int count, input logic [DATA_W-1:0] start_val);
        begin
            $display("  [INFO] Writing %0d items starting from 0x%02h", count, start_val);
            for (int j = 0; j < count; j++) begin
                write_one(start_val + j);
                expected_queue.push_back(start_val + j);  // track in scoreboard
            end
        end
    endtask

    //=========================================================================
    // Task: read_burst — read N items and verify against scoreboard
    //=========================================================================
    task automatic read_burst(input int count);
        begin
            $display("  [INFO] Reading %0d items", count);
            for (int j = 0; j < count; j++) begin
                read_one;
                // Wait for synchronous read data to appear
                @(posedge clk);
                if (expected_queue.size() > 0) begin
                    expected_data = expected_queue.pop_front();
                    if (rd_data !== expected_data) begin
                        $display("  [FAIL] Data mismatch: got=0x%02h expected=0x%02h",
                                 rd_data, expected_data);
                        errors++;
                    end
                end
            end
        end
    endtask

    //=========================================================================
    // Task: write_random — write random data
    //=========================================================================
    task automatic write_random(input int count);
        logic [DATA_W-1:0] rand_data;
        begin
            $display("  [INFO] Writing %0d random items", count);
            for (int j = 0; j < count; j++) begin
                rand_data = $urandom_range(0, (1 << DATA_W) - 1);
                write_one(rand_data);
                expected_queue.push_back(rand_data);
            end
        end
    endtask

    //=========================================================================
    // Task: check_flag — verify a single flag value
    //=========================================================================
    task automatic check_flag(input string flag_name, 
                              input logic actual, 
                              input logic expected);
        begin
            if (actual !== expected) begin
                $display("  [FAIL] %s = %0b, expected %0b", flag_name, actual, expected);
                errors++;
            end else begin
                $display("  [PASS] %s = %0b", flag_name, actual);
            end
        end
    endtask

    //=========================================================================
    // Task: check_count — verify word count
    //=========================================================================
    task automatic check_count(input int expected);
        begin
            if (word_count !== expected) begin
                $display("  [FAIL] word_count = %0d, expected %0d", word_count, expected);
                errors++;
            end else begin
                $display("  [PASS] word_count = %0d", word_count);
            end
        end
    endtask

    //=========================================================================
    // Task: print_header — display test header
    //=========================================================================
    task automatic print_header(input int num, input string name);
        begin
            test_num  = num;
            test_name = name;
            $display("");
            $display("══════════════════════════════════════════════════");
            $display(" TEST %0d: %s", num, name);
            $display("══════════════════════════════════════════════════");
        end
    endtask

    //=========================================================================
    // Main test sequence
    //=========================================================================
    initial begin
        errors      = 0;
        total_tests = 0;

        $display("");
        $display("╔══════════════════════════════════════════════════╗");
        $display("║     SYNCHRONOUS FIFO TESTBENCH                  ║");
        $display("║     DATA_W=%0d  DEPTH=%0d                         ║", DATA_W, FIFO_DEPTH);
        $display("╚══════════════════════════════════════════════════╝");

        // ================================================================
        // TEST 1: Reset
        // ================================================================
        print_header(1, "Reset Behavior");
        total_tests++;
        apply_reset;
        @(posedge clk);
        check_flag("empty", empty, 1'b1);
        check_flag("full",  full,  1'b0);
        check_count(0);
        check_flag("overflow",  overflow,  1'b0);
        check_flag("underflow", underflow, 1'b0);

        // ================================================================
        // TEST 2: Single write and read
        // ================================================================
        print_header(2, "Single Write and Read");
        total_tests++;
        apply_reset;
        write_one(8'hAB);
        expected_queue.push_back(8'hAB);
        @(posedge clk);
        check_flag("empty", empty, 1'b0);
        check_count(1);

        read_one;
        @(posedge clk);
        expected_data = expected_queue.pop_front();
        if (rd_data !== expected_data) begin
            $display("  [FAIL] Read data=0x%02h, expected=0x%02h", rd_data, expected_data);
            errors++;
        end else
            $display("  [PASS] Read data=0x%02h correct", rd_data);

        // ================================================================
        // TEST 3: Fill FIFO to full
        // ================================================================
        print_header(3, "Fill FIFO to Full");
        total_tests++;
        apply_reset;
        write_burst(FIFO_DEPTH, 8'h00);
        @(posedge clk);
        check_flag("full", full, 1'b1);
        check_count(FIFO_DEPTH);

        // ================================================================
        // TEST 4: Overflow detection
        // ================================================================
        print_header(4, "Overflow Detection");
        total_tests++;
        // FIFO should still be full from test 3
        write_one(8'hFF);
        @(posedge clk);
        check_flag("overflow", overflow, 1'b1);
        check_count(FIFO_DEPTH);  // count should NOT increase
        $display("  [INFO] Data was rejected — FIFO protected");

        // ================================================================
        // TEST 5: Drain FIFO to empty
        // ================================================================
        print_header(5, "Drain FIFO to Empty");
        total_tests++;
        for (i = 0; i < FIFO_DEPTH; i++) begin
            read_one;
        end
        @(posedge clk);
        @(posedge clk);
        check_flag("empty", empty, 1'b1);
        check_count(0);

        // ================================================================
        // TEST 6: Underflow detection
        // ================================================================
        print_header(6, "Underflow Detection");
        total_tests++;
        // FIFO should be empty from test 5
        read_one;
        @(posedge clk);
        check_flag("underflow", underflow, 1'b1);
        check_count(0);  // count should NOT go negative
        $display("  [INFO] Read was rejected — FIFO protected");

        // ================================================================
        // TEST 7: Simultaneous read and write
        // ================================================================
        print_header(7, "Simultaneous Read and Write");
        total_tests++;
        apply_reset;
        // Pre-fill with 4 items
        write_burst(4, 8'h10);
        @(posedge clk);

        // Simultaneous R/W for 8 cycles
        for (i = 0; i < 8; i++) begin
            @(posedge clk);
            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = (i + 8'h50);
            @(posedge clk);
        end
        wr_en = 1'b0;
        rd_en = 1'b0;
        @(posedge clk);
        check_count(4);  // should remain at 4

        // ================================================================
        // TEST 8: Almost empty flag
        // ================================================================
        print_header(8, "Almost Empty Flag");
        total_tests++;
        apply_reset;
        write_burst(1, 8'h20);
        @(posedge clk);
        check_flag("almost_empty", almost_empty, 1'b1);
        check_flag("empty",        empty,        1'b0);

        write_burst(2, 8'h21);
        @(posedge clk);
        check_flag("almost_empty", almost_empty, 1'b1);
        check_count(3);

        // ================================================================
        // TEST 9: Almost full flag
        // ================================================================
        print_header(9, "Almost Full Flag");
        total_tests++;
        apply_reset;
        write_burst(FIFO_DEPTH - 3, 8'h30);
        @(posedge clk);
        check_flag("almost_full", almost_full, 1'b1);
        check_flag("full",        full,        1'b0);

        write_burst(2, 8'h60);
        @(posedge clk);
        check_flag("almost_full", almost_full, 1'b1);

        // ================================================================
        // TEST 10: Random data integrity
        // ================================================================
        print_header(10, "Random Data Integrity");
        total_tests++;
        apply_reset;
        write_random(8);
        @(posedge clk);
        check_count(8);
        read_burst(8);
        @(posedge clk);
        @(posedge clk);
        check_count(0);

        // ================================================================
        // TEST 11: Back-to-back operations
        // ================================================================
        print_header(11, "Back-to-Back Write then Read");
        total_tests++;
        apply_reset;

        // Rapid writes
        $display("  [INFO] Rapid writing 10 items...");
        for (i = 0; i < 10; i++) begin
            @(posedge clk);
            wr_en   = 1'b1;
            wr_data = i;
        end
        wr_en = 1'b0;
        @(posedge clk);
        check_count(10);

        // Rapid reads
        $display("  [INFO] Rapid reading 10 items...");
        for (i = 0; i < 10; i++) begin
            @(posedge clk);
            rd_en = 1'b1;
        end
        rd_en = 1'b0;
        @(posedge clk);
        @(posedge clk);
        check_count(0);

        // ================================================================
        // TEST 12: Reset during operation
        // ================================================================
        print_header(12, "Reset During Active Operation");
        total_tests++;
        apply_reset;
        write_burst(8, 8'hA0);
        @(posedge clk);
        check_count(8);

        // Assert reset while FIFO has data
        $display("  [INFO] Asserting reset with 8 items in FIFO...");
        rst_n = 1'b0;
        repeat(2) @(posedge clk);
        check_count(0);
        check_flag("empty", empty, 1'b1);
        check_flag("full",  full,  1'b0);
        rst_n = 1'b1;
        @(posedge clk);
        $display("  [PASS] FIFO cleared by reset");

        // ================================================================
        // FINAL RESULTS
        // ================================================================
        $display("");
        $display("╔══════════════════════════════════════════════════╗");
        if (errors == 0) begin
            $display("║  ✅  ALL %0d TESTS PASSED!                      ║", total_tests);
        end else begin
            $display("║  ❌  %0d FAILURES out of %0d tests               ║", errors, total_tests);
        end
        $display("║                                                  ║");
        $display("║  Total tests:  %2d                                ║", total_tests);
        $display("║  Passed:       %2d                                ║", total_tests - errors);
        $display("║  Failed:       %2d                                ║", errors);
        $display("╚══════════════════════════════════════════════════╝");
        $display("");

        #100;
        $stop;
    end

endmodule
