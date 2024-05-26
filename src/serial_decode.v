module serial_decode (
    input wire reset,
    input wire clock,

    input wire serial_data,
    input wire serial_clock,

    (* KEEP_HIREARCHY = "TRUE" *) output wire full,

    output wire [31:0] preamble,
    output wire [15:0] type_1,
    output wire [15:0] type_2,
    output wire [31:0] constant,
    output wire [31:0] thermostat_id,
    output wire [15:0] room_temp,
    output wire [15:0] set_temp,
    output wire [7:0] state,
    output wire [7:0] tail_1,
    output wire [7:0] tail_2,
    output wire [7:0] tail_3
);

    // 10101010101010101010101010101010110100111001000111010011100100010000110111111111111111111111111000000010001110010001111110011111000000001100000000000000110010000110010001010000000011000100101
    // PREAMBLE: 32h TYPE?: 16h 16h CONSTANT: 32h THERMOSTAT ID: 32h ROOM: 16d SET: 16d STATE?: 8h CRC?: 8h 8h 8h

    reg [192:0] shift_register;
    assign full = shift_register[192];
    wire [191:0] transmission = shift_register[191:0];

    assign
        preamble        = transmission[191:160],
        type_1          = transmission[159:144],
        type_2          = transmission[143:128],
        constant        = transmission[127:96 ],
        thermostat_id   = transmission[ 95:64 ],
        room_temp       = transmission[ 63:48 ],
        set_temp        = transmission[ 47:32 ],
        state           = transmission[ 31:24 ],
        tail_1          = transmission[ 23:16 ],
        tail_2          = transmission[ 15:8  ],
        tail_3          = transmission[  7:0  ];

    // Shift Register
    always @(posedge clock) begin
        if (reset) begin
            shift_register <= 193'b1;
        end else if (!full && serial_clock == 1'b1) begin
            shift_register[192:1] <= shift_register[191:0];
            shift_register[0] <= serial_data;
        end
    end
endmodule
