`timescale 1ns/1ps

module tb_postlayout;

reg clk;
reg reset;
reg [31:0] xin;  // <-- set width correctly based on your RTL


  // DUT interface
  reg  [31:0] din;
  reg         din_valid;
  wire [31:0] y1_out;
  wire [31:0] y2_out;
  wire [31:0] ds_out;
  wire        ds_valid;
  wire [31:0] comb1_out;
  wire        comb1_valid;
  wire [31:0] comb2_out;
  wire        comb2_valid;
  wire [31:0] fir_out;
  wire        fir_valid;
//  wire        dout_valid;     // if DUT drives this

  integer in_fd;
  integer out_fd;
  integer parsed;
  integer cycle_count;

  // DUT instantiation
integrator_chain_with_downsampler_comb_nohold_with_fir128 uut (
    .clk        (clk),
    .reset      (reset),
    .xin        (xin),

    .y1_out     (y1_out),
    .y2_out     (y2_out),
    .ds_out     (ds_out),
    .ds_valid   (ds_valid),

    .comb1_out  (comb1_out),
    .comb1_valid(comb1_valid),

    .comb2_out  (comb2_out),
    .comb2_valid(comb2_valid),

    .fir_out    (fir_out),
    .fir_valid  (fir_valid)
);

  // SDF annotation (post-layout)
  initial begin
    $display("Annotating SDF...");
    $sdf_annotate("design_post.sdf", uut);
  end

  // clock
  initial begin
    clk = 0;
    forever #500 clk = ~clk;  // 1 MHz
  end

  // reset + stimulus
  initial begin
    reset = 1;
    din = 0;
    din_valid = 0;

    repeat (20) @(posedge clk);
    reset = 0;

    in_fd  = $fopen("stimulus.csv", "r");
    out_fd = $fopen("postlayout_out.csv", "w");

    cycle_count = 0;

    while (!$feof(in_fd)) begin
      $fscanf(in_fd, "%d\n", parsed);

      din       = parsed;
      din_valid = 1;

      @(posedge clk);
      cycle_count = cycle_count + 1;

      din_valid = 0;
    end

    repeat (2000) @(posedge clk);

    $fclose(in_fd);
    $fclose(out_fd);

    $display("Simulation completed.");
    $finish;
  end

  // capture output
  always @(posedge clk) begin
    if (!reset && fir_valid) begin
      $fwrite(out_fd, "%0d\n", fir_out);
    end
  end

  // dump waves
  initial begin
    $dumpfile("postlayout.vcd");
    $dumpvars(0, tb_postlayout);
  end

endmodule

