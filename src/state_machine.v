module state_machine (
    input wire clock,
    input wire reset,

    input wire pos_edge,
    input wire neg_edge,

    output wire manchester_clock,
    output wire manchester_data,

    output reg transmission_begin
);

    reg [4:0] timer, next_timer;
    localparam period = 18;

    reg [2:0] state, next_state;
    localparam state_waiting_for_transmission = 3'd0, // TODO: preamble detection
               state_armed                    = 3'd1,
               state_timing                   = 3'd2,
               state_looking_for_edge         = 3'd3,
               state_found_edge               = 3'd4,
               state_end_of_transmission      = ~3'd0;

    reg decoded, next_decoded;
    reg clock_mask, next_clock_mask;

    assign manchester_data = decoded;
    assign manchester_clock = clock_mask;

    reg transmission_begin_next;

    always @(posedge clock) begin
        if (reset) begin
            timer <= 0;
            state <= state_waiting_for_transmission;
            decoded <= 0;
            clock_mask <= 0;
            transmission_begin <= 0;
        end else begin
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
            state_waiting_for_transmission: begin
                next_timer = timer + 1;
                if (timer == ~5'd0) begin
                    next_timer = 0;
                    next_state = state_armed;
                end
            end
            state_armed: if (pos_edge) begin
                next_state = state_timing;
                transmission_begin_next = 1;
            end
            state_timing: begin
                next_timer = timer + 1;

                if (timer > period / 4) begin
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
                end else if (timer >= period) begin
                    next_timer = 0;
                    next_state = state_end_of_transmission;
                end
            end
            state_found_edge: begin
                next_timer = timer + 1;
                if (timer >= period / 4) begin
                    next_timer = 0;
                    next_state = state_timing;
                end
            end
            state_end_of_transmission: begin
                next_timer = timer + 1;
                if (timer == ~5'd0) begin
                    next_timer = 0;
                    next_state = state_waiting_for_transmission;
                end
            end
            default: begin end
        endcase
    end
endmodule
