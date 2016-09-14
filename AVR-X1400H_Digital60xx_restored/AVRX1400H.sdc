# Clock constraints

#######################################################################################
# PLL Clock Auto Generation
#######################################################################################
#derive_pll_clocks -create_base_clocks
#######################################################################################
# Create Clock / Generate Clock
#######################################################################################
# Crystal Master Clock
create_clock -name DIRXMCK -period 40.69 [get_ports {DIRXMCK}]
#######################################################################################
# Mute CLK
#  Crystal Dividd Mute CLOCK
#create_generated_clock \
	-name MUTEBCK \
	-source [get_ports {DIRXMCK}] \
	-divide_by 2 \
	-invert \
	[get_pins {inst104|m_mck_div[0]|regout}]
#create_generated_clock \
	-name MUTELRCK \
	-source [get_ports {DIRXMCK}] \
	-divide_by 128 \
	-invert \
	[get_pins {104m_mck_div[6]|regout}]

#######################################################################################
# DIR I2S
#  fs=192K
create_clock -name DIRBCK_192K -period 81.38 [get_ports {DIRBCK}]
create_clock -name DIRLRCK_192K -period 5208 [get_ports {DIRLRCK}]
#  fs=96K
#create_clock -name DIRBCK_96K -period 162.76 [get_ports {DIRBCK}] -add
#  fs=48K
#create_clock -name DIRBCK_48K -period 325.52 [get_ports {DIRBCK}] -add
#######################################################################################
# ADC output clocks
#  fs=96K
create_generated_clock -name GEN_PLDADCBCK_96K \
	-source [get_ports {DIRXMCK}] \
	-divide_by 4 \
	-invert \
 [get_pins {inst63|MCKDiv[1]|regout}]

create_generated_clock -name PLDADCBCK_96K \
	-source  [get_pins {inst63|MCKDiv[1]|regout}] \
	-master_clock GEN_PLDADCBCK_96K \
 [get_ports {PLDADCBCK}]

#create_generated_clock -name PLDADCBCK_96K \
	-source  [get_pins {inst63|MCKDiv[1]|regout}] \
	-master_clock MUXED_PLDADCBCK_96K \
 [get_ports {PLDADCBCK}] -add

#create_clock -name PLDADCBCK_96K -period 162.76 [get_ports {PLDADCBCK}]
 
#######################################################################################
# HDMI RX BCK(PCM)
#  fs=192K
create_clock -name HDMIBCK_192K -period 81.38 [get_ports {RXBCK}]
#  fs=96K
#create_clock -name HDMIBCK_96K -period 162.76 [get_ports {RXBCK}] -add
#  fs=48K
#create_clock -name HDMIBCK_48K -period 325.52 [get_ports {RXBCK}] -add

#######################################################################################
# LEGO input
#  fs=192K
create_clock -name LEGOBCK_192K -period 81.38 [get_ports {SCLK_I2S_0}]
#  fs=96K
#create_clock -name LEGOBCK_96K -period 162.76 [get_ports {SCLK_I2S_0}] -add
#  fs=48K
#create_clock -name LEGOBCK_48K -period 325.52 [get_ports {SCLK_I2S_0}] -add
# LEGO DSD input
create_clock -name LEGOBCK_DSD128TDM -period 88.6 [get_ports {SCLK_I2S_1}] -add
create_generated_clock -name LEGOBCK_DSD128 \
	-source [get_ports {SCLK_I2S_1}] \
	-master_clock LEGOBCK_DSD128TDM \
	-divide_by 2 \
	-invert \
 [get_pins {inst79|BitCount[0]|regout}]

create_generated_clock -name LEGOBCK_DSD128_0 \
	-source [get_ports {SCLK_I2S_1}] \
	-master_clock LEGOBCK_DSD128TDM \
	-edges {2 4 6} \
 [get_pins {inst79|TxLatch|regout}]

#create_generated_clock -name LEGOLRCK_DSD128 \
	-source [get_pins {inst79|BitCount[0]|regout}] \
	-master_clock LEGOBCK_DSD128 \
	-divide_by 64 \
	-invert \
 [get_pins {inst134|LEGODIV[5]|regout}]

