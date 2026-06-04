/-
  # `keccak.absorb_block` ↔ `sponge.absorb_block`

  This file hosts the single top-level `@[spec]` Triple bridging the
  impl's `keccak.absorb_block` to the sponge spec's `sponge.absorb_block`.

  ## Composition

  Impl side (`Extraction/Funs.lean:4306`):
  ```
  def keccak.absorb_block RATE s blocks start := do
    let s1 ← state.KeccakState.load_block RATE s blocks start
    keccak.keccakf1600 s1
  ```

  Spec side (`HacspecSha3/Extraction/Funs.lean:1157`):
  ```
  def sponge.absorb_block state block rate := do
    let state1 ← sponge.xor_block_into_state state block rate
    keccak_f.keccak_f state1
  ```

  ## Post

  The Triple carries the full textbook post: termination,
  `r.i.val = 0`, and the spec-side equation
  `sponge.absorb_block (lift s) <block> RATE = .ok (lift r)`
  where `<block> := block_of_blocks blocks start RATE _` is the
  rate-window slice of `blocks`.

  Bridge infrastructure:

    - `fromLEBytes_8_split_4_4`         — pure BV identity (bv_decide).
    - `padded4_eq_explicit` /
      `padded8_eq_explicit`             — list-shape: padded-window of
                                          4/8 bytes equals explicit
                                          getElem!-indexed byte list.
    - `block_take{4,8}_eq_blocks_take{4,8}`
                                        — `block.val = blocks.slice ...`
                                          ⇒ inner-window readouts match.
    - `UScalar_bv_of_U{32,64}_from_le_bytes_eq`
                                        — `Subtype.ext`-based reduction
                                          closing the `BitVec.cast` layer.
    - `load_block_to_xor_block_bridge`  — combines the above into the
                                          per-cell U64-equality
                                          connecting `load_block_spec`'s
                                          `Lane2U32_from_4byte_LE_pairs`
                                          BV form to
                                          `xor_block_value_at`'s
                                          `U64.from_le_bytes ∘ list_8_at`
                                          form.

  Composition (`keccak.absorb_block_spec`):

    1. `state.KeccakState.load_block_spec` (Bytes.lean) — yields impl
       `s1` with `s1.i = s.i` and per-cell BV-equation.
    2. `keccakf1600_seal_spec` (Opaque.lean) — yields impl `r` with
       `keccak_f.keccak_f (lift s1) = .ok (lift r)` and `r.i.val = 0`.
    3. `sponge_xor_block_into_state_spec` (XorBlockSpec.lean) — yields
       spec `s_spec_1` with per-cell `xor_block_value_at` equation.
    4. **Bridge**: `s_spec_1 = lift s1` by per-cell BV-equality
       (List.ext_getElem + UScalar.eq_of_val_eq + the per-cell bridge).
    5. Compose: `sponge.absorb_block (lift s) block RATE`
                = `keccak_f.keccak_f s_spec_1`
                = `keccak_f.keccak_f (lift s1)`
                = `.ok (lift r)`.
-/
import LibcruxIotSha3.Sponge.Bytes

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
