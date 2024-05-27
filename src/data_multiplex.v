`include "serial_decode.v"

module data_multiplex (
  input wire reset,
  input wire clock,

  input wire serial_data,
  input wire serial_clock,

  output wire full,

  input wire [1:0] address,
  output reg [7:0] parallel_out
);
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

  serial_decode data_decode (
    .reset,
    .clock,

    .serial_clock,
    .serial_data,

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
      // 4'd0: parallel_out = thermostat_id_reg[7:0];
      // 4'd1: parallel_out = thermostat_id_reg[15:8];
      // 4'd2: parallel_out = thermostat_id_reg[23:16];
      // 4'd3: parallel_out = thermostat_id_reg[31:24];
      2'd0: parallel_out = room_temp_reg[7:0];
      2'd1: parallel_out = room_temp_reg[15:8];
      2'd2: parallel_out = set_temp_reg[7:0];
      2'd3: parallel_out = set_temp_reg[15:8];
      // 4'd8: parallel_out = state_reg;
      // 4'd9: parallel_out = tail_2_reg;  // CRC?
      // 4'd10: parallel_out = tail_1_reg;  // CRC?
      // 4'd11: parallel_out = tail_3_reg;  // CRC?
      // 4'd12
      // 4'd13
      // 4'd14
      // 4'd15: parallel_out = {4'b0000, preamble_valid, type_1_valid, type_2_valid, constant_valid};
      default: parallel_out = 8'h000000;
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
endmodule
