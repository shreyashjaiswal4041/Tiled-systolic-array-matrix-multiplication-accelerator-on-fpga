module pe (
    input clk, rst,
    input [7:0] hin, vin,
    input v_in,             // Valid bit input
    output reg [7:0] hout, vout,
    output reg v_out,       // Valid bit output
    
    // DONT_TOUCH ensures this register is physically kept in the hardware 
    // even if the top-level doesn't seem to use its value.
    (* dont_touch = "yes" *) output reg [31:0] acc
);
    // Force the use of DSP slices for the multiplication
    (* use_dsp48 = "yes" *) reg [15:0] product_reg;
    
    reg [7:0] h_reg, v_reg;
    reg v_stage;            // Pipeline the valid bit

    always @(posedge clk) begin
        if (rst) begin
            acc         <= 32'b0;
            product_reg <= 16'b0;
            h_reg       <= 8'b0;
            v_reg       <= 8'b0;
            hout        <= 8'b0;
            vout        <= 8'b0;
            v_stage     <= 1'b0;
            v_out       <= 1'b0;
        end else begin
            // STAGE 1: Capture and Multiply
            h_reg       <= hin;
            v_reg       <= vin;
            product_reg <= hin * vin;
            v_stage     <= v_in;    // Valid bit follows data into stage 1

            // STAGE 2: Accumulate and Pass
            // Using the pipelined valid signal to guard the addition
            if (v_stage) begin
                acc     <= acc + product_reg;
            end
            
            v_out       <= v_stage; // Pass valid bit to next PE
            hout        <= h_reg;
            vout        <= v_reg;
        end
    end
endmodule