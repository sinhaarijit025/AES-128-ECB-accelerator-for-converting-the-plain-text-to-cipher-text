`timescale 1ns / 1ps
module aes_final_round(clk,rst,en,state_in,round_key,state_out);
    input clk,rst,en;
    input [127:0] state_in,round_key;
    output reg [127:0] state_out;
    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] add_key_out;

    //for the 16 s boxes
    genvar i;
    generate
        for(i=0;i<16;i=i+1) begin: s_box_array_final
          s_box final_sbox(.in_byte(state_in[(i*8)+7:i*8]),.out_byte(sub_bytes_out[(i*8)+7:i*8]));
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

    //no mix columns in round10

    assign add_key_out=shift_rows_out ^ round_key;

    //pipeliend reg

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state_out<=128'b0;
        end 
        else if(en) begin
            state_out<=add_key_out;
        end
        //if en==0 then stalled
    end
endmodule