`timescale 1ns/1ps

module tb_postlayout;

  reg clk;
  reg reset;
  reg [31:0] xin;

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

  integer in_fd;
  integer out_fd;
  integer parsed;
  integer status;
  integer read_count;
  integer fir_count;
  integer cycle_count;

  // DUT ---------------------------------------------------------
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

  // SDF ---------------------------------------------------------
  initial begin
    $display("Annotating SDF...");
    $sdf_annotate("design_post.sdf", uut);
  end

  // Clock -------------------------------------------------------
  initial begin
    clk = 0;
    forever #500 clk = ~clk;
  end

  // Stimulus ----------------------------------------------------
  initial begin
    reset = 1;
    xin   = 0;

    repeat (20) @(posedge clk);
    reset = 0;

    in_fd = $fopen("stimulus.csv", "r");
    if (in_fd == 0) begin
      $display("ERROR: cannot open stimulus.csv");
      $finish;
    end

    out_fd = $fopen("postlayout_out.csv", "w");
    if (out_fd == 0) begin
      $display("ERROR: cannot open output file");
      $finish;
    end

    read_count  = 0;
    fir_count   = 0;
    cycle_count = 0;

    // Read-loop (pure Verilog-2001 safe)
    status = $fscanf(in_fd, "%d", parsed);
    while (status == 1) begin

      xin = parsed;
      read_count = read_count + 1;

      @(posedge clk);
      cycle_count = cycle_count + 1;

      status = $fscanf(in_fd, "%d", parsed);
    end

    $display("INFO: Finished reading. Samples read = %0d", read_count);

    // Allow FIR pipeline to flush
    repeat (2000) @(posedge clk);

    $fclose(in_fd);
    $fclose(out_fd);

    $display("SIM DONE: cycles=%0d  samples=%0d  fir_outputs=%0d",
             cycle_count, read_count, fir_count);

    $finish;
  end

  // Output capture ------------------------------------------------
  always @(posedge clk) begin
    if (!reset && fir_valid) begin
      fir_count = fir_count + 1;
      $fwrite(out_fd, "%0d\n", fir_out);
    end
  end

  // VCD dump ------------------------------------------------------
  initial begin
    $dumpfile("postlayout.vcd");
    $dumpvars(0, tb_postlayout);
  end

endmodule

