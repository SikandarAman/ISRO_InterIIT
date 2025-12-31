`timescale 1ns/1ps

module tb_postlayout;

  // ----- parameters -----
  localparam CLK_PERIOD_NS = 1000; // 1 MHz clock (safe for heavy post-layout sims)
  localparam RESET_CYCLES  = 100;  // keep reset asserted for 100 cycles
  localparam SIM_TIMEOUT_CYCLES = 5000000; // safety timeout

  // ----- DUT interface signals (generic) -----
  logic clk;
  logic reset;

  // Generic data ports - adapt names/widths as per your DUT.
  // If your top module has different port names, either:
  // 1) change these names to match the DUT, or
  // 2) instantiate DUT with explicit port mapping below.
  logic [31:0] din;
  logic        din_valid;
  logic [31:0] dout;
  logic        dout_valid;

  // ----- file I/O and golden vector handling -----
  integer in_fd;
  integer out_fd;
  integer golden_fd;
  integer status;
  string  line;
  integer cycle_count;
  bit mismatch_found = 0;

  // ----- DUT instantiation -----
  // Default: instantiate by name and rely on `.*` to connect by name.
  // This requires your top-level netlist ports to have the same names as above.
  // If not, replace with explicit port mapping:
  //
  // integrator_chain_with_downsampler_comb_nohold_with_fir128 uut (
  //   .CLK(clk),
  //   .RESET(reset),
  //   .DIN(din),
  //   .DIN_VALID(din_valid),
  //   .DOUT(dout),
  //   .DOUT_VALID(dout_valid)
  // );
  //
  integrator_chain_with_downsampler_comb_nohold_with_fir128 uut (.*);

`ifdef POST_LAYOUT
  // SDF annotation in-case you prefer inline annotation instead of sdf.cmd
  initial begin
    // If you use inline annotation, change the path to your SDF
    // $sdf_annotate("design_post.sdf", uut);
  end
`endif

  // ----- clock generator -----
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // ----- reset and simulation control -----
  initial begin
    reset = 1'b1;
    din = '0;
    din_valid = 1'b0;
    cycle_count = 0;

    repeat (RESET_CYCLES) @(posedge clk);
    reset = 1'b0;

    // Open I/O files
    // Input stimulus CSV: columns: sample_value (decimal) or hex (0x...)
    in_fd     = $fopen("stimulus.csv", "r");
    out_fd    = $fopen("postlayout_out.csv", "w");
    golden_fd = $fopen("golden_out.csv", "r"); // optional golden to compare

    if (in_fd == 0) begin
      $display("ERROR: Could not open stimulus.csv");
      $finish;
    end

    $display("[%0t] Starting post-layout simulation", $time);

    // drive inputs from stimulus file
    while (!$feof(in_fd) && cycle_count < SIM_TIMEOUT_CYCLES) begin
      // read one line
      status = $fgets(line, in_fd);
      if (status <= 0) break;

      // parse integer from line (handles hex 0x... or decimal)
      // trim whitespace
      string s = line;
      s = s.trim();
      if (s.len() == 0) begin
         // skip empty
         @(posedge clk);
         cycle_count++;
         continue;
      end

      // convert to integer
      int signed parsed;
      if (s.substr(0,1) == "0" && s.len() > 1 && (s.substr(0,2) == "0x" || s.substr(0,2) == "0X")) begin
        // hex
        $sscanf(s, "%x", parsed);
      end else begin
        $sscanf(s, "%d", parsed);
      end

      // drive input for one cycle (or more if needed)
      din = parsed;
      din_valid = 1'b1;
      @(posedge clk);
      cycle_count++;

      // deassert valid for one cycle
      din_valid = 1'b0;
      din = '0;
    end

    // finished driving stimulus: wait some cycles for pipeline to flush
    repeat (2000) @(posedge clk);

    // close stimulus
    $fclose(in_fd);

    // give extra time for outputs to be produced
    repeat (2000) @(posedge clk);

    $display("[%0t] Post-layout simulation finished driving stimuli.", $time);

    // close files
    $fclose(out_fd);
    $fclose(golden_fd);

    // small pause then finish
    #1000;
    $finish;
  end

  // ----- capture DUT outputs to CSV and compare to golden (if available) -----
  initial begin : capture_and_check
    // wait for reset deassertion
    wait (reset == 1'b0);
    @(posedge clk);

    forever begin
      @(posedge clk);
      if (dout_valid) begin
        // write decimal output; change format if needed
        $fwrite(out_fd, "%0d\n", dout);
        // optional compare: read golden line and compare
        // NOTE: reading golden requires golden_fd opened and not EOF
        if (golden_fd != 0 && !$feof(golden_fd)) begin
          string gline;
          int gval;
          int r = $fgets(gline, golden_fd);
          if (r > 0) begin
            gline = gline.trim();
            if (gline.len() > 0) begin
              $sscanf(gline, "%d", gval);
              if (gval !== dout) begin
                $display("Mismatch at time %0t: expected=%0d got=%0d", $time, gval, dout);
                mismatch_found = 1;
              end
            end
          end
        end
      end
    end
  end

  // ----- X-check and simulation timeout -----
  initial begin
    // dump VCD/VPD for waveform inspection
    $dumpfile("postlayout.vcd");
    $dumpvars(0, tb_postlayout);

    // timeout safety
    repeat (SIM_TIMEOUT_CYCLES) @(posedge clk);
    $display("SIM_TIMEOUT reached at %0t", $time);
    $finish;
  end

  // ----- final reporting -----
  final begin
    if (mismatch_found) begin
      $display("POST-LAYOUT: MISMATCHES FOUND. Check postlayout_out.csv and golden files.");
    end else begin
      $display("POST-LAYOUT: No mismatches detected.");
    end
  end

endmodule

