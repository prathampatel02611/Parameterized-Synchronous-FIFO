//=============================================================================
// Module: fifo_tb
// Description: Self-checking testbench for synchronous FIFO
// Author: Pratham Patel P
// Simulator: ModelSim (Quartus 9.1)
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
    // Signals
    //=========================================================================
    reg                     clk;
    reg                     rst_n;
    reg                     wr_en;
    reg  [DATA_W-1:0]      wr_data;
    reg                     rd_en;
    wire [DATA_W-1:0]      rd_data;
    wire                    full;
    wire                    empty;
    wire                    almost_full;
    wire                    almost_empty;
    wire                    overflow;
    wire                    underflow;
    wire [ADDR_W:0]        word_count;

    // Tracking variables
    integer                 errors;
    integer                 test_num;
    integer                 i;

    //=========================================================================
    // DUT instantiation (Quartus 9.1 style)
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
    task apply_reset;
        begin
            rst_n   = 1'b0;
            wr_en   = 1'b0;
            rd_en   = 1'b0;
            wr_data = 0;
            repeat(3) @(posedge clk);
            rst_n   = 1'b1;
            @(posedge clk);
        end
    endtask

    //=========================================================================
    // Task: write_one
    //=========================================================================
    task write_one;
        input [DATA_W-1:0] data;
        begin
            @(posedge clk);
            wr_en   = 1'b1;
            wr_data = data;
            @(posedge clk);
            wr_en   = 1'b0;
        end
    endtask

    //=========================================================================
    // Task: read_one
    //=========================================================================
    task read_one;
        begin
            @(posedge clk);
            rd_en = 1'b1;
            @(posedge clk);
            rd_en = 1'b0;
        end
    endtask

    //=========================================================================
    // Main test sequence
    //=========================================================================
    initial begin
        errors   = 0;
        test_num = 0;

        // ============================================================
        // TEST 1: Reset behavior
        // ============================================================
        test_num = 1;
        $display("--------------------------------------------------");
        $display("TEST %0d: Reset behavior", test_num);
        apply_reset;
        if (empty !== 1'b1 || full !== 1'b0 || word_count !== 0) begin
            $display("  [FAIL] Reset state incorrect");
            errors = errors + 1;
        end else
            $display("  [PASS] Reset state correct");

        // ============================================================
        // TEST 2: Write until full
        // ============================================================
        test_num = 2;
        $display("--------------------------------------------------");
        $display("TEST %0d: Fill FIFO to full", test_num);
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_one(i);
        end
        @(posedge clk);
        if (full !== 1'b1) begin
            $display("  [FAIL] FIFO not full after %0d writes", FIFO_DEPTH);
            errors = errors + 1;
        end else
            $display("  [PASS] FIFO full flag asserted, count=%0d", word_count);

        // ============================================================
        // TEST 3: Overflow attempt
        // ============================================================
        test_num = 3;
        $display("--------------------------------------------------");
        $display("TEST %0d: Overflow detection", test_num);
        write_one(8'hFF);
        @(posedge clk);
        if (overflow !== 1'b1) begin
            $display("  [FAIL] Overflow not detected");
            errors = errors + 1;
        end else
            $display("  [PASS] Overflow detected");

        // ============================================================
        // TEST 4: Read until empty
        // ============================================================
        test_num = 4;
        $display("--------------------------------------------------");
        $display("TEST %0d: Drain FIFO to empty", test_num);
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            read_one;
        end
        @(posedge clk);
        @(posedge clk);
        if (empty !== 1'b1) begin
            $display("  [FAIL] FIFO not empty after reads");
            errors = errors + 1;
        end else
            $display("  [PASS] FIFO empty flag asserted, count=%0d", word_count);

        // ============================================================
        // TEST 5: Underflow attempt
        // ============================================================
        test_num = 5;
        $display("--------------------------------------------------");
        $display("TEST %0d: Underflow detection", test_num);
        read_one;
        @(posedge clk);
        if (underflow !== 1'b1) begin
            $display("  [FAIL] Underflow not detected");
            errors = errors + 1;
        end else
            $display("  [PASS] Underflow detected");

        // ============================================================
        // TEST 6: Simultaneous read and write
        // ============================================================
        test_num = 6;
        $display("--------------------------------------------------");
        $display("TEST %0d: Simultaneous read and write", test_num);
        apply_reset;
        // Pre-fill with 4 items
        for (i = 0; i < 4; i = i + 1)
            write_one(i);
        // Simultaneous R/W for 8 cycles
        @(posedge clk);
        for (i = 0; i < 8; i = i + 1) begin
            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = (i + 100);
            @(posedge clk);
        end
        wr_en = 1'b0;
        rd_en = 1'b0;
        @(posedge clk);
        if (word_count == 4)
            $display("  [PASS] Word count stable at %0d during R/W", word_count);
        else begin
            $display("  [FAIL] Word count = %0d, expected 4", word_count);
            errors = errors + 1;
        end

        // ============================================================
        // TEST 7: Almost full / almost empty flags
        // ============================================================
        test_num = 7;
        $display("--------------------------------------------------");
        $display("TEST %0d: Almost full and almost empty flags", test_num);
        apply_reset;
        // Write 3 items — check almost_empty
        for (i = 0; i < 3; i = i + 1)
            write_one(i);
        @(posedge clk);
        if (almost_empty !== 1'b1) begin
            $display("  [FAIL] Almost empty not asserted at count=%0d", word_count);
            errors = errors + 1;
        end else
            $display("  [PASS] Almost empty asserted at count=%0d", word_count);

        // Fill to DEPTH-3 — check almost_full
        for (i = 3; i < (FIFO_DEPTH - 3); i = i + 1)
            write_one(i);
        @(posedge clk);
        if (almost_full !== 1'b1) begin
            $display("  [FAIL] Almost full not asserted at count=%0d", word_count);
            errors = errors + 1;
        end else
            $display("  [PASS] Almost full asserted at count=%0d", word_count);

        // ============================================================
        // FINAL RESULTS
        // ============================================================
        $display("==================================================");
        if (errors == 0)
            $display("  ALL %0d TESTS PASSED!", test_num);
        else
            $display("  FAILURES: %0d out of %0d tests", errors, test_num);
        $display("==================================================");

        #100;
        $stop;
    end

endmodule
