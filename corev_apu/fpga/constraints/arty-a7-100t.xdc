// CVA6 — Digilent Arty A7-100T constraints (xc7a100tcsg324-1)
//
// Port names follow ariane_xilinx.sv / the nexys_video.xdc convention.
// Pin assignments come from:
//   - Digilent Arty-A7-100T Master XDC
//   - ibex-demo-system/data/pins_artya7.xdc (same part, same FT2232 JTAG)
//
// The Arty has no Ethernet PHY or SD slot: those ports are unconnected here;
// ariane_xilinx.sv will need board gating on the arty build (see docs).

## Single-ended 100 MHz clock (E3), CMOS33
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { sys_clk_i }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { sys_clk_i }];

## Reset button: BTN0 (D9). Arty user buttons are active HIGH (low at rest);
## the design inverts it for the MIG's active-low sys_rst. (The dedicated RESET
## button on C2 is not usable here: C2 is in bank 35, shared with the clock and
## the DDR IO bank group.)
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }];

## JTAG: on the Arty the debug TAP lives inside the FPGA (dmi_bscane_tap.sv +
## BSCANE2), tapped from the FT2232 configuration chain. The common
## tck/tms/tdi/tdo ports are unused on this board (the BSCANE2 TAP ignores
## them) and stay unconstrained; trst_n is tied high in the RTL.

## LEDs (H5, J5, T9, T10) + RGB LEDs spare
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## Switches (A8, C11, C10, A10)
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## USB-UART (FT2232H channel B): D10 uart_rxd_out (FPGA tx), A9 uart_txd_in (FPGA rx)
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { tx }];
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { rx }];

## DDR3: all DDR3 pin locations come from the MIG project (mig_arty_a7_100t.prj)

## Unconstrained-pin policy: the Arty build intentionally leaves the Ethernet,
## fan, external-JTAG and prog-* ports of ariane_xilinx.sv floating (no PHY /
## no FAN header on this board). Demote the corresponding DRCs until those
## ports get cut at the top level.
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]


