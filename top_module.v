`timescale 1ns / 1ps
module AES_core (clk,rst,en,plain_text,initial_key,cipher_text);
    input clk,rst,en;
    input [127:0] plain_text,initial_key;
    output [127:0] cipher_text;

    //arrays to hold the data states and key states
    wire [127:0] state_data[0:10];
    wire [127:0] round_keys[0:10];
    //for the round 0;
    assign state_data[0]=plain_text^initial_key;
    assign round_keys[0]=initial_key;

    //for round 1 to 9
    genvar i;
    generate
        for(i=0;i<9;i=i+1) begin: stages
            //calculation the next_round key from the initial key
            wire [127:0] next_key;
            key_expansion #(.round(i+1)) key_gen(.key_in(round_keys[i]),.key_out(next_key));

            //reg the key for to travel it with the data
            reg [127:0] store_key; //pipelined register
            always @(posedge clk or negedge rst) begin
                if(!rst) store_key<=128'b0;
                else if(en) store_key<=next_key;
            end
            assign round_keys[i+1]=store_key;
            //now the data to the pipelined stagges
            aes_round round(.clk(clk),.rst(rst),.en(en),.state_in(state_data[i]),.round_key(next_key),.state_out(state_data[i+1]));
        end
    endgenerate

    //round 10 final key with no mix clumns
    wire [127:0] final_key;
    key_expansion #(.round(10)) key_gen_final(.key_in(round_keys[9]),.key_out(final_key));

    //reg the final key
    reg [127:0] final_key_reg;
    always @(posedge clk or negedge rst) begin
        if(!rst) final_key_reg<=128'b0;
        else if(en) final_key_reg<=final_key;
    end
    assign round_keys[10]=final_key_reg;

    //now data to the last pipelined stage
    aes_final_round round_10(.clk(clk),.rst(rst),.en(en),.state_in(state_data[9]),.round_key(final_key),.state_out(state_data[10]));

    //for output
    assign cipher_text=state_data[10];

endmodule