//=============================================================================
// Module: ram
// Description: Simple dual-port RAM for FIFO storage
// Author: Pratham Patel P
//=============================================================================

module ram (
    clk,
    we,
    w_addr,
    w_data,
    r_addr,
    r_data
);

    //=========================================================================
    // Parameters
    //=========================================================================
    parameter DATA_W     = 8;
    parameter ADDR_W     = 4;
    parameter FIFO_DEPTH = 16;

    //=========================================================================
    // Port declarations
    //=========================================================================
    input  wire                 clk;
    input  wire                 we;
    input  wire [ADDR_W-1:0]   w_addr;
    input  wire [DATA_W-1:0]   w_data;
    input  wire [ADDR_W-1:0]   r_addr;
    output reg  [DATA_W-1:0]   r_data;

    //=========================================================================
    // Memory array
    //=========================================================================
    reg [DATA_W-1:0] mem_array [0:FIFO_DEPTH-1];

    // Synchronous write
    always @(posedge clk) begin
        if (we)
            mem_array[w_addr] <= w_data;
    end

    // Synchronous read
    always @(posedge clk) begin
        r_data <= mem_array[r_addr];
    end

endmodule
