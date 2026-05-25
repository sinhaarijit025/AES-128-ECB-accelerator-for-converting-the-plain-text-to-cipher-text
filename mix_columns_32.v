`timescale 1ns / 1ps
module mix_columns_32(col_in,col_out);
    input [31:0] col_in;
    output [31:0] col_out;
    wire [7:0] s0,s1,s2,s3;
    wire [7:0] s0_out,s1_out,s2_out,s3_out;

    assign {s0,s1,s2,s3}=col_in;

    // multiply by 2 in GF(2^8)
    function [7:0] x_time;
        input [7:0] b;
        begin
            x_time=(b[7]==1'b1) ?((b<<1) ^ 8'h1b) :(b<<1);
        end
        
    endfunction

    //matrix computation logic
    //multiply by 3 : xtime(x) ^x
    assign s0_out= x_time(s0) ^ (x_time(s1)^s1) ^ s2 ^s3;
    assign s1_out=s0 ^ x_time(s1) ^ (x_time(s2) ^ s2) ^ s3;
    assign s2_out=s0 ^ s1 ^ (x_time (s2)) ^ (x_time(s3) ^ s3);
    assign s3_out=(x_time(s0) ^ s0) ^ s1 ^ s2 ^ x_time(s3);

    assign col_out={s0_out,s1_out,s2_out,s3_out};
endmodule