#!/bin/bash
iverilog -g2012 -o a.out fp32_int32_converter.sv fp32_int32_converter_tb.sv "$@" && vvp ./a.out