module rom(
    input wire clk,
    input wire ce,
    input wire[11:0] addr,
    output reg[31:0] inst
);

    always @(posedge clk) begin
        if (ce == 1'b0) begin
            inst <= 32'h00000000; 
        end else begin
            case (addr)
                10'h0: inst <= 32'h00000000;
                10'h1: inst <= 32'h10000001;
                10'h2: inst <= 32'h00000000;
                10'h3: inst <= 32'h3c08beff;
                10'h4: inst <= 32'h3508fff8;
                10'h5: inst <= 32'h240900ff;
                10'h6: inst <= 32'had090000;
                10'h7: inst <= 32'h3c10be00;
                10'h8: inst <= 32'h240f0000;
                10'h9: inst <= 32'h020f7821;
                10'ha: inst <= 32'h8de90000;
                10'hb: inst <= 32'h8def0004;
                10'hc: inst <= 32'h000f7c00;
                10'hd: inst <= 32'h012f4825;
                10'he: inst <= 32'h3c08464c;
                10'hf: inst <= 32'h3508457f;
                10'h10: inst <= 32'h11090003;
                10'h11: inst <= 32'h00000000;
                10'h12: inst <= 32'h10000042;
                10'h13: inst <= 32'h00000000;
                10'h14: inst <= 32'h240f0038;
                10'h15: inst <= 32'h020f7821;
                10'h16: inst <= 32'h8df10000;
                10'h17: inst <= 32'h8def0004;
                10'h18: inst <= 32'h000f7c00;
                10'h19: inst <= 32'h022f8825;
                10'h1a: inst <= 32'h240f0058;
                10'h1b: inst <= 32'h020f7821;
                10'h1c: inst <= 32'h8df20000;
                10'h1d: inst <= 32'h8def0004;
                10'h1e: inst <= 32'h000f7c00;
                10'h1f: inst <= 32'h024f9025;
                10'h20: inst <= 32'h3252ffff;
                10'h21: inst <= 32'h240f0030;
                10'h22: inst <= 32'h020f7821;
                10'h23: inst <= 32'h8df30000;
                10'h24: inst <= 32'h8def0004;
                10'h25: inst <= 32'h000f7c00;
                10'h26: inst <= 32'h026f9825;
                10'h27: inst <= 32'h262f0008;
                10'h28: inst <= 32'h000f7840;
                10'h29: inst <= 32'h020f7821;
                10'h2a: inst <= 32'h8df40000;
                10'h2b: inst <= 32'h8def0004;
                10'h2c: inst <= 32'h000f7c00;
                10'h2d: inst <= 32'h028fa025;
                10'h2e: inst <= 32'h262f0010;
                10'h2f: inst <= 32'h000f7840;
                10'h30: inst <= 32'h020f7821;
                10'h31: inst <= 32'h8df50000;
                10'h32: inst <= 32'h8def0004;
                10'h33: inst <= 32'h000f7c00;
                10'h34: inst <= 32'h02afa825;
                10'h35: inst <= 32'h262f0004;
                10'h36: inst <= 32'h000f7840;
                10'h37: inst <= 32'h020f7821;
                10'h38: inst <= 32'h8df60000;
                10'h39: inst <= 32'h8def0004;
                10'h3a: inst <= 32'h000f7c00;
                10'h3b: inst <= 32'h02cfb025;
                10'h3c: inst <= 32'h12800010;
                10'h3d: inst <= 32'h00000000;
                10'h3e: inst <= 32'h12a0000e;
                10'h3f: inst <= 32'h00000000;
                10'h40: inst <= 32'h26cf0000;
                10'h41: inst <= 32'h000f7840;
                10'h42: inst <= 32'h020f7821;
                10'h43: inst <= 32'h8de80000;
                10'h44: inst <= 32'h8def0004;
                10'h45: inst <= 32'h000f7c00;
                10'h46: inst <= 32'h010f4025;
                10'h47: inst <= 32'hae880000;
                10'h48: inst <= 32'h26d60004;
                10'h49: inst <= 32'h26940004;
                10'h4a: inst <= 32'h26b5fffc;
                10'h4b: inst <= 32'h1ea0fff4;
                10'h4c: inst <= 32'h00000000;
                10'h4d: inst <= 32'h26310020;
                10'h4e: inst <= 32'h2652ffff;
                10'h4f: inst <= 32'h1e40ffd7;
                10'h50: inst <= 32'h00000000;
                10'h51: inst <= 32'h02600008;
                10'h52: inst <= 32'h00000000;
                10'h53: inst <= 32'h1000ffff;
                10'h54: inst <= 32'h00000000;
                10'h55: inst <= 32'h1000ffff;
                10'h56: inst <= 32'h00000000;
                default: inst <= 32'h00000000;
            endcase
        end
    end

endmodule // rom