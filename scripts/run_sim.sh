#!/bin/bash

# ==========================================
# OctaCoreX Simulation Automation Script
# ==========================================

echo "=========================================="
echo " Starting OctaCoreX Compilation..."
echo "=========================================="

# 1. Compile Core Modules (Order matters: Package first, then components, then top)
ghdl -a --std=08 src/core_pkg.vhd
ghdl -a --std=08 src/alu_8bit.vhd
ghdl -a --std=08 src/reg_file.vhd
ghdl -a --std=08 src/data_ram.vhd
ghdl -a --std=08 src/control_unit.vhd
ghdl -a --std=08 src/hazard_unit.vhd
ghdl -a --std=08 src/risc_core_top.vhd

# 2. Compile Testbench
ghdl -a --std=08 tb/tb_risc_core.vhd

# 3. Elaborate Top-Level Entity
ghdl -e --std=08 tb_risc_core

# 4. Execute Simulation and Generate Waveform
# (Dumps the VCD into the ignored sim/ folder)
echo " Running Simulation..."
ghdl -r --std=08 tb_risc_core --vcd=sim/wave_core.vcd --stop-time=300ns

echo "=========================================="
echo " Simulation Complete! Open sim/wave_core.vcd in VS Code."
echo "=========================================="