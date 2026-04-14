(* keep_hierarchy = "yes" *)
module systolic_array_8x8 (
    input clk,
    input rst,
    input v_in,                 
    input [63:0] row_in,        
    input [63:0] col_in,        
    output [2047:0] pe_out_flat 
);

    // Internal connections
    wire [7:0] h [8:0][8:0];
    wire [7:0] v [8:0][8:0];
    wire v_prop [8:0][8:0];

    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign h[i][0] = row_in[(i*8)+7 : i*8];
            assign v[0][i] = col_in[(i*8)+7 : i*8];
            
            assign v_prop[i][0] = (i == 0) ? v_in : v_prop[i-1][0]; 
            assign v_prop[0][i] = (i == 0) ? v_in : v_prop[0][i-1];
        end
    endgenerate

    generate
        for (i = 0; i < 8; i = i + 1) begin : row
            for (j = 0; j < 8; j = j + 1) begin : col
                // Prevent Vivado from optimizing the instance ports
                (* dont_touch = "yes" *)
                pe pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .hin(h[i][j]),
                    .vin(v[i][j]),
                    .v_in( (i == 0) ? v_prop[0][j] : v_prop[i][j] ), 
                    .hout(h[i][j+1]),
                    .vout(v[i+1][j]),
                    .v_out(v_prop[i+1][j+1]), 
                    .acc(pe_out_flat[((i*8+j)*32)+31 : (i*8+j)*32])
                );
            end
        end
    endgenerate

endmodule