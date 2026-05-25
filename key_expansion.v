`timescale 1ns / 1ps
module key_expansion #(parameter  [3:0] round = 1)(key_in,key_out);
    input [127:0] key_in;
    output [127:0] key_out;
    wire [31:0] w0,w1,w2,w3;
    wire [31:0] w4,w5,w6,w7;
    wire [31:0] g_w3;
    wire [31:0] sub_word_out;
    wire [31:0] rot_word_out;
    wire [7:0] r_con;
    
    //spliting the 128 bits into 4 32 bit words
    assign {w0,w1,w2,w3}=key_in;

    //rotword -- circular left shift of the w3
    assign rot_word_out={w3[23:0],w3[31:24]};

    //sub_out -- passing the 4 bytes through the sbox

    s_box sbox0(.in_byte(rot_word_out[31:24]),.out_byte(sub_word_out[31:24]));
    s_box sbox1(.in_byte(rot_word_out[23:16]),.out_byte(sub_word_out[23:16]));
    s_box sbox2(.in_byte(rot_word_out[15:8]),.out_byte(sub_word_out[15:8]));
    s_box sbox3(.in_byte(rot_word_out[7:0]),.out_byte(sub_word_out[7:0]));

    //r_con

    assign r_con=(round==1)?8'h01:(round==2)?8'h02:(round==3)?8'h04:(round==4)?8'h08:(round==5)?8'h10:(round==6)?8'h20:(round==7)?8'h40:(round==8)?8'h80:(round==9)?8'h1B:(round==10)?8'h36:8'h00;

    // the g function xor with the sub output with the r_con

    assign g_w3=sub_word_out^{r_con,24'h000000};

    //gen the new words via xor

    assign w4=w0 ^ g_w3;
    assign w5=w1 ^ w4;
    assign w6=w2 ^ w5;
    assign w7=w3 ^ w6;

    //final key_out
    assign key_out={w4,w5,w6,w7};
endmodule