# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-FileCopyrightText: © 2024 Zachary Kohnen <z.j.kohnen@student.tue.nl>
# SPDX-License-Identifier: MIT

import csv
import os
from typing import Generator, Tuple, TypedDict
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def reset(dut):
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 0b1
    dut.ui_in.value = 0b0
    dut.uio_in.value = 0b0
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


class DataDecodePreamble(TypedDict):
    # FIXME: is this all the preamble?
    preamble: int
    type_12: int
    constant: int


class DataDecode(TypedDict):
    thermostat_id: int
    room_temp: int
    set_temp_low: int
    state: int


class DataDecodeTail(TypedDict):
    low: Tuple[int, int, int]
    high: Tuple[int, int, int]


def validate_data(
    dut,
    expected_preamble: DataDecodePreamble,
    expected: DataDecode,
    tail: DataDecodeTail,
):
    # FIXME: is this all the preamble?
    assert dut.user_project.data_decode.preamble.value == expected_preamble["preamble"]
    assert dut.user_project.data_decode.type_1.value == expected_preamble["type_12"]
    assert dut.user_project.data_decode.type_2.value == expected_preamble["type_12"]
    assert dut.user_project.data_decode.constant.value == expected_preamble["constant"]

    assert dut.user_project.data_decode.thermostat_id.value == expected["thermostat_id"]
    assert dut.user_project.data_decode.room_temp.value == expected["room_temp"]
    set_temp = dut.user_project.data_decode.set_temp.value
    assert (set_temp == expected["set_temp_low"]) or (
        set_temp == expected["set_temp_low"] + 1
    )
    is_low = set_temp == expected["set_temp_low"]

    if is_low:
        dut._log.info("low transmission")
    else:
        dut._log.info("high transmission")

    assert dut.user_project.data_decode.state.value == expected["state"]

    current_tail = tail["low" if is_low else "high"]
    assert dut.user_project.data_decode.tail_1.value == current_tail[0]
    assert dut.user_project.data_decode.tail_2.value == current_tail[1]
    assert dut.user_project.data_decode.tail_3.value == current_tail[2]


constant_preamble: DataDecodePreamble = {
    "preamble": 0xAAAAAAAA,
    "type_12": 0xD391,
    "constant": 0x0DFFFFFE,
}


async def validate_transmissions(
    dut,
    expected: DataDecode,
    tail: DataDecodeTail,
):
    while True:
        await RisingEdge(dut.user_project.data_decode.full)
        dut._log.info("Full")
        await ClockCycles(dut.clk, 1)
        validate_data(
            dut,
            constant_preamble,
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
        dut.ui_in[0].value = bool(int(row["DIO 0"]))
        await ClockCycles(dut.clk, 1, rising=True)

    assert dut.user_project.data_decode.full.value == 0x1

    validate_data(
        dut,
        constant_preamble,
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
    #     dut.user_project.data_decode.transmission.value
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
        dut.ui_in[0].value = bool(int(row["DIO 0"]))
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
        dut.ui_in[0].value = bool(int(row["DIO 0"]))
        await ClockCycles(dut.clk, 1, rising=True)

    validation.kill()

    dut.rst_n.value = 0b0
    await ClockCycles(dut.clk, 10)
