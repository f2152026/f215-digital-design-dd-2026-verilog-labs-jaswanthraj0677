
// You w// cla64_hier.v
// BONUS -- open-ended. No detailed scaffold is provided; this is meant to
//ill likely need to modify cla4.v (or add signals alongside it) so
// that block-generate/block-propagate summaries of its own Gi, Pi signals
// are exposed as outputs, since the second-level lookahead unit below
// needs them. As with every module in this lab from Task 2 onward, every
// gate/assign you add should carry an explicit delay.
//
// Starting point (from Tutorial 3, Q4(d)):
//   - Reuse 16 four-bit CLA blocks (your cla4.v) -- their internal logic
//     doesn't change.
//   - For each block k, define:
//       Gblk_k = "this block produces a carry regardless of its incoming
//                 carry" -- a Boolean function of that block's own 4
//                 bit-level Gi, Pi signals.
//       Pblk_k = "an incoming carry sails straight through this whole
//                 block" -- likewise a function of its own Gi, Pi.
//   - Build a second-level lookahead unit -- structurally identical to
//     cla4.v, just one level up -- that computes each block's carry-in
//     directly from Gblk_0..Gblk_15, Pblk_0..Pblk_15, and cin, instead of
//     rippling block to block.
//
// To test this, wire it into dut.v as a fourth option (copy the pattern
// used for the other three) and run it through the same tb.v. Compare
// your final delay to cla64_blocked.v from Task 4.

// cla4_blk.v
// Same internal carry-lookahead logic as cla4.v, but additionally exposes
// this block's own generate/propagate summary signals:
//   Gblk = this block produces a carry regardless of its incoming carry
//   Pblk = an incoming carry sails straight through this whole block
// These do NOT depend on cin -- they are pure functions of this block's
// own a/b bits, which is exactly what the second-level lookahead needs.

module cla4_blk(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout,
  output       Gblk,
  output       Pblk
);

  wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3;
  wire t1, t2a, t2b, t3a, t3b, t3c, t4a, t4b, t4c, t4d;

  xor #(2) (p0, a[0], b[0]);
  xor #(2) (p1, a[1], b[1]);
  xor #(2) (p2, a[2], b[2]);
  xor #(2) (p3, a[3], b[3]);

  and #(2) (g0, a[0], b[0]);
  and #(2) (g1, a[1], b[1]);
  and #(2) (g2, a[2], b[2]);
  and #(2) (g3, a[3], b[3]);

  and #(2) (t1, p0, cin);
  or  #(2) (c1, g0, t1);

  and #(2) (t2a, p1, g0);
  and #(2) (t2b, p1, p0, cin);
  or  #(2) (c2, g1, t2a, t2b);

  and #(2) (t3a, p2, g1);
  and #(2) (t3b, p2, p1, g0);
  and #(2) (t3c, p2, p1, p0, cin);
  or  #(2) (c3, g2, t3a, t3b, t3c);

  and #(2) (t4a, p3, g2);
  and #(2) (t4b, p3, p2, g1);
  and #(2) (t4c, p3, p2, p1, g0);
  and #(2) (t4d, p3, p2, p1, p0, cin);
  or  #(2) (cout, g3, t4a, t4b, t4c, t4d);

  xor #(2) (sum[0], p0, cin);
  xor #(2) (sum[1], p1, c1);
  xor #(2) (sum[2], p2, c2);
  xor #(2) (sum[3], p3, c3);

  // Block generate: same terms as cout's equation, minus the cin term
  or  #(2) (Gblk, g3, t4a, t4b, t4c);

  // Block propagate: carry sails through iff every bit propagates
  and #(2) (Pblk, p3, p2, p1, p0);

endmodule

// cla64_hier.v
// BONUS -- hierarchical (two-level) 64-bit carry-lookahead adder.
//
// Design: reuse 16 four-bit CLA blocks (cla4_blk.v, same internal logic
// as cla4.v). Each block additionally exposes:
//   Gblk_k = this block produces a carry regardless of its incoming carry
//   Pblk_k = an incoming carry sails straight through this whole block
// A second-level lookahead unit -- structurally identical to cla4.v's
// carry equations, just one level up and scaled to 16 blocks instead of
// 4 bits -- computes each block's carry-in directly from
// Gblk_0..Gblk_15, Pblk_0..Pblk_15, and cin, instead of rippling
// block-to-block. This gives O(log n)-depth carry computation instead of
// cla64_blocked.v's 16-stage ripple between blocks.

module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [15:0] Gblk, Pblk;
  wire [15:1] cblk;   // cblk[k] = carry INTO block k, for k = 1..15
                       // block 0's carry-in is cin itself

// Second-level (block) carry-lookahead equations.
// Structurally identical pattern to cla4.v's carry equations, one level up:
// cblk[k] = Gblk[k-1] | Pblk[k-1].Gblk[k-2] | ... | Pblk[k-1]...Pblk[0].cin

