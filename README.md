# Parameterized-Synchronous-FIFO

##Overview
A robust, synthesizable Synchronous FIFO implemented in Verilog, featuring a self-checking SystemVerilog testbench. This design uses a dual-port RAM backend and provides comprehensive status monitoring, including programmable thresholds and error detection flags.

##Key Features
Fully Parameterized: Configurable DATA_W, ADDR_W, and FIFO_DEPTH.

Advanced Status Flags: * Standard full and empty indicators.

almost_full and almost_empty thresholds for proactive flow control.

overflow and underflow error pulses for robust debugging.

Word Tracking: Real-time word_count output to monitor buffer occupancy.

Dual-Port RAM Backend: Modular memory architecture for easy technology mapping.


##Architecture
The design consists of three primary components:

synchronous_fifo.v: The top-level controller managing pointers, flags, and flow logic.

ram.v: A simple dual-port synchronous RAM module.

fifo_tb.sv: A comprehensive self-checking testbench using a Queue-based scoreboard.

