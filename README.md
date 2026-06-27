# OctaCoreX: 8-Bit RISC Microcontroller

## Overview

OctaCoreX is a fully synthesizable, MIPS-style 5-stage pipelined 8-bit RISC processor written in VHDL-2008. The architecture is designed to handle true data dependencies and control flow dynamically, featuring internal register forwarding, active hazard detection, and stall/flush logic.

---

## Core Architecture

The processor implements a classic 5-stage execution pipeline:

* **IF (Instruction Fetch):**
  Manages the Program Counter (PC) to fetch 16-bit instructions sequentially or dynamically update the PC during branch executions.

* **ID (Instruction Decode):**
  Decodes the 4-bit Opcode, manages the Register File, and implements write-through internal forwarding to mitigate Read-After-Write (RAW) data hazards.

* **EX (Execute):**
  Houses the 8-bit ALU for arithmetic/logical operations and evaluates zero-flag conditions for conditional branching.

* **MEM (Memory):**
  Interacts with the Data RAM using asynchronous reads, ensuring data availability on the bus without requiring supplementary clock cycles.

* **WB (Write-Back):**
  Finalizes the execution by committing ALU results or memory loads back to the Register File.

---

### Hazard Management

* **Data Hazards:**
  The Hazard Unit actively monitors register dependencies. Upon detecting a RAW hazard that cannot be resolved via forwarding (e.g., Load-to-Use), it stalls the IF and ID stages and injects NOP (No Operation) bubbles into the EX stage.

* **Control Hazards:**
  During a branch evaluation (e.g., `JZ`), the pipeline may eagerly fetch subsequent instructions. If the branch is taken, the Hazard Unit immediately flushes these "ghost" instructions by overwriting them with NOPs and updates the PC to the correct target.

---

## Instruction Set Architecture (ISA)

OctaCoreX utilizes a 16-bit instruction word format:

```
[Opcode:4] [Dest_Reg:4] [Source_Reg/Immediate:8]
```

| Category       | Instruction | Opcode (Hex) | Opcode (Bin) | Description                              |
| -------------- | ----------- | ------------ | ------------ | ---------------------------------------- |
| **Control**    | `NOP`       | `0`          | `0000`       | No Operation (Used for pipeline bubbles) |
| **Memory**     | `LDI`       | `1`          | `0001`       | Load Immediate to Register               |
|                | `LDR`       | `2`          | `0010`       | Load from Data RAM to Register           |
|                | `STR`       | `3`          | `0011`       | Store from Register to Data RAM          |
| **Arithmetic** | `ADD`       | `4`          | `0100`       | Add Register to Register                 |
|                | `ADDI`      | `5`          | `0101`       | Add Immediate to Register                |
|                | `SUB`       | `6`          | `0110`       | Subtract Register from Register          |
|                | `SUBI`      | `7`          | `0111`       | Subtract Immediate from Register         |
|                | `CMP`       | `8`          | `1000`       | Compare (Sets Zero Flag, no write-back)  |
| **Logical**    | `AND`       | `9`          | `1001`       | Bitwise AND                              |
|                | `OR`        | `A`          | `1010`       | Bitwise OR                               |
|                | `XOR`       | `B`          | `1011`       | Bitwise XOR                              |
|                | `SHL`       | `C`          | `1100`       | Logical Shift Left                       |
|                | `SHR`       | `D`          | `1101`       | Logical Shift Right                      |
| **Branching**  | `JMP`       | `E`          | `1110`       | Unconditional Jump to Address            |
|                | `JZ`        | `F`          | `1111`       | Jump IF Zero Flag = 1                    |

---

## Project Structure

```
OctaCoreX-8BIT-Microcontroller/
├── scripts/
│   └── run_sim.sh           # Simulation execution script
├── src/
│   ├── alu_8bit.vhd         # 8-bit Arithmetic Logic Unit
│   ├── control_unit.vhd     # Main Pipeline Control
│   ├── core_pkg.vhd         # Global constants and ISA definitions
│   ├── data_ram.vhd         # Asynchronous Read Memory
│   ├── hazard_unit.vhd      # Stall and Flush Logic
│   ├── reg_file.vhd         # 16-entry General Purpose Register File
│   └── risc_core_top.vhd    # Top-Level Motherboard (Pipeline Registers)
└── tb/
    └── tb_risc_core.vhd     # Exhaustive Self-Checking Testbench
```

---

## Prerequisites & Environment Setup

### macOS Setup

Install the GHDL compiler using Homebrew:

```bash
brew install ghdl
```

Install VS Code along with the WaveTrace extension
(or install GTKWave via Homebrew):

```bash
brew install --cask gtkwave
```

---

### Windows Setup

#### Option A (MSYS2)

Install MSYS2, open the UCRT64 terminal, and run:

```bash
pacman -S mingw-w64-x86_64-ghdl
```

#### Option B (WSL)

Install Windows Subsystem for Linux (Ubuntu), then run:

```bash
sudo apt update && sudo apt install ghdl
```

Install GTKWave to view generated waveforms.

---

## Quick Start & Simulation

Make the simulation script executable:

```bash
chmod +x scripts/run_sim.sh
```

Run the automated testbench:

```bash
./scripts/run_sim.sh
```

---

### Expected Output

The self-checking testbench will:

* Compile the VHDL source
* Execute the hardcoded assembly program
* Halt automatically upon detecting the correct result

You should see:

```
[PASS] OctaCoreX Exhaustive Verification Successful!
```

---

### Waveform Viewing

The simulation generates a waveform file:

```
sim/wave_core.vcd
```

Open it using:

* VS Code (WaveTrace extension), or
* GTKWave

to visually inspect:

* Pipeline stages
* Hazard stalls
* Branch flush behavior

---

## Testbench Verification Details

The provided `tb_risc_core.vhd` is a self-checking verification environment.

It loads a purpose-built assembly program into Instruction ROM that intentionally triggers:

* **Read-After-Write (RAW) Hazards**
  → Validates stall logic and pipeline bubble injection

* **Compare + Branch Sequences (`CMP → JZ`)**
  → Verifies zero-flag propagation and ghost instruction flushing

* **Memory Operations (Read/Write)**
  → Ensures data integrity and address stability in Data RAM

---