#######################################################################################
# MUXED DSP1 input clocks
#  Bit Clock
create_generated_clock -name MUXED_DSP1IN_DIRBCK_192K \
	-source [get_ports {DIRBCK}] \
	-master_clock DIRBCK_192K \
	[get_pins {inst190~2|combout}] -add
create_generated_clock -name MUXED_DSP1IN_PLDADCBCK_96K \
	-source [get_ports {PLDADCBCK}] \
	-master_clock PLDADCBCK_96K \
	[get_pins {inst190~2|combout}] -add
create_generated_clock -name MUXED_DSP1IN_HDMIBCK_192K \
	-source [get_ports {RXBCK}] \
	-master_clock HDMIBCK_192K \
	[get_pins {inst190~2|combout}] -add
create_generated_clock -name MUXED_DSP1IN_LEGOBCK_192K \
	-source [get_ports {SCLK_I2S_0}] \
	-master_clock LEGOBCK_192K \
	[get_pins {inst190~2|combout}] -add
create_generated_clock -name MUXED_DSP1IN_LEGOBCK_DSD128 \
	-source [get_pins {inst79|BitCount[0]|regout}] \
	-master_clock LEGOBCK_DSD128 \
	[get_pins {inst190~2|combout}] -add
set_clock_groups -exclusive \
	-group {MUXED_DSP1IN_DIRBCK_192K} \
	-group {MUXED_DSP1IN_PLDADCBCK_96K} \
	-group {MUXED_DSP1IN_HDMIBCK_192K} \
	-group {MUXED_DSP1IN_LEGOBCK_192K} \
	-group {MUXED_DSP1IN_LEGOBCK_DSD128}

#######################################################################################
# DSP1 input clocks
#  Bit Clock
create_generated_clock -name DSP1IN_DIRBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_DIRBCK_192K \
	[get_ports {DSP1INBCK}] -add
create_generated_clock -name DSP1IN_PLDADCBCK_96K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_PLDADCBCK_96K \
	[get_ports {DSP1INBCK}] -add
create_generated_clock -name DSP1IN_HDMIBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_HDMIBCK_192K \
	[get_ports {DSP1INBCK}] -add
create_generated_clock -name DSP1IN_LEGOBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_LEGOBCK_192K \
	[get_ports {DSP1INBCK}] -add
create_generated_clock -name DSP1IN_LEGOBCK_DSD128 \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_LEGOBCK_DSD128 \
	[get_ports {DSP1INBCK}] -add
set_clock_groups -exclusive \
	-group {DSP1IN_DIRBCK_192K} \
	-group {DSP1IN_PLDADCBCK_96K} \
	-group {DSP1IN_HDMIBCK_192K} \
	-group {DSP1IN_LEGOBCK_192K} \
	-group {DSP1IN_LEGOBCK_DSD128}

#######################################################################################
#   DSP1 output clocks
#    fs=192K
create_clock -name DSP1OUTBCK_192K -period 81.38 [get_ports {DSP1OUTBCK}]
create_clock -name DSP1OUTLRCK_192K -period 5208 [get_ports {DSP1OUTLRCK}]

#######################################################################################
# Output Selector Mux
# Bit Clock Mux
create_generated_clock -name MUXED_DACBCK_DSP1OUTBCK_192K \
	-source [get_ports {DSP1OUTBCK}] \
	-master_clock DSP1OUTBCK_192K \
	[get_pins {inst184~1|combout}] -add
create_generated_clock -name MUXED_DACBCK_DIRBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_DIRBCK_192K \
	[get_pins {inst184~1|combout}] -add
create_generated_clock -name MUXED_DACBCK_PLDADCBCK_96K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_PLDADCBCK_96K \
	[get_pins {inst184~1|combout}] -add
create_generated_clock -name MUXED_DACBCK_HDMIBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_HDMIBCK_192K \
	[get_pins {inst184~1|combout}] -add
create_generated_clock -name MUXED_DACBCK_LEGOBCK_192K \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_LEGOBCK_192K \
	[get_pins {inst184~1|combout}] -add
create_generated_clock -name MUXED_DACBCK_LEGOBCK_DSD128 \
	-source [get_pins {inst190~2|combout}] \
	-master_clock MUXED_DSP1IN_LEGOBCK_DSD128 \
	[get_pins {inst184~1|combout}] -add
