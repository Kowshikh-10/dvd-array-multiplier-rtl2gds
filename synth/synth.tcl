# SKY130 timing library
set lib "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# 1. Read RTL
yosys read_verilog rtl/full_adder.v rtl/mult_array.v

# 2. Synthesize and flatten the design
yosys synth -top mult_array -flatten

# 3. Map flip-flops to SKY130 cells
yosys dfflibmap -liberty $lib

# 4. Map combinational logic to SKY130 cells
yosys abc -liberty $lib

# 5. Clean unused logic
yosys opt_clean -purge

# 6. Generate cell statistics and area report
yosys tee -o synth/mult_array_stat.rpt stat -liberty $lib

# 7. Write the gate-level netlist
yosys write_verilog -noattr synth/mult_array_netlist.v