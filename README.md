# dvd-array-multiplier-rtl2gds
Digital VLSI Design assignment: a 4-bit array multiplier (16 AND gates, 12 full adders, registered I/O) verified exhaustively, synthesized with Yosys, timed with OpenSTA, and placed and routed to GDSII on SkyWater 130 nm with LibreLane.

## Team Members

- Student 1: Gunda Yaswanth Vardhan — 2024102012 (Parts B and C)
- Student 2: R.Krs Kowshikh Reddy — 2024102053 (Parts A and D)

## Environment

Parts B, C and D use the tools and SKY130A PDK in the IIC-OSIC-TOOLS Docker image. On Ubuntu, the container was started with the repository mounted at `/foss/designs`:

```bash
docker run --rm -it --user $(id -u):$(id -g) -e PDK=sky130A -v ~/Documents/DVD_Assignment:/foss/designs hpretl/iic-osic-tools:2026.09 -s /bin/bash
```

Parts B and C were run from Windows with `docker exec` into the IIC-OSIC-TOOLS VNC container, as shown in those sections.

## Part A — RTL Design and Verification

### Simulation

Commands executed on the Ubuntu host from the repository root (Icarus Verilog 12.0):

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Result:

`PASS: 256 vectors checked, 0 errors`

### Worked example (task 5)

A = 8 (last digit of R.Krs Kowshikh Reddy's roll number 2024102053, plus 5) and B = 7, so A × B = 56. In the waveform `b` changes to 7 at 2720 ns, the input registers capture it at 2725 ns (edge 1), and `p` becomes 56 at 2735 ns (edge 2): a latency of 2 clock cycles.

### Error test (task 6)

`sum` in `rtl/full_adder.v` was temporarily changed to `a ^ b`, the simulation was run again, and the change was then undone:

```bash
sed -i 's/assign sum = a ^ b ^ cin;/assign sum = a ^ b;/' rtl/full_adder.v
grep "assign sum" rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim | tail -6
git restore rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result with the broken adder:

`FAIL: 256 vectors checked, 95 errors`

After `git restore`, the simulation printed `PASS: 256 vectors checked, 0 errors` again.

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

OpenSTA reported a worst setup slack of 7.05 ns (7.046 ns in the 3-digit timing report). The minimum clock period was calculated as 10 − 7.046 = 2.954 ns, rounded to 2.95 ns, and the maximum operating frequency as 1000 / 2.95 = 338.98 MHz.

Next, `set T 2.95` was used in `sta/sta.tcl`, and the same command was executed again.

OpenSTA reported a worst setup slack of -0.004 ns, which is close to 0. It is slightly negative because 2.954 ns was rounded down to 2.95 ns.

The critical path runs from the input register `a_reg[2]` (flip-flop `_106_`) to the output register `p[7]` (flip-flop `_103_`), through 8 logic cells. The first path in the report (`rst_n` to `_096_`) is the asynchronous reset recovery check, not the critical path.

Generated file:
- `sta/mult_array_timing.rpt`

## Part D — Physical Design (RTL to GDSII)

### Configuration and runs

Commands executed inside the IIC-OSIC-TOOLS container (started as in [Environment](#environment)). The starting clock period was 1.2 × Tmin = 1.2 × 2.95 = 3.54 ns, rounded up to the next 0.5 ns = 4.0 ns:

```bash
cd /foss/designs/pnr
cat > config.json <<'EOF'
{
    "DESIGN_NAME": "mult_array",
    "VERILOG_FILES": ["dir::../rtl/full_adder.v", "dir::../rtl/mult_array.v"],
    "CLOCK_PORT": "clk",
    "CLOCK_PERIOD": 4.0,
    "FP_SIZING": "absolute",
    "DIE_AREA": [0, 0, 150, 150]
}
EOF
librelane config.json
```

Each run that failed timing was repeated with CLOCK_PERIOD increased by 0.5 ns, using 4.5, 5.0, 5.5 and then 6.0 in place of `<period>`:

```bash
sed -i 's/"CLOCK_PERIOD": [0-9.]*/"CLOCK_PERIOD": <period>/' config.json
grep CLOCK_PERIOD config.json
librelane config.json
```

After each run, the result was checked with:

```bash
grep -E '"(timing__setup__ws|magic__drc_error__count|klayout__drc_error__count|design__lvs_error__count)"' runs/$(ls runs | tail -1)/final/metrics.json
```

### Attempts

| Run | CLOCK_PERIOD (ns) | Run folder | Setup slack (ns) | DRC | LVS | Result |
|---|---|---|---|---|---|---|
| 1 | 4.0 | `RUN_2026-10-24_12-09-18` | −1.706 | 0 | 0 | Fail (setup) |
| 2 | 4.5 | `RUN_2026-10-24_12-21-10` | −1.206 | 0 | 0 | Fail (setup) |
| 3 | 5.0 | `RUN_2026-10-24_12-27-41` | −0.706 | 0 | 0 | Fail (setup) |
| 4 | 5.5 | `RUN_2026-10-24_12-29-37` | −0.206 | 0 | 0 | Fail (setup) |
| 5 | 6.0 | `RUN_2026-10-24_12-33-27` | +0.034 | 0 | 0 | Pass |

Runs 1–4 failed only on setup timing in the slow corner `ss_100C_1v60` (100 °C, 1.60 V); DRC and LVS were clean every time. Run folder names use the container's clock.

### Final files

Commands executed inside the container after run 5:

```bash
R=runs/$(ls runs | tail -1)
cp $R/final/metrics.json metrics.json
cp $R/final/gds/mult_array.gds mult_array.gds
grep -E '"(design__instance__count|design__core__area|route__wirelength|timing__setup__ws|magic__drc_error__count|klayout__drc_error__count|route__drc_errors|design__lvs_error__count)"' metrics.json
grep '"design__instance__count__class' metrics.json
exit
```

Result: 1895 cells, core area 17759.5 µm², wirelength 2398 µm, setup slack +0.034 ns, 0 DRC errors, 0 LVS errors. Post-route Fmax = 1000 / (6.0 − 0.034) = 167.6 MHz.

Generated files:
- `pnr/config.json`
- `pnr/metrics.json`
- `pnr/mult_array.gds`

### Layout screenshots

The SKY130 KLayout layer colours were copied out of the container once, then the GDS was opened in KLayout on the Ubuntu host:

```bash
docker run --rm --user $(id -u):$(id -g) -v ~/tools:/out hpretl/iic-osic-tools:2026.09 -s bash -c 'cp $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyp /out/'
klayout -l ~/tools/sky130A.lyp ~/Documents/DVD_Assignment/pnr/mult_array.gds
```