set_clock_groups -exclusive \
	-group {MUXED_DACBCK_DSP1OUTBCK_192K} \
	-group {MUXED_DACBCK_DIRBCK_192K} \
	-group {MUXED_DACBCK_PLDADCBCK_96K} \
	-group {MUXED_DACBCK_HDMIBCK_192K} \
	-group {MUXED_DACBCK_LEGOBCK_192K} \
	-group {MUXED_DACBCK_LEGOBCK_DSD128}

#######################################################################################
# Output Port
#  DAC Bit Clock
create_generated_clock -name DACBCK_DSP1OUTBCK_192K \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_DSP1OUTBCK_192K \
	[get_ports {DACBCK}] -add
create_generated_clock -name DACBCK_DIRBCK_192K \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_DIRBCK_192K \
	[get_ports {DACBCK}] -add
create_generated_clock -name DACBCK_PLDADCBCK_96K \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_PLDADCBCK_96K \
	[get_ports {DACBCK}] -add
create_generated_clock -name DACBCK_HDMIBCK_192K \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_HDMIBCK_192K \
	[get_ports {DACBCK}] -add
create_generated_clock -name DACBCK_LEGOBCK_192K \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_LEGOBCK_192K \
	[get_ports {DACBCK}] -add
create_generated_clock -name DACBCK_LEGOBCK_DSD128 \
	-source [get_pins {inst184~1|combout}] \
	-master_clock MUXED_DACBCK_LEGOBCK_DSD128 \
	[get_ports {DACBCK}] -add
set_clock_groups -exclusive \
	-group {DACBCK_DSP1OUTBCK_192K} \
	-group {DACBCK_DIRBCK_192K} \
	-group {DACBCK_PLDADCBCK_96K} \
	-group {DACBCK_HDMIBCK_192K} \
	-group {DACBCK_LEGOBCK_192K} \
	-group {DACBCK_LEGOBCK_DSD128}
	
#######################################################################################
#   Z2ADC output clocks
#    fs=48K(static)
create_clock -name Z2ADCBCK_48K -period 325.52 [get_ports {DIRAUXBCK}] -add

create_generated_clock -name NETI2S2IN48K \
	-source [get_ports {DIRAUXBCK}] \
	-master_clock Z2ADCBCK_48K \
	[get_ports {SCLK_I2S_2}] -add

#######################################################################################
# Z2DAC input Port
#  SPDIF Input
#create_generated_clock -name Z2DACBCK_DIRBCK_192K \
	-source [get_ports {Z2DIRBCK}] \
	-master_clock Z2DIRBCK_192K \
	[get_ports {Z2DACBCK}]
#  LEGO Input
create_generated_clock -name Z2DACBCK_LEGOBCK_192K \
	-source [get_ports {SCLK_I2S_0}] \
	-master_clock LEGOBCK_192K \
	[get_ports {Z2DACBCK}] -add
#set_clock_groups -exclusive \
	-group {Z2DACBCK_DIRBCK_192K} \
	-group {Z2DACBCK_LEGOBCK_192K} 
	
#create_clock -name Z2DACBCK_LEGOBCK_192K -period 81.38 [get_ports {SCLK_I2S_0}]

#######################################################################################
#  HDMI Tx Output
#  Bit Clock
create_generated_clock -name TXBCK_192K \
	-source [get_ports {DSP1OUTBCK}] \
	-master_clock DSP1OUTBCK_192K \
	[get_ports {TXBCK}]
#######################################################################################
#   SPI Clock
create_clock -name SPICLK -period 1000 [get_ports {AP_CK}]
create_clock -name SPICS -period 48000 [get_ports {AP_CS}]

#######################################################################################
# Clock Exclusive
#######################################################################################
	
#######################################################################################
# Clock Uncertainty
#######################################################################################
#derive_clock_uncertainty

