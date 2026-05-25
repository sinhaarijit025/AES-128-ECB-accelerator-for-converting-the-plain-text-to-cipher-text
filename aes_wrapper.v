`timescale 1ns / 1ps

module axi_aes_wrapper (
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,
    input  wire [31:0] S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,
    output reg  [1:0]  S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,
    input  wire [31:0] S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,
    output reg  [31:0] S_AXI_RDATA,
    output reg  [1:0]  S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);
    reg [31:0]  slv_control_reg;
    reg [31:0]  slv_status_reg;
    reg [127:0] slv_key_reg;
    reg [127:0] slv_plaintext_reg;
    wire [127:0] core_ciphertext;
    reg core_enable;
    reg [3:0] flush_counter;
    reg [11:0] pipeline_track;
    reg [127:0] latched_ciphertext;
    reg trigger_injection;

    wire slv_reg_wren = S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= 2'b00;
        end else begin
            if (~S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) S_AXI_AWREADY <= 1'b1;
            else S_AXI_AWREADY <= 1'b0;

            if (~S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID) S_AXI_WREADY <= 1'b1;
            else S_AXI_WREADY <= 1'b0;

            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID && ~S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end
    reg has_new_data;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            slv_control_reg    <= 32'b0;
            slv_key_reg        <= 128'b0;
            slv_plaintext_reg  <= 128'b0;
            core_enable        <= 1'b0;
            flush_counter      <= 4'b0;
            pipeline_track     <= 12'b0;
            latched_ciphertext <= 128'b0;
            has_new_data       <= 1'b0;
        end else begin
            if (slv_reg_wren) begin
                case (S_AXI_AWADDR[7:0])
                    8'h00: slv_control_reg <= S_AXI_WDATA;
                    8'h10: slv_key_reg[127:96] <= S_AXI_WDATA;
                    8'h14: slv_key_reg[95:64]  <= S_AXI_WDATA;
                    8'h18: slv_key_reg[63:32]  <= S_AXI_WDATA;
                    8'h1C: slv_key_reg[31:0]   <= S_AXI_WDATA;
                    8'h20: slv_plaintext_reg[127:96] <= S_AXI_WDATA;
                    8'h24: slv_plaintext_reg[95:64]  <= S_AXI_WDATA;
                    8'h28: slv_plaintext_reg[63:32]  <= S_AXI_WDATA;
                    8'h2C: begin
                        slv_plaintext_reg[31:0] <= S_AXI_WDATA;
                        
                        has_new_data <= 1'b1; 
                    end
                endcase
            end else if (core_enable && has_new_data) begin
                has_new_data <= 1'b0; 
            end

            if (has_new_data) begin
                flush_counter <= 4'd12;
                core_enable   <= 1'b1;
            end else if (flush_counter > 0) begin
                flush_counter <= flush_counter - 1;
                core_enable   <= 1'b1;
            end else begin
                core_enable   <= 1'b0;
            end

            
            if (core_enable) begin
                
                pipeline_track <= {pipeline_track[10:0], has_new_data};
            end

            if (pipeline_track[9]) begin
                latched_ciphertext <= core_ciphertext;
            end
        end
    end
    wire slv_reg_rden = S_AXI_ARREADY & S_AXI_ARVALID & ~S_AXI_RVALID;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
            S_AXI_RRESP   <= 2'b00;
        end else begin
            if (~S_AXI_ARREADY && S_AXI_ARVALID) S_AXI_ARREADY <= 1'b1;
            else S_AXI_ARREADY <= 1'b0;

            if (slv_reg_rden) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

   
    always @(posedge S_AXI_ACLK) begin
        if (slv_reg_rden) begin
            case (S_AXI_ARADDR[7:0])
                8'h00: S_AXI_RDATA <= slv_control_reg;
                8'h04: S_AXI_RDATA <= slv_status_reg; 
                8'h10: S_AXI_RDATA <= slv_key_reg[127:96];
                8'h14: S_AXI_RDATA <= slv_key_reg[95:64];
                8'h18: S_AXI_RDATA <= slv_key_reg[63:32];
                8'h1C: S_AXI_RDATA <= slv_key_reg[31:0];

                
                8'h30: S_AXI_RDATA <= latched_ciphertext[127:96];
                8'h34: S_AXI_RDATA <= latched_ciphertext[95:64];
                8'h38: S_AXI_RDATA <= latched_ciphertext[63:32];
                8'h3C: S_AXI_RDATA <= latched_ciphertext[31:0];
                default: S_AXI_RDATA <= 32'b0;
            endcase
        end
    end
    AES_core aes_inst (
        .clk         (S_AXI_ACLK),
        .rst         (S_AXI_ARESETN),       
        .en          (core_enable),         
        .plain_text  (slv_plaintext_reg),
        .initial_key (slv_key_reg),
        .cipher_text (core_ciphertext)
    );

endmodule
