#!/bin/bash

FILE="vcs.log"

if [ -f "$FILE" ]; then
    rm -rf "$FILE"
fi

touch "$FILE"

vcs -sverilog TRAD_TB/tb_sanity_check.sv -f rtl_files.list |& tee -a $FILE
./simv |& tee -a $FILE

