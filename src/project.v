/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "data_multiplex.v"
`include "edge_detect.v"
`include "state_machine.v"

module tt_um_dusterthefirst_project (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out = 8'b00000000;
  assign uo_out = parallel_out & { 8{halt} };
  assign uio_out = {2'b00, pos_edge, neg_edge, transmission_begin, manchester_data, manchester_clock, valid};
  assign uio_oe  = 8'b11111111;

  wire _unused = &{1'b0, uio_in, ena, ui_in[3:1]};

  wire digital_in = ui_in[0];
  wire halt = ui_in[2];
  wire [3:0] address = ui_in[7:4];

  wire pos_edge, neg_edge;

  edge_detect input_edge_detect (
    .digital_in(digital_in),
    .clock(clk),
    .reset(~rst_n),

    .pos_edge,
    .neg_edge
  );

  wire manchester_clock, manchester_data, transmission_begin;

  // TODO: FIXME:
  // Future (report): Use preamble to determine start of transmission, not a rising edge
  // Future (report): Also maybe use the known preamble to fix alignment problems with preamble (such as first transmission)
  state_machine state_machine (
    .clock(clk & !halt),
    .reset(~rst_n),

    .pos_edge,
    .neg_edge,

    .manchester_clock,
    .manchester_data,

    .transmission_begin
  );

  wire valid;
  wire [7:0] parallel_out;

  data_multiplex data_multiplex (
    .reset(transmission_begin || !rst_n),
    .clock(clk),

    .serial_clock(manchester_clock),
    .serial_data(manchester_data),

    .address,
    .parallel_out,

    .valid
  );
endmodule
