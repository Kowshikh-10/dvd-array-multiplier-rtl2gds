# dvd-array-multiplier-rtl2gds
Digital VLSI Design assignment: a 4-bit array multiplier (16 AND gates, 12 full adders, registered I/O) verified exhaustively, synthesized with Yosys, timed with OpenSTA, and placed and routed to GDSII on SkyWater 130 nm with LibreLane.

## Team Members

- Student 1: [Gunda Yaswanth Vardhan] — [2024102012]
- Student 2: [R.Krs Kowshikh Reddy] — [2024102053]

## Part B — Logic Synthesis

### Synthesis

The RTL design was synthesized using Yosys and mapped to the SKY130 standard-cell library.

Command executed inside the IIC-OSIC-TOOLS container:

```bash
cd /foss/designs/dvd-array-multiplier-rtl2gds && yosys -c synth/synth.tcl
```

Generated files:
- `synth/mult_array_netlist.v`
- `synth/mult_array_stat.rpt`

### Gate-Level Simulation

The synthesized netlist was simulated using the SKY130 standard-cell models to verify that synthesis preserved the design's functionality.

Command executed from the Windows terminal:

```powershell
docker exec -w /foss/designs/dvd-array-multiplier-rtl2gds iic-osic-tools_xvnc_uid_1000 bash -lc 'iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=\#1 -o gls tb/tb_mult.v /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v synth/mult_array_netlist.v && vvp gls'
```

Result:

`PASS: 256 vectors checked, 0 errors`



## Part C — Static Timing Analysis

### Timing Analysis

OpenSTA was used to perform static timing analysis on the synthesized netlist using the SKY130 typical timing corner (`tt_025C_1v80`).

First, `set T 10.0` was used in `sta/sta.tcl`.

Command executed from the Windows terminal:

```powershell
docker exec -w /foss/designs/dvd-array-multiplier-rtl2gds iic-osic-tools_xvnc_uid_1000 bash -lc "sta sta/sta.tcl"
```

OpenSTA reported a worst setup slack of 7.05 ns. The minimum clock period was calculated as 2.95 ns, and the maximum operating frequency was calculated as 338.98 MHz.

Next, `set T 2.95` was used in `sta/sta.tcl`, and the same command was executed again.

OpenSTA reported a worst setup slack of -0.004 ns.

Generated file:
- `sta/mult_array_timing.rpt`