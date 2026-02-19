# VCS Filelist for AHB2APB Bridge Class-based Testbench

# RTL Files (local rtl directory)
./rtl/AHB_Slave_Interface.sv
./rtl/APB_FSM_Controller.sv
./rtl/CDC_Handler.sv
./rtl/Bridge_Top.sv

# Testbench Files (in order of dependency)
./CLASS_TB/intf.sv
./CLASS_TB/txn.sv
./CLASS_TB/generator.sv
./CLASS_TB/driver.sv
./CLASS_TB/monitor.sv
./CLASS_TB/apb_slave.sv
./CLASS_TB/scoreboard.sv
./CLASS_TB/environment.sv
./CLASS_TB/test.sv

# Coverage Files
./CLASS_TB/coverage.sv
./CLASS_TB/coverage_bind.sv

# Top-level
./CLASS_TB/class_top.sv
