#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/media/hammond/more_linux/Xilinx/Vitis/2022.1/bin:/media/hammond/more_linux/Xilinx/Vivado/2022.1/ids_lite/ISE/bin/lin64:/media/hammond/more_linux/Xilinx/Vivado/2022.1/bin
else
  PATH=/media/hammond/more_linux/Xilinx/Vitis/2022.1/bin:/media/hammond/more_linux/Xilinx/Vivado/2022.1/ids_lite/ISE/bin/lin64:/media/hammond/more_linux/Xilinx/Vivado/2022.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/hammond/Documents/vivado_projs/tt03-verilog-qtcoreA1/vivado_proj/qtcore_a1_vivado/qtcore_a1_vivado.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log cmod_a7_top.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source cmod_a7_top.tcl
