module piano #(
    parameter CLOCK_FREQ = 125_000_000
) (
    input clk,
    input rst,

    input [2:0] buttons,
    input [1:0] switches,
    output reg [5:0] leds,

    output reg [7:0] ua_tx_din,
    output reg ua_tx_wr_en,
    input ua_tx_full,

    input [7:0] ua_rx_dout,
    input ua_rx_empty,
    output reg ua_rx_rd_en,

    output [23:0] tone,
    output volume
);
	assign volume = switches[1]; 
	localparam S0 = 2'b00; // IDLE  
	localparam S1 = 2'b01; // RECEIVE 
	localparam S2 = 2'b10; // TRANSMIT 
	localparam S3 = 2'b11; // PLAYING


	wire [7:0] last_address;
	reg [7:0] address_reg =0;
	reg [7:0] address;
	reg [31:0] note_length =32'd25000000;
	reg [31:0]counter;
	reg [1:0] next_state, current_state;
	reg data_ready =0;	 // wait the fifo data
	reg data_pass =0;  // ensure data is ready to pass
	
	rom tone_rom(
	.address(address),
	.data(tone),
	.last_address(last_address)
	);
	
	

// FSM state changing
	always @(*)
	begin 
	next_state = S0;
	case (current_state)
		S0: if (!ua_rx_empty) next_state = S1; else next_state =S0;
		S1: if (!ua_tx_full && data_ready) next_state = S2; else next_state = S1;
		S2: if(data_pass) next_state = S3; else next_state =S2;
		S3:	if(counter >= note_length) next_state = S0; else next_state = S3;
		default: next_state = S0;
	endcase
	end 

// FSM output
always @(posedge clk)
	begin 
	if (rst)
		begin 
			counter<= 32'd0;
			note_length<= 32'd25000000;
			address <=0;
		end
	current_state <= next_state;
	case (current_state)
		S0: begin  data_ready<=0; address<=0; leds <= 6'b110001; ua_rx_rd_en<=0; ua_tx_wr_en<=0; counter<=0; data_pass <=0;end
		S1: begin  ua_rx_rd_en<=1; ua_tx_wr_en<=0; counter<=0; leds <= 6'b110010; data_ready <=1; data_pass <=0; if(data_ready) begin ua_rx_rd_en<=0;end  end
		S2: begin  ua_rx_rd_en<=0; leds <= 6'b110100; if(data_pass) begin ua_tx_wr_en<=1; end ua_tx_din <= ua_rx_dout; address_reg <= ua_rx_dout; counter <=0;data_pass <=1; data_ready <=0; end
		S3: begin ua_rx_rd_en<=0; ua_tx_wr_en<=0; leds <= 6'b111000; address <= address_reg; data_ready <=0; data_pass <=0; if(counter< note_length) counter<= counter+1; end 
		default: begin ua_rx_rd_en<=0; ua_tx_wr_en<=0; counter<=0; data_ready <=0; data_pass <=0;end 
	endcase

// Variable note length 
	if (switches[0] && buttons[0]) 
			 note_length <=note_length - 32'd1000000;
	else if ((!switches[0] && buttons[0] ) 
			note_length <=note_length + 32'd1000000;
 	else ;
	end 

endmodule
