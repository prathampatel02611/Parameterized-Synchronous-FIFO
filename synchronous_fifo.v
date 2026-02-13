//=============================================================================
// Module: synchronous_fifo
// Description: Parameterized synchronous FIFO with status flags
// Author: Pratham Patel P
//=============================================================================

module synchronous_fifo (
    clk,
    rst_n,
    wr_en,
    wr_data,
    rd_en,
    rd_data,
    full,
    empty,
    almost_full,
    almost_empty,
    overflow,
    underflow,
    word_count
);

    //=========================================================================
    // Parameters
    //=========================================================================
    parameter DATA_W              = 8;
    parameter ADDR_W              = 4;
    parameter FIFO_DEPTH          = 16;   // must equal 2**ADDR_W
    parameter ALMOST_FULL_OFFSET  = 3;
    parameter ALMOST_EMPTY_OFFSET = 3;

    //=========================================================================
    // Port declarations
    //=========================================================================
    input  wire                 clk;
    input  wire                 rst_n;

    // Write interface
    input  wire                 wr_en;
    input  wire [DATA_W-1:0]   wr_data;

    // Read interface
    input  wire                 rd_en;
    output wire [DATA_W-1:0]   rd_data;

    // Status flags
    output wire                 full;
    output wire                 empty;
    output wire                 almost_full;
    output wire                 almost_empty;
    output reg                  overflow;
    output reg                  underflow;
    output reg  [ADDR_W:0]     word_count;

    //=========================================================================
    // Internal signals
    //=========================================================================
    reg  [ADDR_W-1:0]  wr_ptr;
    reg  [ADDR_W-1:0]  rd_ptr;
    wire               wr_valid;
    wire               rd_valid;

    //=========================================================================
    // Flag generation
    //=========================================================================
    assign empty        = (word_count == 0);
    assign full         = (word_count == FIFO_DEPTH);
    assign almost_empty = (word_count <= ALMOST_EMPTY_OFFSET) && (word_count > 0);
    assign almost_full  = (word_count >= (FIFO_DEPTH - ALMOST_FULL_OFFSET)) 
                          && (word_count < FIFO_DEPTH);

    // Valid transaction qualifiers
    assign wr_valid = wr_en & (~full);
    assign rd_valid = rd_en & (~empty);

    //=========================================================================
    // RAM instantiation
    //=========================================================================
    ram u_ram (
        .clk    (clk),
        .we     (wr_valid),
        .w_addr (wr_ptr),
        .w_data (wr_data),
        .r_addr (rd_ptr),
        .r_data (rd_data)
    );

    // Override RAM parameters
    defparam u_ram.DATA_W     = DATA_W;
    defparam u_ram.ADDR_W     = ADDR_W;
    defparam u_ram.FIFO_DEPTH = FIFO_DEPTH;

    //=========================================================================
    // Write pointer
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_valid)
            wr_ptr <= wr_ptr + 1'b1;
    end

    //=========================================================================
    // Read pointer
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 0;
        else if (rd_valid)
            rd_ptr <= rd_ptr + 1'b1;
    end

    //=========================================================================
    // Word count tracker
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            word_count <= 0;
        else begin
            if (wr_valid && !rd_valid)
                word_count <= word_count + 1'b1;
            else if (rd_valid && !wr_valid)
                word_count <= word_count - 1'b1;
            // simultaneous read/write: count stays same
        end
    end

    //=========================================================================
    // Overflow flag — write attempted when full
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            overflow <= 1'b0;
        else if (wr_en && full)
            overflow <= 1'b1;
        else
            overflow <= 1'b0;
    end

    //=========================================================================
    // Underflow flag — read attempted when empty
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            underflow <= 1'b0;
        else if (rd_en && empty)
            underflow <= 1'b1;
        else
            underflow <= 1'b0;
    end

endmodule
