# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer

@cocotb.test()
async def test_project(dut):
    dut._log.info("~~~Reconfigureable Ring TEST~~~")
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut._log.info("Testing Bitstream FLIP FLOPS")
    dut._log.info(str(dir(dut.uo_out.value)))

    testpattern = "101100011100001111000001111" + "000000000000000000000000000"
    outpattern = ""
    dut._log.info("Input Test Pattern:"+testpattern)

    for b in range(54):
        bit = testpattern[b]
        dut.ui_in.value = int(bit)
        await ClockCycles(dut.clk, 1)
        #await Timer(10, unit="ns")
        bitout = str(dut.uo_out.value[0])
        outpattern.append(bitout)
        dut._log.info("Input:output " + bit + ":" + bitout)

    dut._log.info("Input Test Pattern:"+outpattern)
    
    testpattern = "100010000000000000000000000"
    dut._log.info("Input Config Pattern:"+testpattern)

    for b in range(27):
        bit = testpattern[b]
        dut.ui_in.value = int(bit)
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ms")
        bitout = str(dut.uo_out.value & 1)
        outpattern.append(bitout)

    # Set the input values you want to test
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 27)

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 0

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    #assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
