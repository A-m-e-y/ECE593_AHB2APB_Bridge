#!/bin/bash
# VCS Compilation and Simulation Script for AHB2APB Bridge

# Clean previous compilation
rm -rf csrc simv* *.log *.vpd ucli.key

# Compile with VCS
vcs -sverilog \
    -full64 \
    -timescale=1ns/1ps \
    -debug_access+all \
    -l compile.log \
    -f filelist.f \
    +v2k \
    -LDFLAGS -Wl,--no-as-needed

# Check compilation status
if [ $? -eq 0 ]; then
    echo "==============================================="
    echo "  Compilation Successful"
    echo "==============================================="
    
    # Run simulation
    ./simv -l simulation.log +vcs+finish+100000
    
    # Check simulation status
    if [ $? -eq 0 ]; then
        echo "==============================================="
        echo "  Simulation Completed Successfully"
        echo "==============================================="
    else
        echo "==============================================="
        echo "  Simulation Failed - Check simulation.log"
        echo "==============================================="
    fi
else
    echo "==============================================="
    echo "  Compilation Failed - Check compile.log"
    echo "==============================================="
fi
