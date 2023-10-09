// cdc for req/ack handshake
//                ___________________________________
// req_i(clk1) __/                                ___\_____
// ack_o(clk1) __________________________________/   \_____
//                                _______
// req_o(clk2) __________________/      _\_______________
// ack_i(clk2) ________________________/ \_______________
//                              _
// pre_req_o   ________________/ \_______________________
//
//

module req_ack_cdc
#(
	parameter ACK_WIDTH  = 3,
	parameter REQ_WIDTH  = 3
)
(
	input		clk1,
	input		rstn_1,
	input		req_i,
	output		ack_o,

	input		clk2,
	input		rstn_2,
	output	reg	req_o,
	input		ack_i,
	output		pre_req_o	// one cycle before req_o rising edge, can be used to latch something.

);

wire	rstn_1_dft = rstn_1;
wire	rstn_2_dft = rstn_2;


reg		req_i_d;
always@(posedge clk1, negedge rstn_1_dft)
begin
	if( ~rstn_1_dft )
		req_i_d <= 1'b0;
	else if( req_i & ~req_i_d )
		req_i_d <= 1'b1;
	else if( ack_o )
		req_i_d <= 1'b0;
end

wire	req_i_start = req_i & ~req_i_d;

reg		ack_i_cdc;

reg[ACK_WIDTH-1:0]		ack_o_cdc_d;
always@(posedge clk1, negedge rstn_1_dft)
begin
	if( ~rstn_1_dft )
		ack_o_cdc_d <={(ACK_WIDTH){1'b0}};
	else
		ack_o_cdc_d <= {ack_o_cdc_d[ACK_WIDTH-2:0],ack_i_cdc};
end

reg		req_i_cdc;
always@(posedge clk1, negedge rstn_1_dft)
begin
	if( ~rstn_1_dft )
		req_i_cdc <= 1'b0;
	else if( req_i_start )
		req_i_cdc <= 1'b1;
	else if( ack_o_cdc_d[ACK_WIDTH-2] )
		req_i_cdc <= 1'b0;
end

assign	ack_o = ack_o_cdc_d[ACK_WIDTH-1] && ~ack_o_cdc_d[ACK_WIDTH-2];

// =========================================================================
reg[REQ_WIDTH-1:0]  req_o_cdc_d;
always@(posedge clk2, negedge rstn_2_dft)
begin
	if( ~rstn_2_dft )
		req_o_cdc_d <= {(REQ_WIDTH){1'b0}};
	else
		req_o_cdc_d <= {req_o_cdc_d[REQ_WIDTH-2:0],req_i_cdc};
end

wire	req_o_start = req_o_cdc_d[REQ_WIDTH-2] & ~req_o_cdc_d[REQ_WIDTH-1];
assign	pre_req_o = req_o_start;

always@(posedge clk2, negedge rstn_2_dft)
begin
	if( ~rstn_2_dft )
		req_o <= 1'b0;
	else if( req_o_start )
		req_o <= 1'b1;
	else if( req_o & ack_i )
		req_o <= 1'b0;
end


always@(posedge clk2, negedge rstn_2_dft)
begin
	if( ~rstn_2_dft )
		ack_i_cdc <= 1'b0;
	else if( req_o & ack_i )
		ack_i_cdc <= 1'b1;
	else if( ~req_o_cdc_d[REQ_WIDTH-2] )
		ack_i_cdc <= 1'b0;
end


endmodule
