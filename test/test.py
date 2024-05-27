# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-FileCopyrightText: © 2024 Zachary Kohnen <z.j.kohnen@student.tue.nl>
# SPDX-License-Identifier: MIT

import csv
import os
from fractions import Fraction
from typing import Generator, Tuple, TypedDict
import cocotb
from cocotb.types import LogicArray, Range
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer


async def reset(dut):
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 0b1
    dut.digital_in.value = 0b0
    dut.address.value = 0b0
    dut.rst_n.value = 0b0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 0b1


def csv_transmission(files, dut) -> Generator[dict, None, None]:
    for file in files:
        dut._log.info(f"testing file {file}")
        with open(os.path.realpath(file), newline="") as transmission:
            transmission_reader = csv.DictReader(
                filter(lambda row: row[0] != "#", transmission)
            )
            for row in transmission_reader:
                yield row


class DataDecode(TypedDict):
    thermostat_id: int
    room_temp: int
    set_temp_low: int
    state: int


class DataDecodeTail(TypedDict):
    low: Tuple[int, int, int]
    high: Tuple[int, int, int]


async def validate_data(
    dut,
    expected: DataDecode,
    tail: DataDecodeTail,
):
    # assert dut.parallel_out.value == expected_preamble["preamble"]
    # assert (
    #     dut.data_multiplex.data_decode.type_1.value
    #     == expected_preamble["type_12"]
    # )
    # assert (
    #     dut.data_multiplex.data_decode.type_2.value
    #     == expected_preamble["type_12"]
    # )
    # assert (
    #     dut.data_multiplex.data_decode.constant.value
    #     == expected_preamble["constant"]
    # )

    readout_speed = Timer(Fraction(1, 500_000), units="sec")


    thermostat_id = LogicArray(expected["thermostat_id"], Range(31, 0))

    dut.address.value = LogicArray(0, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == thermostat_id[7:0]

    dut.address.value = LogicArray(1, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == thermostat_id[15:8]

    dut.address.value = LogicArray(2, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == thermostat_id[23:16]

    dut.address.value = LogicArray(3, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == thermostat_id[31:24]


    room_temp = LogicArray(expected["room_temp"], Range(15, 0))

    dut.address.value = LogicArray(4, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == room_temp[7:0]

    dut.address.value = LogicArray(5, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == room_temp[15:8]


    set_temp = LogicArray(expected["set_temp_low"], Range(15, 0))
    set_temp_plus_one = LogicArray(expected["set_temp_low"] + 1, Range(15, 0))

    dut.address.value = LogicArray(6, Range(3, 0))
    await readout_speed
    is_low = dut.parallel_out.value == set_temp[7:0]
    is_high = dut.parallel_out.value == set_temp_plus_one[7:0]
    assert is_low or is_high

    if is_low:
        dut._log.info("low transmission")
    else:
        dut._log.info("high transmission")

    dut.address.value = LogicArray(7, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == set_temp[15:8]


    dut.address.value = LogicArray(8, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(expected["state"], Range(7, 0))



    current_tail = tail["low" if is_low else "high"]

    dut.address.value = LogicArray(9, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(current_tail[0], Range(7, 0))

    dut.address.value = LogicArray(10, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(current_tail[1], Range(7, 0))

    dut.address.value = LogicArray(11, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(current_tail[2], Range(7, 0))

    dut.address.value = LogicArray(12, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(0x00, Range(7, 0))

    dut.address.value = LogicArray(13, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(0x00, Range(7, 0))

    dut.address.value = LogicArray(14, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(0x00, Range(7, 0))

    dut.address.value = LogicArray(15, Range(3, 0))
    await readout_speed
    assert dut.parallel_out.value == LogicArray(0x0F, Range(7, 0))

async def validate_transmissions(
    dut,
    expected: DataDecode,
    tail: DataDecodeTail,
):
    while True:
        await RisingEdge(dut.valid)
        dut._log.info("Valid Preamble")
        await ClockCycles(dut.clk, 1)
        await validate_data(
            dut,
            expected,
            tail,
        )


@cocotb.test()
async def transmission_single(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 50, units="us")  # 20 kHz
    cocotb.start_soon(clock.start())

    await reset(dut)

    dut._log.info("Test")

    for row in csv_transmission(["./data/transmission_digital_hs.csv"], dut):
        await ClockCycles(dut.clk, 1, rising=False)
        dut.digital_in.value = bool(int(row["DIO 0"]))
        await ClockCycles(dut.clk, 1, rising=True)

    assert dut.valid.value == 0x1

    await validate_data(
        dut,
        {
            "thermostat_id": 0x03391F89,
            "room_temp": 0x00F6,
            "set_temp_low": 0x00B5,
            "state": 0x00,
        },
        {
            "low": (0x94, 0xAE, 0x16),
            "high": (0x00, 0x00, 0x00),  # unknown (single transmission capture)
        },
    )

    # TODO: is this needed?
    # assert (
    #     dut.data_multiplex.data_decode.transmission.value
    #     == 0xAAAAAAAA_D391_D391_0DFFFFFE_03391F89_00F6_00B5_00_94AE16
    # )

    dut.rst_n.value = 0b0
    await ClockCycles(dut.clk, 10)


@cocotb.test()
async def transmission_super_long(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 50, units="us")  # 20 kHz
    cocotb.start_soon(clock.start())

    await reset(dut)

    validation = cocotb.start_soon(
        validate_transmissions(
            dut,
            {
                "thermostat_id": 0x02391F89,
                "room_temp": 0x0116,
                "set_temp_low": 0x0104,
                "state": 0x00,
            },
            {
                "low": (0xB0, 0x86, 0x0E),
                "high": (0x56, 0x84, 0x4E),
            },
        )
    )

    dut._log.info("Test")

    for row in csv_transmission(
        [f"./data/hs_super_long/{x:02}.csv" for x in range(1, 11)], dut
    ):
        await ClockCycles(dut.clk, 1, rising=False)
        dut.digital_in.value = bool(int(row["DIO 0"]))
        await ClockCycles(dut.clk, 1, rising=True)

    validation.kill()

    dut.rst_n.value = 0b0
    await ClockCycles(dut.clk, 10)


@cocotb.test()
async def transmission_repeating(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 50, units="us")  # 20 kHz
    cocotb.start_soon(clock.start())

    await reset(dut)

    validation = cocotb.start_soon(
        validate_transmissions(
            dut,
            {
                "thermostat_id": 0x03391F89,
                "room_temp": 0x0112,
                "set_temp_low": 0x00B4,
                "state": 0x00,
            },
            {
                "low": (0xDA, 0xFB, 0x46),
                "high": (0x3C, 0xF9, 0x06),
            },
        )
    )

    dut._log.info("Test")

    for row in csv_transmission(
        [f"./data/hs_repeating/{x:02}.csv" for x in range(1, 11)], dut
    ):
        await ClockCycles(dut.clk, 1, rising=False)
        dut.digital_in.value = bool(int(row["DIO 0"]))
        await ClockCycles(dut.clk, 1, rising=True)

    validation.kill()

    dut.rst_n.value = 0b0
    await ClockCycles(dut.clk, 10)
