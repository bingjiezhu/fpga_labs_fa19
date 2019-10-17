module fifo #(
    parameter data_width = 8,
    parameter fifo_depth = 32,
    parameter addr_width = $clog2(fifo_depth)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [data_width-1:0] din,
    output full,

    // Read side
    input rd_en,
    output reg [data_width-1:0] dout,
    output  empty
);
    reg [addr_width-1 :0] rp=0, wp=0, compare; 
    reg [data_width-1 :0] fifo_reg [fifo_depth-1 : 0];
     
    
    assign empty = (compare==0) ? 1: 0;
    assign full = (compare==fifo_depth-1) ? 1: 0;
    
    always@(posedge clk)
        begin
            // rst, wr_en, rd_en operation 
            if(rst)
                begin 
                rp<=0;
                wp<=0;
                end
            else if(wr_en && !full)
                begin
                    fifo_reg[wp]=din;
                    wp <= wp+1;
                end
            else if (rd_en && !empty)
                begin
                    dout <= fifo_reg[rp];
                    rp <= rp+1;
                end 
            else ;
            
            // compare 
            if(rp>wp)
                compare = rp-wp;
            else if (rp<wp)
                compare = wp-rp;
            else ;
            
            // set wp,rp to 0 when reaches the top  
            if(wp == fifo_depth-1)
                wp <=0;
            else if(rp == fifo_depth-1)
                rp <=0;
            else ;
                
        end
            
    
    
    
    
endmodule
