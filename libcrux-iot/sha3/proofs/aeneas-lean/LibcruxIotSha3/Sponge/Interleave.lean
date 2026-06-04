/-
  # Aeneas-Result lifts of `Lane2U32.interleave` / `Lane2U32.deinterleave`.

  Bridges the impl's 13-stage bit-deposit code (`Extraction/Funs.lean` lines
  116-163 and 3993-4065) to the pure-`BitVec` models `interleave_bv` /
  `deinterleave_bv` defined at the top of this file.

  Both Triples post:
  - `interleave_spec`:  the two output halves equal `interleave_bv  lo hi`.
  - `deinterleave_spec`: the two output halves equal `deinterleave_bv e o`.

  Composing with `interleave_bv_lift_eq` / `deinterleave_bv_lift_eq` (also
  in this file) recovers the LE-concatenated `u64` form consumed by the
  byte-bridge layer in `Sponge/Bytes.lean`.

  Technique: a pure `hax_mvcgen` walk through ~30 `Std.U32`/`Std.U64` ops,
  finishing with a single `BitVec` equality closed by `bv_decide` (after
  exposing the underlying `.bv` content through `Std.U32.bv_eq_imp_eq` /
  `Std.U64.bv_eq_imp_eq` + `UScalar.bv_*`).

  The BV-pure identity layer (`interleave_bv`, `deinterleave_bv`,
  `lift_lane_bv_xor`, `interleave_bv_lift_eq`, `deinterleave_bv_lift_eq`)
  lives in this file (rather than in `Sponge/Bytes.lean`) so that
  `Sponge/Bytes.lean` can depend on `Sponge/LoopSpecs.lean` (which itself
  imports this file) without an import cycle.
-/
import LibcruxIotSha3.Sponge.Opaque

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
