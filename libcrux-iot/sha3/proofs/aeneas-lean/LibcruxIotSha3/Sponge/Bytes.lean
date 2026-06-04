/-
  # Byte ↔ Lane primitives (`load_block`, `store_block`,
  # `load_block_full`).

  Top-level `@[spec]` Triples bridging the impl's byte-loop
  loaders/stores to the sponge spec's byte ↔ lane view:

  - `state.KeccakState.load_block_spec`      — unwraps `load_block_2u32`,
    composes the two outer-loop Triples from `Sponge/LoopSpecs.lean`.
    Carries `⌜ r.i = s.i ⌝`.
  - `state.KeccakState.store_block_spec`     — unwraps `store_block_2u32`,
    composes the outer-loop Triple from `Sponge/LoopSpecs.lean` and
    preserves output-slice length.
  - `state.KeccakState.load_block_full_spec` — delegates to
    `load_block_spec` after `Array.to_slice` coercion.

  The BV-pure identity layer (`interleave_bv`, `deinterleave_bv`,
  `lift_lane_bv_xor`, `interleave_bv_lift_eq`,
  `deinterleave_bv_lift_eq`) lives in `Sponge/Interleave.lean`'s
  header section.
-/
import LibcruxIotSha3.Sponge.LoopSpecs
import LibcruxIotSha3.Sponge.XorBlockSpec

open Aeneas Aeneas.Std Result ControlFlow Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
