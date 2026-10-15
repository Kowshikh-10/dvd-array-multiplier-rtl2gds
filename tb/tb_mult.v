`timescale 1ns/1ps

module tb_mult;

reg        clk;
reg        rst_n;
reg  [3:0] a;
reg  [3:0] b;
wire [7:0] p;

reg  [7:0] expected;
integer    i, k;
integer    checked;
integer    errors;

mult_array dut (
    .clk  (clk),
    .rst_n(rst_n),
    .a    (a),
    .b    (b),
    .p    (p)
);

// 10 ns clock period
initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    $dumpfile("mult.vcd");
    $dumpvars(0, tb_mult);

    checked = 0;
    errors  = 0;
    a       = 4'd0;
    b       = 4'd0;

    // hold reset low for the first 2 clock cycles
    rst_n = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    for (i = 0; i < 16; i = i + 1) begin
        for (k = 0; k < 16; k = k + 1) begin
            // apply inputs on the falling edge, away from the rising edge
            a        = i[3:0];
            b        = k[3:0];
            expected = i * k;

            // edge 1: a, b captured into a_reg, b_reg; edge 2: product captured into p
            repeat (2) @(posedge clk);

            // compare on the next falling edge, after p has settled
            // (also keeps the gate-level simulation free of races)
            @(negedge clk);
            checked = checked + 1;
            if (p !== expected) begin
                errors = errors + 1;
                $display("MISMATCH at %0d ns: a=%0d b=%0d expected=%0d got=%0d",
                         $time, a, b, expected, p);
            end
        end
    end

    if (errors == 0)
        $display("PASS: %0d vectors checked, %0d errors", checked, errors);
    else
        $display("FAIL: %0d vectors checked, %0d errors", checked, errors);

    $finish;
end

endmodule
