module piano #(
    parameter CLOCK_FREQ = 125_000_000
) (
    input clk,
    input rst,

    input [2:0] buttons,
    input [1:0] switches,
    output [5:0] leds,

    output [7:0] ua_tx_din,
    output ua_tx_wr_en,
    input ua_tx_full,

    input [7:0] ua_rx_dout,
    input ua_rx_empty,
    output ua_rx_rd_en,

    output [23:0] tone,
    output volume
);
	assign volume = 1; 
	parameter S0 = 2'b00; // IDLE  
	parameter S1 = 2'b01; // RECEIVE 
	parameter S2 = 2'b10; // TRANSMIT 
	parameter S3 = 2'b11; // PLAYING


	wire [7:0] last_address;
	reg [7:0] address_reg;
	reg [7:0] address;
	reg [31:0] note_length;
	reg [31:0]counter;

	piano_scale_rom tone_rom(
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
		S1: if (!ua_tx_full) next_state = S2; else next_state = S1;
		S2: next_state = S3;
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
			note_ <= 32'd25000000;
		end
	current_state <= next_state;
	case (current_state)
		S0: begin ua_rx_rd_en<=0; ua_tx_wr_en<=0; counter<=0; end
		S1: begin ua_rx_rd_en<=1; ua_tx_wr_en<=0; ua_tx_din <= ua_rx_dout; address_reg <= ua_rx_dout; counter<=0; end
		S2: begin ua_tx_wr_en<=1; ua_rx_rd_en<=0; counter <=0; end
		S3: begin ua_rx_rd_en<=0; ua_tx_wr_en<=0; leds[0] <= 1; address <= address_reg; if(counter< note_length) counter<= counter+1; end 
		default: begin ua_rx_rd_en<=0; ua_tx_wr_en<=0; counter<=0;end 
	endcase
// Variable note length 
	if (switches[0] && buttons[0]) 
			 note_length <=note_length - 32'd1000000;
	else if (!switches[0] && buttons[0]) 
			note_length <=note_length + 32'd1000000;
 	else ;
	end 

endmodule
