/-
  # Top-level `keccak.keccak` ↔ `sponge.keccak`.

  Largest composition in the sponge proofs: the impl function
  `keccak.keccak` (full pipeline: absorb-full-loop + absorb-final +
  first-output-block + squeeze-loop + optional trailing block) matches
  the spec `sponge.keccak` byte-by-byte.

  ## Post

  ```
  @[spec]
  theorem keccak.keccak_keccak_spec
      (RATE DELIM data out)
      (+ side conditions) :
      ⦃⌜True⌝⦄ keccak.keccak RATE DELIM data out
      ⦃⇓ r => ⌜ ∃ spec_out,
                  sponge.keccak ⟨Slice.len out⟩ RATE DELIM data = .ok spec_out
                  ∧ r.val.length = out.val.length
                  ∧ ∀ k < out.val.length, r.val[k]! = spec_out.val[k]! ⌝⦄
  ```

  Impl and spec sides are composed as independent `.ok`-equation chains,
  then bridged byte-by-byte.

  ### Impl side
  - `keccak.keccak_loop0_spec` ⇒ `absorb_fold s data RATE n.val = .ok (lift s1)`.
  - `keccak.absorb_final_spec` ⇒ `sponge.absorb_final (lift s1) data ... = .ok (lift s2)`.
  - Case-split on `blocks = 0`:
    - **blocks = 0** branch: `squeeze_first_and_last_spec` ⇒ output's bytes
      come from `lift s2` (no permutation).
    - **blocks ≥ 1** branch: `squeeze_first_block_spec` + `keccak_loop1_invariant`
      + (`squeeze_last_spec` if `last < outlen`) ⇒ output's bytes come from
      `iterate_keccak_f j (lift s2)` for various `j`.

  ### Spec side
  - `sponge.absorb` = `absorb_rec a₀ rate delim data` with `a₀ = Array.repeat 25 0`.
    Via `sponge_absorb_rec_eq_fold` and `absorb_fold_eq_spec`
    (from `Sponge/Absorb.lean`), tie to `absorb_fold s_init data RATE n.val`
    for the new-state `s_init`.
  - `sponge.squeeze` is characterized byte-wise by `sponge_squeeze_byte_eq`
    (from `Sponge/Squeeze.lean`).
-/
import LibcruxIotSha3.Sponge.AbsorbFinal
import LibcruxIotSha3.Sponge.Squeeze
import LibcruxIotSha3.Sponge.Absorb
import LibcruxIotSha3.Sponge.SqueezeBlock

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
