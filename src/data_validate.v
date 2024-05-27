module data_validate(
  input wire [31:0] preamble,
  input wire [15:0] type_1,
  input wire [15:0] type_2,
  input wire [31:0] constant,

  output wire [3:0] validations
);
  localparam known_preamble = 32'hAAAAAAAA,
             known_type_12  = 16'hD391,
             known_constant = 32'h0DFFFFFE;

  wire preamble_valid = preamble == known_preamble;
  wire type_1_valid = type_1 == known_type_12;
  wire type_2_valid = type_2 == known_type_12;
  wire constant_valid = constant == known_constant;

  assign validations = { preamble_valid, type_1_valid, type_2_valid, constant_valid };
endmodule