#######################################################################################
# Set Input Delay
#######################################################################################
# DIR
set_input_delay -clock {DIRBCK_192K} -max 10 [get_ports {DIRLRCK DIRDATA}] -clock_fall -add_delay
set_input_delay -clock {DIRBCK_192K} -min -10 [get_ports {DIRLRCK DIRDATA}] -clock_fall -add_delay
#set_input_delay -clock {DIRLRCK_192K} -max 10 [get_ports {DIRBCK DIRDATA}] -clock_fall -add_delay
#set_input_delay -clock {DIRLRCK_192K} -min -10 [get_ports {DIRBCK DIRDATA}] -clock_fall -add_delay
# ADC
set_input_delay -clock {PLDADCBCK_96K} -max 6 [get_ports {PLDADCDATA}] -clock_fall -add_delay
set_input_delay -clock {PLDADCBCK_96K} -min 0 [get_ports {PLDADCDATA}] -clock_fall -add_delay
# HDMI
set_input_delay -clock {HDMIBCK_192K} -max 10 [get_ports {RXLRCK RXI2S*}] -clock_fall -add_delay
set_input_delay -clock {HDMIBCK_192K} -min -10 [get_ports {RXLRCK RXI2S*}] -clock_fall -add_delay
# LEGO
set_input_delay -clock {LEGOBCK_192K} -max 6 [get_ports {LRCK_I2S_0 SDOUT_I2S_0}] -clock_fall -add_delay
set_input_delay -clock {LEGOBCK_192K} -min 0 [get_ports {LRCK_I2S_0 SDOUT_I2S_0}] -clock_fall -add_delay
set_input_delay -clock {LEGOBCK_DSD128} -max 6 [get_ports {LRCK_I2S_1 SDOUT_I2S_1}] -clock_fall -add_delay
set_input_delay -clock {LEGOBCK_DSD128} -min 0 [get_ports {LRCK_I2S_1 SDOUT_I2S_1}] -clock_fall -add_delay
# DSP1 Output
set_input_delay -clock {DSP1OUTBCK_192K} -max 13.25 [get_ports {DSP1OUTLRCK DSP1OUTCSW1 DSP1OUTF DSP1OUTFH DSP1OUTFW DSP1OUTS DSP1OUTSB}] -clock_fall -add_delay
set_input_delay -clock {DSP1OUTBCK_192K} -min 0.5 [get_ports {DSP1OUTLRCK DSP1OUTCSW1 DSP1OUTF DSP1OUTFH DSP1OUTFW DSP1OUTS DSP1OUTSB}] -clock_fall -add_delay
# Z2ADC
set_input_delay -clock {Z2ADCBCK_48K} -max 10 [get_ports {DIRAUXLRCK DIRAUXDATA}] -clock_fall -add_delay
set_input_delay -clock {Z2ADCBCK_48K} -min -10 [get_ports {DIRAUXLRCK DIRAUXDATA}] -clock_fall -add_delay
# Sub Comm. SPI
set_input_delay -clock {SPICLK} -max 100 [get_ports {AP_DA}] -add_delay
set_input_delay -clock {SPICLK} -min 100 [get_ports {AP_DA}] -add_delay
#set_input_delay -clock {SPICS} -max 100 [get_ports {PLDCS}] -add_delay
#set_input_delay -clock {SPICS} -min 100 [get_ports {PLDCS}] -add_delay

