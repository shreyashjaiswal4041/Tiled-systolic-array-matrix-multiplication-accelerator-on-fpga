`timescale 1ns / 1ps

module tiled_top (
    input clk,
    input btnC,         // Global Reset
    input btnU,         // Start Calculation
    input [15:0] sw,    
    output [15:0] led,  
    output reg [7:0] an,    
    output reg [6:0] seg    
);

    // --- Control Registers ---
    (* keep = "true" *) reg [11:0] addr = 0;
    (* keep = "true" *) reg [11:0] timer = 0;
    reg processing = 0;
    reg [7:0]  drain_count = 0;
    reg [31:0] result_snapshot = 0;
    
    reg v_in_gate = 0;
    reg auto_rst = 0;  
    reg [63:0] r_p = 0;
    reg [63:0] c_p = 0;
    
    wire [127:0] dout;
    
    // Attribute to keep the hierarchy visible in utilization reports
    (* keep_hierarchy = "yes" *)
    wire [2047:0] flat_outputs;
    
    // Logic to prevent optimization: 
    // led[0] shows activity, led[1] ensures all PEs are technically "used"
    assign led[0] = processing;
    assign led[1] = ^flat_outputs; 
    assign led[15:2] = 0;

    // --- The Synchronized State Machine (Logic Preserved) ---
    always @(posedge clk) begin
        if (btnC) begin
            addr <= 0;
            timer <= 0;
            processing <= 0;
            drain_count <= 0;
            result_snapshot <= 0;
            v_in_gate <= 0;
            auto_rst <= 1; 
        end else if (btnU) begin
            processing <= 1;
            addr <= 0;
            timer <= 0;
            drain_count <= 0;
            v_in_gate <= 0;
            auto_rst <= 1; 
        end else if (processing) begin
            r_p <= dout[127:64];
            c_p <= dout[63:0];

            if (timer < 500) begin 
                timer <= timer + 1;
                
                if (timer < 20) begin
                    auto_rst <= 1;
                    addr <= 0;
                end else begin
                    auto_rst <= 0;
                    
                    if (addr < 255) 
                        addr <= addr + 1;

                    // Standard Synchronized Window (Cycle 23 to 279)
                    if (timer >= 23 && timer < (23 + 256))
                        v_in_gate <= 1'b1;
                    else
                        v_in_gate <= 1'b0;
                end
            end 
            else begin
                if (drain_count < 150) begin
                    drain_count <= drain_count + 1;
                end else begin
                    processing <= 0;
                    // Taking PE(0,0) result (Bits 31:0)
                    result_snapshot <= flat_outputs[31:0]; 
                end
            end
        end else begin
            auto_rst <= 0;
        end
    end

    // --- BRAM Instance ---
    matrix_mem your_bram_inst (
        .clka(clk),
        .ena(1'b1), 
        .addra(addr),
        .douta(dout)
    );

    // --- Systolic Array Instance ---
    (* keep_hierarchy = "yes" *)
    systolic_array_8x8 core_8x8 (
        .clk(clk),
        .rst(btnC | auto_rst), 
        .v_in(v_in_gate), 
        .row_in(r_p),
        .col_in(c_p),
        .pe_out_flat(flat_outputs)
    );

    // --- Seven Segment Display Logic ---
    reg [19:0] refresh = 0; 
    always @(posedge clk) begin
        refresh <= refresh + 1;
        an <= 8'b11111111; 
        case(refresh[19:17])
            3'b000: begin an[0] <= 1'b0; hex_to_seg(result_snapshot[3:0]);   end
            3'b001: begin an[1] <= 1'b0; hex_to_seg(result_snapshot[7:4]);   end
            3'b010: begin an[2] <= 1'b0; hex_to_seg(result_snapshot[11:8]);  end
            3'b011: begin an[3] <= 1'b0; hex_to_seg(result_snapshot[15:12]); end
            3'b100: begin an[4] <= 1'b0; hex_to_seg(result_snapshot[19:16]); end
            3'b101: begin an[5] <= 1'b0; hex_to_seg(result_snapshot[23:20]); end
            3'b110: begin an[6] <= 1'b0; hex_to_seg(result_snapshot[27:24]); end
            3'b111: begin an[7] <= 1'b0; hex_to_seg(result_snapshot[31:28]); end
        endcase
    end

    task hex_to_seg(input [3:0] val);
        case(val)
            4'h0: seg <= 7'b1000000; 4'h1: seg <= 7'b1111001;
            4'h2: seg <= 7'b0100100; 4'h3: seg <= 7'b0110000;
            4'h4: seg <= 7'b0011001; 4'h5: seg <= 7'b0010010;
            4'h6: seg <= 7'b0000010; 4'h7: seg <= 7'b1111000;
            4'h8: seg <= 7'b0000000; 4'h9: seg <= 7'b0010000;
            4'hA: seg <= 7'b0001000; 4'hB: seg <= 7'b0000011;
            4'hC: seg <= 7'b1000110; 4'hD: seg <= 7'b0100001;
            4'hE: seg <= 7'b0000110; 4'hF: seg <= 7'b0001110;
            default: seg <= 7'b1111111;
        endcase
    endtask
endmodule