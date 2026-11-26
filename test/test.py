# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer
from cocotb.triggers import ValueChange
from cocotb.utils import get_sim_time

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

    testpattern = "101100011100001111000001111" + "000000000000000000000000000"
    outpattern = ""
    dut._log.info("Input Test Pattern:"+testpattern)

    for b in range(54):
        bit = testpattern[b]
        dut.ui_in.value = int(bit)
        await ClockCycles(dut.clk, 1)
        #await Timer(10, unit="ns")
        bitout = str(dut.uo_out.value[0])
        outpattern = outpattern + bitout
        #dut._log.info("Input:output " + bit + ":" + bitout)

    dut._log.info("Output Test Pattern:" + outpattern)

    assert testpattern.replace("000000000000000000000000000","") == outpattern.replace("000000000000000000000000000","")

    
    #10 00 10 00 00 00 00 00 00 00 00 00 000
    #10 00 00 00 10 00 00 00 00 00 00 00 000
    #10 00 00 00 00 00 10 00 00 00 00 00 000
    #10 00 00 00 00 00 00 00 10 00 00 00 000
    #10 00 00 00 00 00 00 00 00 00 10 00 000
    #configs = ["100010000000000000000000000","100000001000000000000000000","100000000000100000000000000","100000000000000010000000000","100000000000000000001000000"]

    #10 10 00 00 00 00 00 00 00 00 00 00 000
    #10 00 00 10 00 00 00 00 00 00 00 00 000
    #10 00 00 00 00 10 00 00 00 00 00 00 000
    #10 00 00 00 00 00 00 10 00 00 00 00 000
    #10 00 00 00 00 00 00 00 00 10 00 00 000
    #10 00 00 00 00 00 00 00 00 00 00 10 000

    #00 00 10 10 10 10 10 10 10 10 10 10 000
    #00 10 10 00 10 10 10 10 10 10 10 10 000
    #00 10 10 10 10 00 10 10 10 10 10 10 000
    #00 10 10 10 10 10 10 00 10 10 10 10 000
    #00 10 10 10 10 10 10 10 10 00 10 10 000
    #00 10 10 10 10 10 10 10 10 10 10 00 000

    configs = ["101000000000000000000000000","100000100000000000000000000","100000000010000000000000000","100000000000001000000000000","100000000000000000100000000","100000000000000000000010000"]
    #configs = ["000010101010101010101010000","001010001010101010101010000","001010101000101010101010000","001010101010100010101010000","001010101010101010001010000","001010101010101010101000000"]

    speeds = []
    for testpattern in configs:
        dut._log.info("\nLoading Config Pattern:"+testpattern)
        for b in range(27):
            bit = testpattern[b]
            dut.ui_in.value = int(bit)
            await ClockCycles(dut.clk, 1)
            
        dut._log.info("Enabling Rings")
        dut.ui_in.value[1] = 1
        dut.ui_in.value[2] = 1
        dut.ui_in.value[3] = 1

        loopbitchange = False
        loopcnt = 0
        while(not loopbitchange):
            loopcnt = loopcnt + 1
            await ValueChange(dut.uo_out)
            dut._log.info("uo_out byte:" + str(dut.uo_out.value))
            if(dut.uo_out.value[0]==1):
                start = get_sim_time(unit="ns")
                dut._log.info("uo_out byte:" + str(dut.uo_out.value))
                dut._log.info("loop bit changed at:"+str(start))
                loopbitchange = True
            if(loopcnt%100==0 & loopcnt > 100):
                dut._log.info("uo_out byte:" + str(dut.uo_out.value))        
        

        loopbitchange = False
        loopcnt = 0
        while(not loopbitchange):
            loopcnt = loopcnt + 1
            await ValueChange(dut.uo_out)
            dut._log.info("uo_out byte:" + str(dut.uo_out.value))
            if(dut.uo_out.value[0]==1):
                end = get_sim_time(unit="ns")
                dut._log.info("uo_out byte:" + str(dut.uo_out.value))
                dut._log.info("loop bit changed at:"+str(start))
                loopbitchange = True
            if(loopcnt%100==0 & loopcnt > 100):
                dut._log.info("uo_out byte:" + str(dut.uo_out.value))
        
        dut._log.info("Loop Period:" + str(end-start)+"ns")
        speeds.append(end-start)

        dut._log.info("Disabling Rings")
        dut.ui_in.value[1] = 0
        dut.ui_in.value[2] = 0
        dut.ui_in.value[3] = 0

    dut._log.info("\nPrinting Loop Speeds at CFGs")
    for i in range(len(configs)):
        dut._log.info("Bitstream:" + configs[i])
        dut._log.info("Period:" + str(speeds[i]) + "ns")

    dut._log.info("\nVerifying CFG behavior")
    for i in range(len(speeds)-1):
        assert speeds[i+1] > speeds[i]
        

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