#######################################################################################
# Set Output Delay
#######################################################################################
# DSP
# Specify the maximum setup time of the external device
set tSU_DSP -5
# Specify the minimum setup time of the external device
set tH_DSP 5
# DSP1
#  Source=DIR
set_output_delay -clock {DSP1IN_DIRBCK_192K} -max [expr - $tSU_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
set_output_delay -clock {DSP1IN_DIRBCK_192K} -min [expr - $tH_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
#  Source=ADC
set_output_delay -clock {DSP1IN_PLDADCBCK_96K} -max [expr - $tSU_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
set_output_delay -clock {DSP1IN_PLDADCBCK_96K} -min [expr - $tH_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
#  Source=HDMI(PCM)
set_output_delay -clock {DSP1IN_HDMIBCK_192K} -max [expr - $tSU_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
set_output_delay -clock {DSP1IN_HDMIBCK_192K} -min [expr - $tH_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
#  Source=LEGO(PCM)
set_output_delay -clock {DSP1IN_LEGOBCK_192K} -max [expr - $tSU_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
set_output_delay -clock {DSP1IN_LEGOBCK_192K} -min [expr - $tH_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
#  Source=LEGO(DSD)
set_output_delay -clock {DSP1IN_LEGOBCK_DSD128} -max [expr - $tSU_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay
set_output_delay -clock {DSP1IN_LEGOBCK_DSD128} -min [expr - $tH_DSP] [get_ports {DSP1INLRCK DSP1INF_FL DSP1INRSV_FR DSP1INSB_SR DSP1INSWC_C DSP1INS_SL}] -add_delay

#######################################################################################
# Main DAC
# Specify the maximum setup time of the external device
set tSU_DAC -5
# Specify the minimum setup time of the external device
set tH_DAC 5
#  DSP3 Source
set_output_delay -clock {DACBCK_DSP1OUTBCK_192K} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_DSP1OUTBCK_192K} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
#  DIR Source
set_output_delay -clock {DACBCK_DIRBCK_192K} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_DIRBCK_192K} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
#  ADC Source
set_output_delay -clock {DACBCK_PLDADCBCK_96K} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_PLDADCBCK_96K} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
#  HDMI Source
set_output_delay -clock {DACBCK_HDMIBCK_192K} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_HDMIBCK_192K} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
#  LEGO Source
set_output_delay -clock {DACBCK_LEGOBCK_192K} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_LEGOBCK_192K} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
#  LEGO Source(DSD)
set_output_delay -clock {DACBCK_LEGOBCK_DSD128} -max [expr - $tSU_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay
set_output_delay -clock {DACBCK_LEGOBCK_DSD128} -min [expr - $tH_DAC] [get_ports {DACLRCK DACPCMF DACPCMCSW1 DACPCMS DACPCMSB}] -add_delay

#######################################################################################
# ADC
# Specify the maximum setup time of the external device
set tSU_ADC -65.11
# Specify the minimum setup time of the external device
set tH_ADC 0
# 
set_output_delay -clock {PLDADCBCK_96K} -max  [expr - $tSU_ADC] [get_ports {PLDADCLRCK}] -add_delay
set_output_delay -clock {PLDADCBCK_96K} -min [expr - $tH_ADC] [get_ports {PLDADCLRCK}] -add_delay
#
#set_output_delay -clock {PLDADCBCK_48K} -max  [expr - $tSU_ADC] [get_ports {PLDADCLRCK}] -add_delay
#set_output_delay -clock {PLDADCBCK_48K} -min [expr - $tH_ADC] [get_ports {PLDADCLRCK}] -add_delay
#######################################################################################
# Z2ADC
# Specify the maximum setup time of the external device
set tSU_ZONE2ADC -65.11
# Specify the minimum setup time of the external device
set tH_ZONE2ADC 0
# 
set_output_delay -clock {NETI2S2IN48K} -max  [expr - $tSU_ZONE2ADC] [get_ports {LRCK_I2S_2 SDIN_I2S_2}] -add_delay
set_output_delay -clock {NETI2S2IN48K} -min [expr - $tH_ZONE2ADC] [get_ports {LRCK_I2S_2 SDIN_I2S_2}] -add_delay
#######################################################################################
# Z2DAC
# Specify the maximum setup time of the external device
set tSU_ZONEDAC -8
# Specify the minimum setup time of the external device
set tH_ZONEDAC 8
#  DIR Source
#set_output_delay -clock {Z2DACBCK_DIRBCK_192K} -max [expr - $tSU_ZONEDAC] [get_ports {Z2DACLRCK Z2DACDATA}] -add_delay
#set_output_delay -clock {Z2DACBCK_DIRBCK_192K} -min [expr - $tH_ZONEDAC] [get_ports {Z2DACLRCK Z2DACDATA}] -add_delay
#  LEGO Source
set_output_delay -clock {Z2DACBCK_LEGOBCK_192K} -max [expr - $tSU_ZONEDAC] [get_ports {Z2DACLRCK Z2DACDATA}] -add_delay
set_output_delay -clock {Z2DACBCK_LEGOBCK_192K} -min [expr - $tH_ZONEDAC] [get_ports {Z2DACLRCK Z2DACDATA}] -add_delay

#######################################################################################
# Set False Path
#######################################################################################
# SPI Path
set_false_path -from [get_clocks {SPICS}]
set_false_path -from {inst141|dat_o*}
# Constraint Not Required 
set_false_path -from [get_ports \
 {DIRNPCM DIRPERR \
  DIRXMCK \
  DIRMCK \
  DIRAUXMCK DIRAUXBCK DIRAUXLRCK DIRAUXDATA}]
set_false_path -from {DSP1FLAG3}
set_false_path -to {MPIO_B*}  
# Main DAC
set_false_path -to {DACMCK DACLRCK}
set_false_path -from {DZF1}
# ZONE DAC
set_false_path -to {Z2DACMCK}
set_false_path -from [get_ports {SCLK_I2S_0}] -to [get_ports {Z2DACBCK}]
# HDMI
set_false_path -from {RXMCK}
set_false_path -to {HDMISPDIF}
# LEGO
set_false_path -from {MCLK_I2S_0}
set_false_path -from {GPIO_0}
# Main ADC
set_false_path -to {PLDADCMCK}
# Clock itself
set_false_path -from [get_ports {RXBCK DSP1OUTBCK}] -to [get_ports {TXBCK}]
set_false_path -from [get_ports {DIRLRCK LRCK_I2S_0 RXLRCK DSP1OUTLRCK}] -to [get_ports {TXLRCK}]
set_false_path -from {inst19|dat_o[8]} -to [get_ports {TXLRCK}]
set_false_path -from [get_clocks {DIRLRCK_192K}] -to [get_ports {TXLRCK}]
set_false_path -from [get_ports {RXI2S0 DSP1OUTF}] -to [get_ports {TXI2S0}]
#set_false_path -from [get_ports {*_I2S_0}] -to [get_ports {DIRDSD*}]
set_false_path -from {inst184~1|combout} -to [get_ports {DACBCK}]
set_false_path -from {inst190~2|combout} -to [get_ports {DSP1INBCK}]
#set_false_path -from [get_pins {inst76|LPM_MUX_component|auto_generated|result_node[0]~0|combout}] -to [get_ports {PLDADCBCK}]
#set_false_path -from {inst78|LPM_MUX_component|auto_generated|result_node[2]~2|combout} -to [get_ports {Z2DACBCK}]
#set_false_path -from {inst81|LPM_MUX_component|auto_generated|result_node[2]~2|combout} -to [get_ports {Z3DACBCK}]
#set_false_path -from {DIRLRCK} -to [get_pins {inst29|LPM_FF|lpm_ff_component|dffs[0]}]
set_false_path -from {inst63|MCKDiv[1]|regout} -to [get_ports {PLDADCBCK}]
set_false_path -from {inst63|MCKDiv[2]} -to [get_ports {PLDADCBCK}]
set_false_path -from {inst206|FS96} -to [get_ports {PLDADCBCK}]
set_false_path -from {inst97|lpm_ff_component|dffs[0]} -to [get_ports {DACPC*}]
set_false_path -from {inst25|lpm_ff_component|dffs[0]} -to [get_ports {DACLRCK}]
set_false_path -from {inst29|lpm_ff_component|dffs[0]} -to [get_ports {DACLRCK}]

# DSP3(actually DSP4)
#set_false_path -from [get_ports {SDOUT_I2S_0}] -to {DSP3INRSV1}
# ADC
#set_false_path -from [get_pins {inst63|BCK_out|combout}] -to [get_ports {PLDADCBCK}]
# Fs Counter Output(Async)
#set_false_path -from {inst149|l_cnt*} 
set_false_path -from {LEGOBCK_* DIRBCK_* HDMIBCK_*} -to {DIRXMCK}
# Not Exist Pattern
#set_false_path -from [get_clocks {*DIR* *HDMI* *DSP1* *LEGO* *ADC*}] -to [get_clocks {*MUTE*}]
set_false_path -from [get_clocks {*DIR* *HDMI* *DSP1* *LEGO*}] -to [get_clocks {*ADC*}]
set_false_path -from [get_clocks {*ADC* *DIR* *HDMI* *DSP1*}] -to [get_clocks {*LEGO*}]
set_false_path -from [get_clocks {*LEGO* *ADC* *DIR* *HDMI*}] -to [get_clocks {*DSP1*}]
set_false_path -from [get_clocks {*DSP1* *LEGO* *ADC* *DIR*}] -to [get_clocks {*HDMI*}]
set_false_path -from [get_clocks {*HDMI* *DSP1* *LEGO* *ADC*}] -to [get_clocks {*DIR*}]
set_false_path -from [get_clocks {*_192K* *_96K* *_48K*}] -to [get_clocks {*DSD*}]
set_false_path -from [get_clocks {*DSD*}] -to [get_clocks {*_192K*}]
#set_false_path -from {AIOS4_PWM3}

set_false_path -to [get_clocks {*LEGOBCK_DSD128}]
