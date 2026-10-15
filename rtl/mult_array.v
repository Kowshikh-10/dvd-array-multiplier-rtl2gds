`timescale 1ns/1ps

module mult_array(
    input clk,
    input rst_n,
    input [3:0]a,
    input [3:0]b,
    output reg [7:0]p
);

reg [3:0] a_reg;
reg [3:0] b_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        a_reg <= 4'b0;
        b_reg <= 4'b0;
    end
    else begin
        a_reg <= a;
        b_reg <= b;
    end
end

wire [3:0] pp0, pp1, pp2, pp3;   // partial products: ppi[j] = a_reg[j] & b_reg[i]
wire [3:0] r0, r1, r2;           // bits passed down to the next row
wire [3:0] s1, s2, s3;           // sum outputs of rows 1-3
wire [4:0] c1, c2, c3;           // carry chains of rows 1-3

assign c1[0] = 1'b0;
assign c2[0] = 1'b0;
assign c3[0] = 1'b0;

assign r0 = {1'b0,  pp0[3:1]};
assign r1 = {c1[4], s1[3:1]};
assign r2 = {c2[4], s2[3:1]};

genvar j;
generate
    for(j = 0; j < 4; j = j + 1) begin : col
        assign pp0[j] = a_reg[j] & b_reg[0];
        assign pp1[j] = a_reg[j] & b_reg[1];
        assign pp2[j] = a_reg[j] & b_reg[2];
        assign pp3[j] = a_reg[j] & b_reg[3];

        full_adder fa1 (.a(pp1[j]), .b(r0[j]), .cin(c1[j]), .sum(s1[j]), .cout(c1[j+1]));
        full_adder fa2 (.a(pp2[j]), .b(r1[j]), .cin(c2[j]), .sum(s2[j]), .cout(c2[j+1]));
        full_adder fa3 (.a(pp3[j]), .b(r2[j]), .cin(c3[j]), .sum(s3[j]), .cout(c3[j+1]));
    end
endgenerate

// p[0] = pp0[0], p[1] = s1[0], p[2] = s2[0], p[3] = s3[0], p[7:4] = {c3[4], s3[3:1]}
wire [7:0] product;
assign product = {c3[4], s3[3:1], s3[0], s2[0], s1[0], pp0[0]};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        p <= 8'b0;
    else
        p <= product;
end

endmodule
