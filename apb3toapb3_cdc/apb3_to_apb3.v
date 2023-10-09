// wrapper of apb3_to_apb3_cdc
// apb3_to_apb3_cdc will be bypassed if SYNC_MODE == 1

module apb3_to_apb3
#(
	parameter A_WIDTH    = 32,
	parameter RD_WIDTH   = 32,
	parameter WD_WIDTH   = 32,
	parameter ACK_WIDTH  = 3,
	parameter REQ_WIDTH  = 3,
	parameter SYNC_MODE  = 0
)
(
	input						clk_a,
	input						prst_n_a,
	input						penable_a,
	input						pwrite_a,
	input						psel_a,
	input[A_WIDTH-1:0]       			paddr_a,

	output[RD_WIDTH-1:0]	                	prdata_a,
	input[WD_WIDTH-1:0]		        	pwdata_a,
	output						pready_a,
	
	input						clk_b,
	input						prst_n_b,
	output						penable_b,
	output						pwrite_b,
	output						psel_b,
	output[A_WIDTH-1:0]			        paddr_b,

	input[RD_WIDTH-1:0]       			prdata_b,
	output[WD_WIDTH-1:0]	                 	pwdata_b,
	input						pready_b

);

// synopsys template

generate
if( SYNC_MODE == 1)
begin : sync_mode_apb
	assign	penable_b	= penable_a;
	assign	pwrite_b	= pwrite_a;
	assign	psel_b		= psel_a;
	assign	paddr_b		= paddr_a;
	assign	prdata_a	= prdata_b;
	assign	pwdata_b	= pwdata_a;
	assign	pready_a	= pready_b;
end
else
begin : async_mode_apb
apb3_to_apb3_cdc
#(
	.A_WIDTH		(A_WIDTH),
	.RD_WIDTH		(RD_WIDTH),
	.WD_WIDTH		(WD_WIDTH),
	.ACK_WIDTH		(ACK_WIDTH),
	.REQ_WIDTH		(REQ_WIDTH)
)
apb3_to_apb3_cdc
(
	.clk_a			(clk_a		),
	.prst_n_a		(prst_n_a	),
	.penable_a		(penable_a	),
	.pwrite_a		(pwrite_a	),
	.psel_a			(psel_a		),
	.paddr_a		(paddr_a	),

	.prdata_a		(prdata_a	),
	.pwdata_a		(pwdata_a	),
	.pready_a		(pready_a	),
	
	.clk_b			(clk_b		),
	.prst_n_b		(prst_n_b	),
	.penable_b		(penable_b	),
	.pwrite_b		(pwrite_b	),
	.psel_b			(psel_b		),
	.paddr_b		(paddr_b	),

	.prdata_b		(prdata_b	),
	.pwdata_b		(pwdata_b	),
	.pready_b		(pready_b	)

);
end
endgenerate


endmodule
