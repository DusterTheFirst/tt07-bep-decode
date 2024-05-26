module seven_segment_decode_decimal (
  input wire [3:0] digit,
  output reg [6:0] abcdefg
);
  always @(*) begin
    case (digit)
      4'd0: abcdefg = 7'b1111110;
      4'd1: abcdefg = 7'b0110000;
      4'd2: abcdefg = 7'b1101101;
      4'd3: abcdefg = 7'b1111001;
      4'd4: abcdefg = 7'b0110011;
      4'd5: abcdefg = 7'b1011011;
      4'd6: abcdefg = 7'b1011111;
      4'd7: abcdefg = 7'b1110010;
      4'd8: abcdefg = 7'b1111111;
      4'd9: abcdefg = 7'b1111011;
      default: abcdefg = 7'b0000001;
    endcase
  end
endmodule

module seven_segment_decode_hex (
  input wire [3:0] digit,
  output reg [6:0] abcdefg
);
  always @(*) begin
    case (digit)
      4'h0: abcdefg = 7'b1111110;
      4'h1: abcdefg = 7'b0110000;
      4'h2: abcdefg = 7'b1101101;
      4'h3: abcdefg = 7'b1111001;
      4'h4: abcdefg = 7'b0110011;
      4'h5: abcdefg = 7'b1011011;
      4'h6: abcdefg = 7'b1011111;
      4'h7: abcdefg = 7'b1110010;
      4'h8: abcdefg = 7'b1111111;
      4'h9: abcdefg = 7'b1111011;
      4'hA: abcdefg = 7'b1110111;
      4'hB: abcdefg = 7'b0011111;
      4'hC: abcdefg = 7'b1001110;
      4'hD: abcdefg = 7'b0111101;
      4'hE: abcdefg = 7'b1001111;
      4'hF: abcdefg = 7'b1000111;
    endcase
  end
endmodule
