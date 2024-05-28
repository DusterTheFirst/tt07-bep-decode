module edge_detect (
    input wire digital_in,
    input wire clock,
    input wire reset_n,

    output reg pos_edge,
    output reg neg_edge
);
    reg previous_in;

    always @(posedge clock) begin
        if (!reset_n) begin
            previous_in <= 0;
        end else begin
            previous_in <= digital_in;
        end
    end

    always @(*) begin
        pos_edge = (digital_in != previous_in) & digital_in;
        neg_edge = (digital_in != previous_in) & !digital_in;
    end
endmodule
