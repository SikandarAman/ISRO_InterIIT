`timescale 1ns/1ps

module integrator #(parameter WIDTH = 32) (
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  x_in,
    output reg  [WIDTH-1:0]  y_out
);
    always @(posedge clk) begin
        if (reset)
            y_out <= {WIDTH{1'b0}};
        else
            y_out <= y_out + x_in;
    end
endmodule

module integrator2 #(parameter WIDTH = 32) (
    input  wire              clk,
    input  wire              reset,
    input  wire              xin,
    output wire [WIDTH-1:0]  y_out,
    output wire [WIDTH-1:0]  z_out
);
    integrator #(.WIDTH(WIDTH)) I1 (
        .clk(clk),
        .reset(reset),
        .x_in({{(WIDTH-1){1'b0}}, xin}),
        .y_out(y_out)
    );
    integrator #(.WIDTH(WIDTH)) I2 (
        .clk(clk),
        .reset(reset),
        .x_in(y_out),
        .y_out(z_out)
    );
endmodule

module downsampler_nohold #(
    parameter WIDTH = 32,
    parameter integer OSR = 3
)(
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  din,
    output reg  [WIDTH-1:0]  dout,
    output reg               valid_out
);
    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = i;
        end
    endfunction
    localparam CNT_WIDTH = (OSR > 1) ? clog2(OSR) : 1;
    reg [CNT_WIDTH-1:0] count;
    always @(posedge clk) begin
        if (reset) begin
            count     <= {CNT_WIDTH{1'b0}};
            dout      <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (count == OSR - 1) begin
                count     <= {CNT_WIDTH{1'b0}};
                dout      <= din;
                valid_out <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule

module comb_diff_nohold #(parameter WIDTH = 32)(
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  din,
    input  wire              din_valid,
    output reg  signed [WIDTH-1:0] dout,
    output reg               dout_valid
);
    reg signed [WIDTH-1:0] prev;
    always @(posedge clk) begin
        if (reset) begin
            prev       <= {WIDTH{1'b0}};
            dout       <= {WIDTH{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= 1'b0;
            if (din_valid) begin
                dout       <= $signed(din) - prev;
                prev       <= $signed(din);
                dout_valid <= 1'b1;
            end
        end
    end
endmodule

module integrator_chain_with_downsampler_comb_nohold #(
    parameter WIDTH = 32,
    parameter integer OSR = 3
)(
    input  wire              clk,
    input  wire              reset,
    input  wire              xin,
    output wire [WIDTH-1:0]  y1_out,
    output wire [WIDTH-1:0]  y2_out,
    output wire [WIDTH-1:0]  ds_out,
    output wire signed [WIDTH-1:0] comb_out,
    output wire              ds_valid,
    output wire              comb_valid
);
    wire [WIDTH-1:0] ds_reg;
    wire ds_v;
    wire signed [WIDTH-1:0] comb1_reg;
    wire comb1_v;
    integrator2 #(.WIDTH(WIDTH)) INT2 (
        .clk(clk),
        .reset(reset),
        .xin(xin),
        .y_out(y1_out),
        .z_out(y2_out)
    );
    downsampler_nohold #(.WIDTH(WIDTH), .OSR(OSR)) DS (
        .clk(clk),
        .reset(reset),
        .din(y2_out),
        .dout(ds_reg),
        .valid_out(ds_v)
    );
    comb_diff_nohold #(.WIDTH(WIDTH)) S1 (
        .clk(clk),
        .reset(reset),
        .din(ds_reg),
        .din_valid(ds_v),
        .dout(comb1_reg),
        .dout_valid(comb1_v)
    );
    assign ds_out     = ds_reg;
    assign ds_valid   = ds_v;
    assign comb_out   = comb1_reg;
    assign comb_valid = comb1_v;
endmodule

module comb2_diff_nohold #(parameter WIDTH = 32)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire [WIDTH-1:0]        din,
    input  wire                    din_valid,
    output reg signed [WIDTH-1:0]  dout,
    output reg                     dout_valid
);
    reg signed [WIDTH-1:0] prev;
    always @(posedge clk) begin
        if (reset) begin
            prev       <= {WIDTH{1'b0}};
            dout       <= {WIDTH{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= 1'b0;
            if (din_valid) begin
                dout       <= $signed(din) - prev;
                prev       <= $signed(din);
                dout_valid <= 1'b1;
            end
        end
    end
endmodule

module fir128_nohold #(
    parameter WIDTH = 32,
    parameter integer TAPS = 128,
    parameter FRAC = 8
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire [WIDTH-1:0]             din,
    input  wire                         din_valid,
    output reg signed [WIDTH+FRAC-1:0]  dout,
    output reg                          dout_valid
);
    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = i;
        end
    endfunction
    localparam SHIFT = clog2(TAPS); // for TAPS=128 -> SHIFT=7
    localparam BUF_DEPTH = TAPS - 1;
    localparam OUTW = WIDTH + FRAC;
    integer i;
    reg signed [OUTW-1:0] buffer [0:BUF_DEPTH-1];
    reg signed [OUTW+SHIFT-1:0] sum_reg; // wider to hold sum of BUF_DEPTH entries + din_f
    reg [clog2(BUF_DEPTH+1)-1:0] ptr; // points to oldest element index
    reg signed [OUTW-1:0] pending;
    reg pending_v;
    wire signed [OUTW-1:0] din_f;
    assign din_f = $signed({1'b0, din}) <<< FRAC;
    initial begin
        // synthesis tools ignore initial for regs reset if reset logic exists,
        // but we still initialize arrays for simulator clarity; synthesis will use reset.
        for (i = 0; i < BUF_DEPTH; i = i + 1) buffer[i] = {OUTW{1'b0}};
        sum_reg = { (OUTW+SHIFT){1'b0} };
        ptr = 0;
        pending = {OUTW{1'b0}};
        pending_v = 1'b0;
    end
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < BUF_DEPTH; i = i + 1) buffer[i] <= {OUTW{1'b0}};
            sum_reg <= { (OUTW+SHIFT){1'b0} };
            ptr <= 0;
            pending <= {OUTW{1'b0}};
            pending_v <= 1'b0;
            dout <= {OUTW{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= 1'b0;
            if (pending_v) begin
                // emit pending raw sample
                dout <= pending;
                dout_valid <= 1'b1;
                // update circular buffer: replace oldest with pending
                sum_reg <= sum_reg - buffer[ptr] + pending;
                buffer[ptr] <= pending;
                // increment pointer
                if (ptr == BUF_DEPTH-1) ptr <= 0;
                else ptr <= ptr + 1;
                pending_v <= 1'b0;
            end else if (din_valid) begin
                // compute average: (sum_reg + din_f) >> SHIFT  (divide by TAPS)
                dout <= (sum_reg + din_f) >>> SHIFT;
                dout_valid <= 1'b1;
                // schedule raw sample for next cycle
                pending <= din_f;
                pending_v <= 1'b1;
            end
        end
    end
endmodule

module integrator_chain_with_downsampler_comb_nohold_with_fir128 #(
    parameter WIDTH = 32,
    parameter integer OSR = 3,
    parameter FRAC = 8
)(
    input  wire              clk,
    input  wire              reset,
    input  wire              xin,
    output wire [WIDTH-1:0]  y1_out,
    output wire [WIDTH-1:0]  y2_out,
    output wire [WIDTH-1:0]  ds_out,
    output wire              ds_valid,
    output wire signed [WIDTH-1:0] comb1_out,
    output wire              comb1_valid,
    output wire signed [WIDTH-1:0] comb2_out,
    output wire              comb2_valid,
    output wire signed [WIDTH+FRAC-1:0] fir_out,
    output wire              fir_valid
);
    integrator_chain_with_downsampler_comb_nohold #(.WIDTH(WIDTH), .OSR(OSR)) BASE_CHAIN (
        .clk(clk),
        .reset(reset),
        .xin(xin),
        .y1_out(y1_out),
        .y2_out(y2_out),
        .ds_out(ds_out),
        .comb_out(comb1_out),
        .ds_valid(ds_valid),
        .comb_valid(comb1_valid)
    );
    comb2_diff_nohold #(.WIDTH(WIDTH)) C2 (
        .clk(clk),
        .reset(reset),
        .din(comb1_out[WIDTH-1:0]),
        .din_valid(comb1_valid),
        .dout(comb2_out),
        .dout_valid(comb2_valid)
    );
    fir128_nohold #(.WIDTH(WIDTH), .TAPS(128), .FRAC(FRAC)) FIR (
        .clk(clk),
        .reset(reset),
        .din(comb2_out[WIDTH-1:0]),
        .din_valid(comb2_valid),
        .dout(fir_out),
        .dout_valid(fir_valid)
    );
endmodule
