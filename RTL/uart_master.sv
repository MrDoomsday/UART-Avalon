module uart_master
(
	input clk,
	input reset_n,
	
	
	input 	logic 	[7:0] 		avsi_data,
	input 	logic 				avsi_valid,
	output 	logic 				avsi_ready,
	
	
	output 	logic 				avmm_write,
	output 	logic 	[31:0] 		avmm_address,
	output 	logic 	[31:0]		avmm_writedata,
	input 	logic 				avmm_waitrequest

);



reg [7:0] data;
reg valid;




enum logic [3:0] {idle, addr_0, addr_1, addr_2, addr_3, data_0, data_1, data_2, data_3, crc, write} state, state_next;


wire state_receive = (state == addr_0) | (state == addr_1) | (state == addr_2) | (state == addr_3) | (state == data_0) | (state == data_1) | (state == data_2) | (state == data_3) | (state == crc);

wire start_packet = (data == 8'hFF) & valid;
reg [25:0] counter;
wire [7:0] crc_calculated;
reg [25:0] counter_write;

(*keep*)wire crc_ok;
(*keep*)wire cnt_max;// = counter == 26'd50_000_000;
(*keep*)wire write_fail;// = counter_write == 26'd50_000_000;

assign cnt_max = counter == 26'd50_000_000;
assign write_fail = counter_write == 26'd50_000_000;
assign crc_ok = (crc_calculated == data) & (state == crc) & valid;
//********************************************************************************************************************************************************************





crc_calc crc_inst 
(
	.clk(clk),
	.rst(reset_n),
	.clear((state == idle) & valid),
	.data_in(data),
	.crc_en(state_receive & valid),
	.crc_out(crc_calculated)
);

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n) {data, valid} <= 'h0;
	else if(avsi_ready) {data, valid} <= {avsi_data, avsi_valid};
				

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n) counter <= 'h0;
	else if(state_receive)
			if(valid) counter <= 'h0;
			else counter <= counter + 1'b1;
		 else counter <= 'h0;
				

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n) counter_write <= 'h0;
	else if(state == write) counter_write <= counter_write + 1'b1;
		 else counter_write <= 'h0;
				
	
always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n) state <= idle;
	else state <= state_next;
		

	
always_comb
	case(state)
		idle: if(start_packet) state_next = addr_0;
			  else state_next = idle;
		
		addr_0:		if(valid) state_next = addr_1;
					else if(cnt_max) state_next = idle;
					else state_next = addr_0;
	
		addr_1:		if(valid) state_next = addr_2;
					else if(cnt_max) state_next = idle;
					else state_next = addr_1;
	
		addr_2:		if(valid) state_next = addr_3;
					else if(cnt_max) state_next = idle;
					else state_next = addr_2;
	
		addr_3:		if(valid) state_next = data_0;
					else if(cnt_max) state_next = idle;
					else state_next = addr_3;
	
		data_0:		if(valid) state_next = data_1;
					else if(cnt_max) state_next = idle;
					else state_next = data_0;
	
		data_1:		if(valid) state_next = data_2;
					else if(cnt_max) state_next = idle;
					else state_next = data_1;
	
		data_2:		if(valid) state_next = data_3;
					else if(cnt_max) state_next = idle;
					else state_next = data_2;
	
		data_3:		if(valid) state_next = crc;
					else if(cnt_max) state_next = idle;
					else state_next = data_3;
		
		crc:		if(valid)
						if(crc_ok) state_next = write;
						else state_next = idle;
					else if(cnt_max) state_next = idle;
					else state_next = crc;
		
		write:		if(!avmm_waitrequest) state_next = idle;
					else if(write_fail)	state_next = idle;
					else state_next = write;
		
		default: 	state_next = idle;
	endcase 



	
always_ff @ (posedge clk) begin 
		if((state == data_0) && valid) avmm_writedata[7:0] <= data[7:0];
		if((state == data_1) && valid) avmm_writedata[15:8] <= data[7:0];
		if((state == data_2) && valid) avmm_writedata[23:16] <= data[7:0];
		if((state == data_3) && valid) avmm_writedata[31:24] <= data[7:0];
	end 

	

always_ff @ (posedge clk) begin 
		if((state == addr_0) && valid) avmm_address[7:0] <= data[7:0];
		if((state == addr_1) && valid) avmm_address[15:8] <= data[7:0];
		if((state == addr_2) && valid) avmm_address[23:16] <= data[7:0];	
		if((state == addr_3) && valid) avmm_address[31:24] <= data[7:0];	
	end


assign avsi_ready = (state == write) ? 1'b0:1'b1;
assign avmm_write = state == write;




endmodule 