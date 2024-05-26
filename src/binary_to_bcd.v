module binary_to_bcd (
    input wire reset_n,
    input wire clock,

    input wire [7:0] binary,
    output wire [3:0] digit,

    output reg [1:0] digit_place
);
    parameter clock_cycles_pow2 = 3;

    reg [clock_cycles_pow2 - 1:0] clock_counter;

    reg [7:0] binary_reg;

    always @(posedge clock) begin
        if (reset_n == 1'b0) begin
            digit_place <= 2;
            clock_counter <= 0;
            binary_reg <= binary;
        end else if (&clock_counter) begin
            clock_counter <= 0;
            case (digit_place)
                2: digit_place <= 1;
                1: digit_place <= 0;
                0: begin
                    digit_place <= 2;
                    binary_reg <= binary;
                end
                default: digit_place <= 2;
            endcase
        end else begin
            clock_counter <= clock_counter + 1;
        end
    end

    reg [7:0] digit_8;
    assign digit = digit_8[3:0];

    always @(*) begin
        case (digit_place)
            0: digit_8 = binary_reg % 10;
            1: digit_8 = (binary_reg / 10) % 10;
            2: digit_8 = (binary_reg / 100) % 10;
            default: digit_8 = 8'b00001111;
        endcase
    end

    wire _unused = &{1'b0, digit_8[7:4], 1'b0};
endmodule
