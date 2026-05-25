module mix_columns_128(state_in,state_out);
    input [127:0] state_in;
    output [127:0] state_out;

    //4 * 32 bit columns

    mix_columns_32 m0(.col_in(state_in[127:96]),.col_out(state_out[127:96]));
    mix_columns_32 m1(.col_in(state_in[95:64]),.col_out(state_out[95:64]));
    mix_columns_32 m2(.col_in(state_in[63:32]),.col_out(state_out[63:32]));
    mix_columns_32 m3(.col_in(state_in[31:0]),.col_out(state_out[31:0]));
endmodule