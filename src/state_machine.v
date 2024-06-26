module state_machine (
    input wire clock,
    input wire enable,
    input wire reset_n,

    input wire pos_edge,
    input wire neg_edge,

    output wire manchester_clock,
    output wire manchester_data,

    output reg transmission_begin
);
    reg [3:0] timer, next_timer;
    localparam half_period = 9, // 18 / 2 = 9
               quarter_period = 4; // 18 / 4 = 4.5

    reg [1:0] state, next_state;
    localparam state_armed                    = 2'd0,
               state_timing                   = 2'd1,
               state_looking_for_edge         = 2'd2,
               state_found_edge               = 2'd3;

    reg decoded, next_decoded;
    reg clock_mask, next_clock_mask;

    assign manchester_data = decoded;
    assign manchester_clock = clock_mask;

    reg transmission_begin_next;

    always @(posedge clock) begin
        if (!reset_n) begin
            timer <= 0;
            state <= state_armed;
            decoded <= 0;
            clock_mask <= 0;
            transmission_begin <= 0;
        end else if (enable) begin
            timer <= next_timer;
            state <= next_state;
            decoded <= next_decoded;
            clock_mask <= next_clock_mask;
            transmission_begin <= transmission_begin_next;
        end
    end

    always @(*) begin
        next_state = state;
        next_decoded = decoded;
        next_timer = 0;
        next_clock_mask = 0;
        transmission_begin_next = 0;

        case (state)
            state_armed: if (pos_edge) begin
                next_state = state_timing;
                transmission_begin_next = 1;
            end
            state_timing: begin
                next_timer = timer + 1;

                if (timer > quarter_period) begin
                    next_timer = 0;
                    next_state = state_looking_for_edge;
                end
            end
            state_looking_for_edge: begin
                next_timer = timer + 1;

                if (pos_edge) begin
                    next_decoded = 0;
                    next_clock_mask = 1;
                    next_timer = 0;
                    next_state = state_found_edge;
                end else if (neg_edge) begin
                    next_decoded = 1;
                    next_clock_mask = 1;
                    next_timer = 0;
                    next_state = state_found_edge;
                end else if (timer >= half_period) begin
                    next_timer = 0;
                    next_state = state_armed;
                end
            end
            state_found_edge: begin
                next_timer = timer + 1;
                if (timer >= quarter_period) begin
                    next_timer = 0;
                    next_state = state_timing;
                end
            end
        endcase
    end
endmodule