assign #(2) cblk[1] = Gblk[0] | (Pblk[0] & cin);
assign #(2) cblk[2] =
      Gblk[1]
    | (Pblk[1] & Gblk[0])
    | (Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[3] =
      Gblk[2]
    | (Pblk[2] & Gblk[1])
    | (Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[4] =
      Gblk[3]
    | (Pblk[3] & Gblk[2])
    | (Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[5] =
      Gblk[4]
    | (Pblk[4] & Gblk[3])
    | (Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[6] =
      Gblk[5]
    | (Pblk[5] & Gblk[4])
    | (Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[7] =
      Gblk[6]
    | (Pblk[6] & Gblk[5])
    | (Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[8] =
      Gblk[7]
    | (Pblk[7] & Gblk[6])
    | (Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[9] =
      Gblk[8]
    | (Pblk[8] & Gblk[7])
    | (Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[10] =
      Gblk[9]
    | (Pblk[9] & Gblk[8])
    | (Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[11] =
      Gblk[10]
    | (Pblk[10] & Gblk[9])
    | (Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[12] =
      Gblk[11]
    | (Pblk[11] & Gblk[10])
    | (Pblk[11] & Pblk[10] & Gblk[9])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[13] =
      Gblk[12]
    | (Pblk[12] & Gblk[11])
    | (Pblk[12] & Pblk[11] & Gblk[10])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[14] =
      Gblk[13]
    | (Pblk[13] & Gblk[12])
    | (Pblk[13] & Pblk[12] & Gblk[11])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
assign #(2) cblk[15] =
      Gblk[14]
    | (Pblk[14] & Gblk[13])
    | (Pblk[14] & Pblk[13] & Gblk[12])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Gblk[11])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);

assign #(2) cout =
      Gblk[15]
    | (Pblk[15] & Gblk[14])
    | (Pblk[15] & Pblk[14] & Gblk[13])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Gblk[12])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Gblk[11])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0])
    | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);

  // 16 four-bit CLA blocks, each fed its carry-in directly from the
  // second-level lookahead above (block 0 uses top-level cin).
  cla4_blk blk0  (.a(a[3:0]),    .b(b[3:0]),    .cin(cin),      .sum(sum[3:0]),    .cout(), .Gblk(Gblk[0]),  .Pblk(Pblk[0]));
  cla4_blk blk1  (.a(a[7:4]),    .b(b[7:4]),    .cin(cblk[1]),  .sum(sum[7:4]),    .cout(), .Gblk(Gblk[1]),  .Pblk(Pblk[1]));
  cla4_blk blk2  (.a(a[11:8]),   .b(b[11:8]),   .cin(cblk[2]),  .sum(sum[11:8]),   .cout(), .Gblk(Gblk[2]),  .Pblk(Pblk[2]));
  cla4_blk blk3  (.a(a[15:12]),  .b(b[15:12]),  .cin(cblk[3]),  .sum(sum[15:12]),  .cout(), .Gblk(Gblk[3]),  .Pblk(Pblk[3]));
  cla4_blk blk4  (.a(a[19:16]),  .b(b[19:16]),  .cin(cblk[4]),  .sum(sum[19:16]),  .cout(), .Gblk(Gblk[4]),  .Pblk(Pblk[4]));
  cla4_blk blk5  (.a(a[23:20]),  .b(b[23:20]),  .cin(cblk[5]),  .sum(sum[23:20]),  .cout(), .Gblk(Gblk[5]),  .Pblk(Pblk[5]));
  cla4_blk blk6  (.a(a[27:24]),  .b(b[27:24]),  .cin(cblk[6]),  .sum(sum[27:24]),  .cout(), .Gblk(Gblk[6]),  .Pblk(Pblk[6]));
  cla4_blk blk7  (.a(a[31:28]),  .b(b[31:28]),  .cin(cblk[7]),  .sum(sum[31:28]),  .cout(), .Gblk(Gblk[7]),  .Pblk(Pblk[7]));
  cla4_blk blk8  (.a(a[35:32]),  .b(b[35:32]),  .cin(cblk[8]),  .sum(sum[35:32]),  .cout(), .Gblk(Gblk[8]),  .Pblk(Pblk[8]));
  cla4_blk blk9  (.a(a[39:36]),  .b(b[39:36]),  .cin(cblk[9]),  .sum(sum[39:36]),  .cout(), .Gblk(Gblk[9]),  .Pblk(Pblk[9]));
  cla4_blk blk10 (.a(a[43:40]),  .b(b[43:40]),  .cin(cblk[10]), .sum(sum[43:40]),  .cout(), .Gblk(Gblk[10]), .Pblk(Pblk[10]));
  cla4_blk blk11 (.a(a[47:44]),  .b(b[47:44]),  .cin(cblk[11]), .sum(sum[47:44]),  .cout(), .Gblk(Gblk[11]), .Pblk(Pblk[11]));
  cla4_blk blk12 (.a(a[51:48]),  .b(b[51:48]),  .cin(cblk[12]), .sum(sum[51:48]),  .cout(), .Gblk(Gblk[12]), .Pblk(Pblk[12]));
  cla4_blk blk13 (.a(a[55:52]),  .b(b[55:52]),  .cin(cblk[13]), .sum(sum[55:52]),  .cout(), .Gblk(Gblk[13]), .Pblk(Pblk[13]));
  cla4_blk blk14 (.a(a[59:56]),  .b(b[59:56]),  .cin(cblk[14]), .sum(sum[59:56]),  .cout(), .Gblk(Gblk[14]), .Pblk(Pblk[14]));
  cla4_blk blk15 (.a(a[63:60]),  .b(b[63:60]),  .cin(cblk[15]), .sum(sum[63:60]),  .cout(), .Gblk(Gblk[15]), .Pblk(Pblk[15]));

endmodule
