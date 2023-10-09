// apb3 to apb3 with cdc, including interrupt sync

module apb3_to_apb3_cdc
#(
        parameter A_WIDTH    = 32,
        parameter RD_WIDTH   = 32,
        parameter WD_WIDTH   = 32,
        parameter ACK_WIDTH  = 3,
        parameter REQ_WIDTH  = 3
)
(
        input                                           clk_a,
        input                                           prst_n_a,
        input                                           penable_a,
        input                                           pwrite_a,
        input                                           psel_a,
        input[A_WIDTH-1:0]                              paddr_a,

        output[RD_WIDTH-1:0]                            prdata_a,
        input[WD_WIDTH-1:0]                             pwdata_a,
        output                                          pready_a,
        
        input                                           clk_b,
        input                                           prst_n_b,
        output                                          penable_b,
        output                                          pwrite_b,
        output                                          psel_b,
        output[A_WIDTH-1:0]                             paddr_b,

        input[RD_WIDTH-1:0]                             prdata_b,
        output[WD_WIDTH-1:0]                            pwdata_b,
        input                                           pready_b

);

// synopsys template

reg     req_a;
wire    ack_a;
wire    latch_a = psel_a & ~penable_a;

reg[RD_WIDTH-1:0]       prdata; // latched prdata in clk_b domain
reg[RD_WIDTH-1:0]       prdata_latched_a;       // latched prdata in clk_a domain

always@(posedge clk_a, negedge prst_n_a)
begin
        if( ~prst_n_a )
                req_a <= 1'b0;
        else if( latch_a )
                req_a <= 1'b1;
        else if( ack_a )
                req_a <= 1'b0;
end

assign  pready_a = ~req_a;

reg[A_WIDTH+WD_WIDTH+1-1:0]     payload_a;
always@(posedge clk_a, negedge prst_n_a)        
begin
        if(~prst_n_a)
          payload_a <= {(A_WIDTH+WD_WIDTH+1){1'b0}};
        else if( latch_a ) 
          payload_a <= {paddr_a,pwdata_a,pwrite_a};
end

always@(posedge clk_a, negedge prst_n_a)        
begin
        if(~prst_n_a)
          prdata_latched_a <= {(RD_WIDTH){1'b0}};//modify 55aa to 0 by lianghao 20200825;
        else if( ack_a ) 
         prdata_latched_a <= prdata;
end

assign  prdata_a = prdata_latched_a;

wire                            req_b;
reg                             ack_b;

wire                            latch_payload_b;

req_ack_cdc
#(
        .ACK_WIDTH              (ACK_WIDTH),
        .REQ_WIDTH              (REQ_WIDTH)
)
cpu_req_ack_cdc_inst
(
        .clk1   (clk_a          ),
        .rstn_1 (prst_n_a       ),
        .req_i  (req_a          ),
        .ack_o  (ack_a          ),
        
        .clk2   (clk_b          ),
        .rstn_2 (prst_n_b       ),
        .req_o  (req_b          ),
        .ack_i  (ack_b          ),
        
        .pre_req_o(latch_payload_b)
        
);


reg    data_phase_b;

assign  penable_b = data_phase_b;
wire    prdata_valid_b = pready_b & data_phase_b;
wire    prdata_latch = prdata_valid_b;

always@(posedge clk_b, negedge prst_n_b)
begin
        if( ~prst_n_b )
                ack_b <= 1'b0;
        else
                ack_b <= prdata_valid_b;
end

always@(posedge clk_b, negedge prst_n_b)
begin
        if( ~prst_n_b )
                data_phase_b <= 1'b0;
        else if( req_b & ~data_phase_b & ~ack_b)
                data_phase_b <= 1'b1;
        else if( pready_b )
                data_phase_b <= 1'b0;
end

always@(posedge clk_b, negedge prst_n_b) 
begin
        if(~prst_n_b)
          prdata <={(RD_WIDTH){1'b0}};
        else if( prdata_latch ) 
          prdata <= prdata_b;
end

reg[A_WIDTH+WD_WIDTH+1-1:0]     payload_b;
always@(posedge clk_b, negedge prst_n_b)        
begin
        if( ~prst_n_b )
          payload_b <= {(A_WIDTH+WD_WIDTH+1){1'b0}};
  else if( latch_payload_b ) 
    payload_b <= payload_a;
end

assign  {paddr_b,pwdata_b,pwrite_b} = payload_b;
assign  psel_b = req_b & ~ack_b;

endmodule