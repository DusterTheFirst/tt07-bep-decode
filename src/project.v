/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "serial_decode.v"
`include "edge_detect.v"
`include "state_machine.v"

module tt_um_dusterthefirst_project (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output reg  [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out = 8'b00000000;
  assign uio_out = {4'b0000, transmission_begin, manchester_data, manchester_clock, full};
  assign uio_oe  = 8'b11111111;

  wire _unused = &{1'b0, uio_in, ena, ui_in[3:1]};

  wire digital_in = ui_in[0];
  wire [1:0] address = ui_in[7:6];

  wire pos_edge, neg_edge;

  edge_detect input_edge_detect (
    .digital_in(digital_in),
    .clock(clk),
    .reset(~rst_n),

    .pos_edge,
    .neg_edge
  );

  reg manchester_clock, manchester_data, transmission_begin;

  // TODO: FIXME:
  // Future (report): Use preamble to determine start of transmission, not a rising edge
  // Future (report): Also maybe use the known preamble to fix alignment problems with preamble (such as first transmission)
  // Maybe double buffer results, verify preamble and other known sections before sending them to the visualizer
  state_machine state_machine (
    .digital_in(digital_in),
    .clock(clk),
    .reset(~rst_n),

    .pos_edge,
    .neg_edge,

    .manchester_clock,
    .manchester_data,

    .transmission_begin
  );

  localparam known_preamble = 32'hAAAAAAAA,
             known_type_12  = 16'hD391,
             known_constant = 32'h0DFFFFFE;

  wire preamble_valid = preamble == known_preamble;
  // wire type_1_valid = type_1 == known_type_12;
  // wire type_2_valid = type_2 == known_type_12;
  wire constant_valid = constant == known_constant;

  wire valid = full & preamble_valid & constant_valid;

  // TODO: remove double buffering? allow microcontroller to disable RX to allow
  // for data read
  always @(*) begin
    case (address)
      // 4'd0: uo_out = thermostat_id_reg[7:0];
      // 4'd1: uo_out = thermostat_id_reg[15:8];
      // 4'd2: uo_out = thermostat_id_reg[23:16];
      // 4'd3: uo_out = thermostat_id_reg[31:24];
      2'd0: uo_out = room_temp_reg[7:0];
      2'd1: uo_out = room_temp_reg[15:8];
      2'd2: uo_out = set_temp_reg[7:0];
      2'd3: uo_out = set_temp_reg[15:8];
      // 4'd8: uo_out = state_reg;
      // 4'd9: uo_out = tail_2_reg;  // CRC?
      // 4'd10: uo_out = tail_1_reg;  // CRC?
      // 4'd11: uo_out = tail_3_reg;  // CRC?
      // 4'd12
      // 4'd13
      // 4'd14
      // 4'd15: uo_out = {4'b0000, preamble_valid, type_1_valid, type_2_valid, constant_valid};
      default: uo_out = 8'h000000;
    endcase
  end

  // reg [31:0] thermostat_id_reg;
  reg [15:0] room_temp_reg;
  reg [15:0] set_temp_reg;
  // reg [7:0] state_reg;

  // reg [7:0] tail_1_reg;
  // reg [7:0] tail_2_reg;
  // reg [7:0] tail_3_reg;

  always @(posedge valid) begin
    // thermostat_id_reg <= thermostat_id;
    room_temp_reg <= room_temp;
    set_temp_reg <= set_temp;
    // state_reg <= state;

    // tail_1_reg <= tail_1;
    // tail_2_reg <= tail_2;
    // tail_3_reg <= tail_3;
  end

  wire [31:0] preamble;
  wire [15:0] type_1;
  wire [15:0] type_2;
  wire [31:0] constant;

  wire [31:0] thermostat_id;
  wire [15:0] room_temp;
  wire [15:0] set_temp;
  wire [7:0] state;

  wire [7:0] tail_1;
  wire [7:0] tail_2;
  wire [7:0] tail_3;

  wire full;

  serial_decode data_decode (
    .reset(transmission_begin || !rst_n),
    .clock(clk),

    .serial_clock(manchester_clock),
    .serial_data(manchester_data),

    .full,

    .thermostat_id,
    .room_temp,
    .set_temp,

    .preamble,
    .type_1,
    .type_2,
    .constant,
    .state,
    .tail_1,
    .tail_2,
    .tail_3
  );

endmodule
