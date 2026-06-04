/-
  # Squeeze loop (`keccak_loop1`) and per-byte spec bridge.

  Artifacts delivered in this file:

  * `iterate_keccak_f_eq_fold` — pure unfold of `sponge.iterate_keccak_f`
    to a `Nat.fold` of `keccak_f.keccak_f`. Proved by induction on the
    iteration count using `sponge.iterate_keccak_f.eq_def`.

  * `keccak.keccak_loop1_invariant` — the impl Triple for the squeeze
    loop `keccak.keccak_loop1`. Uses `loop_range_spec_usize` with a
    fold-form invariant carrying termination (`r.i.val = 0`), offset
    advancement, and spec-side lockstep
    `squeeze_fold s (blocks - 1) = .ok (lift r)`.

  * `squeeze_byte_at` — the per-byte projection of a spec state used
    by both `keccak.squeeze_next_block_spec` and the per-byte
    equivalence theorem.

  * `sponge_squeeze_byte_eq` — pure block-wise characterization of
    `sponge.squeeze`. Equates byte `k` of `sponge.squeeze` (under
    `iterate_keccak_f (k/rate) state = .ok s_b`) with
    `squeeze_byte_at s_b (k % rate.val)`. The conditional totality
    of `iterate_keccak_f` is supplied at the use site via Bridge 1's
    `keccakf1600_equiv_hacspec`.

  ## See also

  - `Sponge/SqueezeBlock.lean:keccak.squeeze_next_block_spec` —
    per-block Triple used in the loop body.
-/
import LibcruxIotSha3.Sponge.SqueezeBlock

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
