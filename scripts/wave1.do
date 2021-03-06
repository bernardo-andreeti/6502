onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/rst
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/ready
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/duv/P6502/control_path/rdy
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/nmi
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/nres
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/irq
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/duv/clk_div
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/control_path/currentstate
add wave -noupdate -format Logic -radix hexadecimal P6502_RAM_tb/duv/P6502/uins
add wave -noupdate -format Literal P6502_RAM_tb/duv/P6502/control_path/decins
add wave -noupdate -divider Datapath
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/data_in
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/data_out
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/p_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/db
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/sb
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/s_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/pch_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/pcl_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/abh_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/abl_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/address
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/ai_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/bi_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/ac_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/x_q
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/P6502/data_path/y_q
add wave -noupdate -divider RAM
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/RAM/address
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/RAM/data_in
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/RAM/data_out
add wave -noupdate -format Literal -radix hexadecimal P6502_RAM_tb/duv/RAM/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2014 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1797 ns} {2297 ns}
