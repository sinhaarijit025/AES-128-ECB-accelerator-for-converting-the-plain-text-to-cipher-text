`timescale 1ns / 1ps
module aes_round(clk,rst,en,state_in,round_key,state_out);
    input clk,en,rst;
    input [127:0] state_in;
    input [127:0] round_key;
    output reg [127:0] state_out;
    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] mix_columns_out;
    wire [127:0] add_key_out;

    //for subbytes
    genvar i;
    generate
        for(i=0;i<16;i=i+1) begin: s_box_array
            s_box sbox(.in_byte(state_in[(i*8)+7:i*8]),.out_byte(sub_bytes_out[(i*8)+7:i*8]));
        end
    endgenerate

    //for the shiftrows

    //row 0 : no shift
    assign shift_rows_out[127:120]=sub_bytes_out[127:120];
    assign shift_rows_out[95:88]=sub_bytes_out[95:88];
    assign shift_rows_out[63:56]=sub_bytes_out[63:56];
    assign shift_rows_out[31:24]=sub_bytes_out[31:24];

    //row 1: shift left by 1 byte
    assign shift_rows_out[119:112]=sub_bytes_out[87:80];
    assign shift_rows_out[87:80]=sub_bytes_out[55:48];
    assign shift_rows_out[55:48]=sub_bytes_out[23:16];
    assign shift_rows_out[23:16]=sub_bytes_out[119:112];

    //row 2:shift by 2 bytes
    assign shift_rows_out[111:104]=sub_bytes_out[47:40];
    assign shift_rows_out[79:72]=sub_bytes_out[15:8];
    assign shift_rows_out[47:40]=sub_bytes_out[111:104];
    assign shift_rows_out[15:8]=sub_bytes_out[79:72];

    //row 3: shift by 3 bytes
    assign shift_rows_out[103:96]=sub_bytes_out[7:0];
    assign shift_rows_out[71:64]=sub_bytes_out[103:96];
    assign shift_rows_out[39:32]=sub_bytes_out[71:64];
    assign shift_rows_out[7:0]=sub_bytes_out[39:32];

    //for the 128 mix_columns
    mix_columns_128 mix_128(.state_in(shift_rows_out),.state_out(mix_columns_out));

    //add the round key

    assign add_key_out=mix_columns_out ^ round_key;

    //pipelined reg

    always @(posedge clk or negedge rst) begin
        if(!rst) state_out<=128'b0;
        else if(en) begin
            state_out<=add_key_out;
        end
        // if en==0 then it will hold the previous values latch (stall)
    end


endmodule