`timescale 1ns/1ps
module tb_fir128;
    parameter WIDTH = 32;
    parameter OSR = 1025;
    parameter FRAC = 8;
    parameter NUM_CYCLES = 120;

    reg clk;
    reg reset;
    reg xin;

    wire [WIDTH-1:0] y1_out;
    wire [WIDTH-1:0] y2_out;
    wire [WIDTH-1:0] ds_out;
    wire ds_valid;
    wire signed [WIDTH-1:0] comb1_out;
    wire comb1_valid;
    wire signed [WIDTH-1:0] comb2_out;
    wire comb2_valid;
    wire signed [WIDTH+FRAC-1:0] fir_out;
    wire fir_valid;

    // integer temporaries for FIR printing
    reg signed [WIDTH+FRAC-1:0] tmp_fixed;
    integer intpart;
    integer frac_raw;
    integer frac_dec;

    // instantiate DUT
    integrator_chain_with_downsampler_comb_nohold_with_fir128 #(
        .WIDTH(WIDTH),
        .OSR(OSR),
        .FRAC(FRAC)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .xin(xin),
        .y1_out(y1_out),
        .y2_out(y2_out),
        .ds_out(ds_out),
        .ds_valid(ds_valid),
        .comb1_out(comb1_out),
        .comb1_valid(comb1_valid),
        .comb2_out(comb2_out),
        .comb2_valid(comb2_valid),
        .fir_out(fir_out),
        .fir_valid(fir_valid)
    );

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // VCD
    initial begin
        $dumpfile("Waveform.vcd");
        $dumpvars(0, tb_fir128);
    end

    integer i;
    initial begin
        reset = 1;
        xin = 0;

        @(posedge clk);
        @(posedge clk);
        reset = 0;

        $display("Cycle | xin | y1 | y2 | ds | comb1 | comb2 | fir");
        $display("-------------------------------------------------------------");

        for (i = 0; i < NUM_CYCLES; i = i + 1) begin

            xin = $urandom_range(0,1);
            @(posedge clk);

            // CYCLE NUMBER
            $write("%4d |  %b  | %5d | %5d | ", i, xin, y1_out, y2_out);

            // DS OUTPUT
            if (ds_valid) $write("%5d | ", ds_out);
            else          $write("  -   | ");

            // COMB1 OUTPUT
            if (comb1_valid) $write("%6d | ", comb1_out);
            else             $write("   -   | ");

            // COMB2 OUTPUT
            if (comb2_valid) $write("%6d | ", comb2_out);
            else             $write("   -   | ");

            // FIR OUTPUT (pretty printed with 2 decimal digits)
            if (fir_valid) begin
                tmp_fixed = fir_out;

                intpart  = tmp_fixed >>> FRAC;
                if (tmp_fixed < 0)
                    frac_raw = -tmp_fixed & ((1<<FRAC)-1);
                else
                    frac_raw =  tmp_fixed & ((1<<FRAC)-1);

                frac_dec = (frac_raw * 100) >>> FRAC;

                if (tmp_fixed < 0)
                    $write(" -%0d.%02d\n", intpart, frac_dec);
                else
                    $write(" %0d.%02d\n", intpart, frac_dec);
            end
            else begin
                $write("   -\n");
            end
        end

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule
