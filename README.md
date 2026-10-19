# dvd-array-multiplier-rtl2gds
Digital VLSI Design assignment: a 4-bit array multiplier (16 AND gates, 12 full adders, registered I/O) verified exhaustively, synthesized with Yosys, timed with OpenSTA, and placed and routed to GDSII on SkyWater 130 nm with LibreLane.

## Team Members

- Student 1: [Gunda Yaswanth Vardhan] — [2024102012]
- Student 2: [R.Krs Kowshikh Reddy] — [2024102053]

## Part B — Logic Synthesis

### Synthesis

Command executed inside the IIC-OSIC-TOOLS container:

```bash
cd /foss/designs/dvd-array-multiplier-rtl2gds && yosys -c synth/synth.tcl
```

Generated files:
- `synth/mult_array_netlist.v`
- `synth/mult_array_stat.rpt`

### Synthesis Results

| Metric | Value |
|---|---:|
| Total number of cells | 68 |
| Number of flip-flops | 16 |
| Total cell area | 785.7536 µm² |
| Flip-flop area | 400.384 µm² |
| Flip-flop area (% of total) | 50.96% |
| `dfrtp_1` count | 16 |
| `nand2_1` count | 8 |
| `and2_0` count | 6 |
| `xnor2_1` count | 6 |

### Gate-Level Simulation

Command executed from Windows PowerShell:

```powershell
docker exec -w /foss/designs/dvd-array-multiplier-rtl2gds iic-osic-tools_xvnc_uid_1000 bash -lc 'iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=\#1 -o gls tb/tb_mult.v /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v synth/mult_array_netlist.v && vvp gls'
```

Result:

`PASS: 256 vectors checked, 0 errors`