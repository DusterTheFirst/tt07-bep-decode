`include "data_validate.v"

module serial_decode (
  input wire reset_n,
  input wire clock,

  input wire serial_data,
  input wire serial_clock,

  output wire full,

  output wire [31:0] thermostat_id,
  output wire [15:0] room_temp,
  output wire [15:0] set_temp,
  output wire [7:0] state,
  output wire [7:0] tail_1,
  output wire [7:0] tail_2,
  output wire [7:0] tail_3
);
  // Preamble: 32
  // Type: 16 x 2
  // Constant: 32
  // Total Preamble: 96

  // Thermostat ID: 32
  // Room: 16
  // Set: 16
  // State: 8
  // CRC: 8x3
  // Total Data: 96

  reg [96:0] shift_register;
  reg preamble_or_data;

  localparam state_preamble = 0, state_data = 1;

  wire [31:0] preamble  = shift_register[95:64];
  wire [15:0] type_1    = shift_register[63:48];
  wire [15:0] type_2    = shift_register[47:32];
  wire [31:0] constant  = shift_register[31:0 ];

  assign full = shift_register[96] & preamble_or_data == state_data;

  assign
    thermostat_id   = shift_register[95:64],
    room_temp       = shift_register[63:48],
    set_temp        = shift_register[47:32],
    state           = shift_register[31:24],
    tail_1          = shift_register[23:16],
    tail_2          = shift_register[15:8 ],
    tail_3          = shift_register[ 7:0 ];

  // Shift Register
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      shift_register <= 97'b1;
      preamble_or_data <= state_preamble;
    end else if (serial_clock == 1'b1) begin
      if (preamble_or_data == state_preamble && valid) begin
        shift_register <= {96'b1, serial_data};
        preamble_or_data <= state_data;
      end else if (!full) begin
        shift_register[96:1] <= shift_register[95:0];
        shift_register[0] <= serial_data;
      end
    end
  end

  wire [3:0] validations;
  wire valid = &validations;

  data_validate data_validate (
    .preamble,
    .type_1,
    .type_2,
    .constant,

    .validations
  );
endmodule
