`include "serial_decode.v"

module data_multiplex (
    input wire reset_n,
    input wire clock,

    input wire serial_data,
    input wire serial_clock,

    input wire [3:0] address,

    output reg [7:0] parallel_out,
    output wire full
);

  // TODO: allow microcontroller to disable RX to allow
  // for data read
  always @(*) begin
    case (address)
      4'd0: parallel_out = thermostat_id[7:0];
      4'd1: parallel_out = thermostat_id[15:8];
      4'd2: parallel_out = thermostat_id[23:16];
      4'd3: parallel_out = thermostat_id[31:24];
      4'd4: parallel_out = room_temp[7:0];
      4'd5: parallel_out = room_temp[15:8];
      4'd6: parallel_out = set_temp[7:0];
      4'd7: parallel_out = set_temp[15:8];
      4'd8: parallel_out = state;
      4'd9: parallel_out = tail_1;  // CRC?
      4'd10: parallel_out = tail_2;  // CRC?
      4'd11: parallel_out = tail_3;  // CRC?
      // 4'd12
      // 4'd13
      // 4'd14
      4'd15: parallel_out = {4'b0000, validations};
      default: parallel_out = 8'h000000;
    endcase
  end

  wire [31:0] thermostat_id;
  wire [15:0] room_temp;
  wire [15:0] set_temp;
  wire [7:0] state;

  wire [7:0] tail_1;
  wire [7:0] tail_2;
  wire [7:0] tail_3;

  wire [3:0] validations;

  serial_decode data_decode (
    .reset_n,
    .clock,

    .serial_clock,
    .serial_data,

    .full,
    .validations,

    .thermostat_id,
    .room_temp,
    .set_temp,

    .state,
    .tail_1,
    .tail_2,
    .tail_3
  );

endmodule
