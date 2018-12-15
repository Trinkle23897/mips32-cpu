#!/bin/bash

cd cpu_testcase/func_test/src
make ver=sim clean
make clean
make ver=sim -j
xxd -c 4 -g 4 -e main.bin | awk '{print $2}' > main.data
cd ../../..
cp cpu_testcase/func_test/src/main.data thinpad_top.srcs/sources_1/new
cp cpu_testcase/func_test/src/main.bin thinpad_top.srcs/sources_1/new
cp cpu_testcase/func_test/src/main.bin bit/5d.bin
