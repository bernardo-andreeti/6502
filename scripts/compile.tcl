# TCL ModelSim compile script
# Pay attention on the compilation order!!! (Botton up)



# Sets the compiler
#set compiler vlog
set compiler vcom


# Creats the work library if it does not exist
if { ![file exist work] } {
	vlib work
	vmap work work
}




#########################
### Source files list ###
#########################

# Source files listed in hierarchical order: botton -> top
set sourceFiles {
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/P6502_pkg.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/FlipFlopD_sr.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/RegisterNbits.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/ALU.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/DataPath.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/ControlPath.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502/P6502.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/Util_package.vhd    
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/Memory.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/DisplayCtrl.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502_RAM.vhd
    c:/Users/Bernardo/Documents/GitHub/6502/VHDL/P6502_RAM_tb.vhd
}



set testBench P6502_RAM_tb	



###################
### Compilation ###
###################

if { [llength $sourceFiles] > 0 } {
	
	foreach file $sourceFiles {
		if [ catch {$compiler $file} ] {
			puts "\n*** ERROR compiling file $file :( ***" 
			return;
		}
	}
}




################################
### Lists the compiled files ###
################################

if { [llength $sourceFiles] > 0 } {
	
	puts "\n*** Compiled files:"  
	
	foreach file $sourceFiles {
		puts \t$file
	}
}


puts "\n*** Compilation OK ;) ***"

#vsim $testBench
#set StdArithNoWarnings 1

