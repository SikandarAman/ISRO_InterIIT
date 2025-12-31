// stdcell_stubs.v
// Minimal functional models for missing standard cells.
// NOTE: For functional simulation only (no real timing).

`timescale 1ns/1ps
`celldefine

module DFFHQXL (
    input  CK,
    input  D,
    output reg Q
);
  // Simple positive-edge D flip-flop, no reset.
  always @(posedge CK) begin
    Q <= D;
  end
endmodule

`endcelldefine

