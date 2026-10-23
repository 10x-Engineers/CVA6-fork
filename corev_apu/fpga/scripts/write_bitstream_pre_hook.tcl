# Pre-hook for the WRITE_BITSTREAM step: the Arty port-list intentionally
# leaves Ethernet (no PHY), fan, external-JTAG (internal BSCANE2 tap) and
# prog-* ports floating on this board. Demote the corresponding DRCs so the
# bitstream can be produced while those ports are still in the top interface.
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]

# The Arty's config flash (S25FL128S) is programmed over the 4-bit QSPI
# interface -> the bitstream must carry SPI_buswidth = 4 for write_cfgmem.
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
