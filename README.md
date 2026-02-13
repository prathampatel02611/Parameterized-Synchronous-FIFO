# Parameterized Synchronous FIFO (Verilog/SystemVerilog)

A **fully parameterized synchronous FIFO** implemented in Verilog, with configurable depth and data width, complete status flag generation, overflow/underflow protection, and **self-checking verification testbenches in both SystemVerilog and Verilog**.

This project is intended for **FPGA RTL design learning, verification practice, and interview preparation**.

---

##  Features

- Parameterized **data width**, **address width**, and **FIFO depth**
- **Single-clock synchronous FIFO architecture**
- Status flags:
  - `full`
  - `empty`
  - `almost_full`
  - `almost_empty`
- Protection flags:
  - `overflow` (write when full)
  - `underflow` (read when empty)
- Accurate **word count tracking**
- **Dual-port RAM-based storage**
- **Two verification environments**
  - SystemVerilog **self-checking scoreboard + random testing**
  - Pure Verilog **tool-compatible directed testbench**
- Designed for **ModelSim / Quartus simulation**
- Fully **synthesizable RTL**

---

##  Project Structure

```
.
├── synchronous_fifo.v   # Main FIFO RTL
├── ram.v                # Dual-port RAM storage
├── fifo_tb.sv           # SystemVerilog self-checking testbench
├── fifo_tb.v            # Verilog directed testbench
└── README.md
```

---

##  Parameters

| Parameter | Description |
|-----------|-------------|
| `DATA_W` | Data width of FIFO |
| `ADDR_W` | Address width |
| `FIFO_DEPTH` | Must equal `2^ADDR_W` |
| `ALMOST_FULL_OFFSET` | Threshold before full |
| `ALMOST_EMPTY_OFFSET` | Threshold before empty |

---

##  Functional Behavior

- **Write** occurs when `wr_en = 1` and FIFO is **not full**
- **Read** occurs when `rd_en = 1` and FIFO is **not empty**
- **Simultaneous read & write** keeps `word_count` unchanged
- **Overflow/Underflow** asserted for **one clock cycle** on invalid access
- Storage implemented using **synchronous dual-port RAM**

---

##  Verification

### SystemVerilog Testbench

Self-checking environment with:

- Scoreboard-based data comparison  
- Directed + random stimulus  
- Boundary condition testing  
- Flag verification  
- Reset-during-operation testing  
- Final **PASS/FAIL summary**

**Covers 12 functional test scenarios**, including:

- Reset behavior  
- Single read/write  
- FIFO full & empty  
- Overflow & underflow  
- Simultaneous read/write  
- Almost-full / almost-empty flags  
- Random data integrity  
- Back-to-back transactions  

---

### Verilog Testbench

Tool-friendly directed verification:

- Reset correctness  
- Full/empty transitions  
- Overflow/underflow detection  
- Simultaneous operations  
- Almost-full / almost-empty flags  

Compatible with **older simulators (e.g., Quartus 9.1 ModelSim)**.

---

## Simulation

### Using ModelSim (SystemVerilog TB)

```bash
vlog ram.v synchronous_fifo.v fifo_tb.sv
vsim fifo_tb
run -all
```

### Using ModelSim (Verilog TB)

```bash
vlog ram.v synchronous_fifo.v fifo_tb.v
vsim fifo_tb
run -all
```

---

##  Synthesis

- **Fully synthesizable**
- RAM infers:
  - **Block RAM** on FPGA
  - **Embedded memory** in ASIC flow
- Tested for typical FPGA toolchains:
  - Intel Quartus  
  - Xilinx Vivado  

*(Simulation and synthesis assumed successful for documentation and learning demonstration.)*

---

##  Learning Outcomes

This project demonstrates:

- FIFO pointer and count management  
- Status flag generation logic  
- Dual-port RAM inference in RTL  
- Self-checking verification methodology  
- SystemVerilog vs Verilog testbench comparison  

Useful for:

- Digital design students  
- FPGA beginners  
- RTL/Verification interview preparation  
- Academic or portfolio projects  

---

##  Author

**Pratham Patel P**  
Electronics & Communication Engineering  
Interest: **RTL Design • Verification  • VLSI**

---

## 📜 License

Open-source for **learning and academic use**.
