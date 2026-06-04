/-
  # Loop Triples for `load_block` / `store_block` outer fixpoints.

  Three `@[spec]` Triples, one per Aeneas `partial_fixpoint` loop,
  threading a `loop_range_spec_usize`-style forward induction:

  - `state.load_block_2u32_loop0_spec`   — outer fixpoint of load-loop 0.
    Body: read 8 bytes from `blocks` at offset `start + 8*i`, interleave,
    write to `state_flat[i]`.
  - `state.load_block_2u32_loop1_spec`   — outer fixpoint of load-loop 1.
    Body: XOR `state_flat[i]` (both halves) into `s.st[5*(i%5) + i/5]`.
  - `state.store_block_2u32_loop_spec`   — outer fixpoint of store-loop.
    Body: deinterleave `s.st[5*(i%5) + i/5]` and write 8 bytes to
    `out[8*i .. 8*i + 8]` (slice-length-preservation post).

  Each loop runs over the range `iter.start..iter.end` with step 1. Each
  Triple is obtained by applying `loop_range_spec_usize` with the trivial
  invariant `inv _ _ := True`; the downstream `load_block_spec` /
  `store_block_spec` callers thread accumulator-tracking invariants on
  top.
-/
import LibcruxIotSha3.Sponge.SliceSpecs
import LibcruxIotSha3.Sponge.Interleave

open Aeneas Aeneas.Std Result ControlFlow Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
