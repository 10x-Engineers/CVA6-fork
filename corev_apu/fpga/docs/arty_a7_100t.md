# CVA6 on the Digilent Arty A7-100T

Board: Digilent Arty A7-100T, Xilinx Artix-7 `xc7a100tcsg324-1`.

```
export BOARD=arty_a7_100t
source corev_apu/fpga/sourceme.sh
make fpga target=cv32a6_imac_sv32
```

`sourceme.sh` exports the part, board part and clock period for the selected
board; `target` selects the CVA6 configuration.

## Memory map (same as the other FPGA boards)

| Region | Address |
|---|---|
| Boot ROM | `0x0001_0000` |
| UART | `0x1000_0000` |
| DDR3 (256 MB) | `0x8000_0000` |

The boot ROM prints `Hello World!` on the FT2232 channel B UART
(`/dev/ttyUSB*`, 57600 baud, 25 MHz core clock) and then waits for a boot
image on that UART. Note that the boot ROM stack lives in DDR
(`startup.S: sp = 0x8400_0000`), so DDR must be calibrated for any code to
run.

## Clocking and reset

```
E3 100 MHz ──► BUFG ──┬──► MIG sys_clk_i          ──► DDR3 pins
                      └──► clk_wiz ──► 25 MHz core clock
                                   └─► 200 MHz MIG clk_ref_i
```

- The MIG is generated with `SystemClock = No Buffer` and
  `ReferenceClock = No Buffer` (see `mig_arty_a7_100t.prj`). With a
  pin-selected system clock the MIG constrains E3 to LVCMOS25, which conflicts
  with the other LVCMOS33 pins in bank 35; driving the clock through a BUFG
  avoids this.
- The MIG reference clock must be 200 MHz for IDELAYCTRL. The Arty has only a
  100 MHz oscillator, so a Clocking Wizard generates it.
- MIG `sys_rst` is active low and is held asserted until the reference clock
  MMCM is locked. BTN0 (D9) is active high and can also force a reset.

## DDR3

The board carries a Micron MT41K128M16 (2 Gb, x16, 1.35 V). The MIG project
file follows Digilent's board-file configuration: tCK 3077 ps, CAS latency 5,
controller chip select enabled (CS on U8), SSTL135 I/O.

## Debug

The FT2232 on the Arty only drives the FPGA configuration JTAG chain; there
are no external JTAG user pins. The debug TAP therefore uses the FPGA's
BSCANE2 primitives (`dmi_bscane_tap.sv` in the `riscv-dbg` submodule,
compiled in place of `dmi_jtag_tap.sv`):

| Chain | IR | Use |
|---|---|---|
| USER3 | `0x22` | DTM control/status |
| USER4 | `0x23` | DMI |

The expected IDCODE is the FPGA's own (`0x13631093`). A matching OpenOCD
configuration uses `jtag newtap riscv.cpu -irlen 6 -expected-id 0x13631093`.

The BSCANE2 TAP is part of `riscv-dbg` upstream (`dmi_bscane_tap.sv`, first
added in commit `b5d1610`). The top-level Makefile compiles it in place of
`dmi_jtag_tap.sv` for `BOARD=arty_a7_100t`; both files are pin-compatible.

## Bring-up status chain (optional)

For headless bring-up, a read-only BSCANE2 USER1 (`IR 0x02`) chain exposes a
status word. Read it with OpenOCD:

```
irscan riscv.cpu 0x02
drscan riscv.cpu 32 0 -endstate RUN/IDLE
```

| Bits | Meaning |
|---|---|
| `[3:0]` | heartbeat counter bits (core clock alive) |
| `[4]` | MIG `init_calib_complete` |
| `[5]` | reference clock MMCM locked |
| `[6]` | MIG `ui_clk_sync_rst` |
| `[7]` | debug `ndmreset` |
| `[15:8]` | free-running counter (changes while the core clock runs) |
| `[19:16]` | `4'h5` alignment magic |
| `[20]` | `init_calib_complete` (duplicate) |
| `[21]` | sticky: the core committed an instruction |
| `[22]` | sticky: a DMI request reached the debug module |
| `[23]` | `dmactive` |
| `[31:24]` | `8'hA5` alignment magic |
