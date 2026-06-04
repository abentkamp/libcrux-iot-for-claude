/-
  # SHAKE128/256 + SHA3-{224,256,384,512} ema specs.

  Each of these 6 top-level digest functions is a direct instantiation of
  `keccak.keccak_keccak_spec` (in `Sponge/Keccak.lean`). The impl side
  goes through `keccakx1 RATE DELIM` which is a one-liner wrapper around
  `keccak.keccak RATE DELIM`; the spec side goes through `sha3.sha3_N` /
  `sha3.shake_N` which is a one-liner wrapper around `sponge.keccak RATE
  DELIM`. The proofs thus reduce to: unfold both wrappers, apply
  `keccak_keccak_spec`, repackage.

  ## Posts (equality-form)

  ```
  -- SHAKE (variable length):
  ⦃⌜True⌝⦄ shake128 BYTES data ⦃⇓ r => ⌜
    ∃ spec_out : Std.Array Std.U8 BYTES,
      sha3.shake128 BYTES data = .ok spec_out
      ∧ ∀ k < BYTES.val, r.val[k]! = spec_out.val[k]! ⌝⦄

  -- SHA3-ema (fixed length, side condition `digest.len = DIGEST_SIZE`):
  ⦃⌜True⌝⦄ sha224_ema digest payload ⦃⇓ r => ⌜
    ∃ spec_out : Std.Array Std.U8 28#usize,
      sha3.sha3_224 payload = .ok spec_out
      ∧ r.val.length = 28
      ∧ ∀ k < 28, r.val[k]! = spec_out.val[k]! ⌝⦄
  ```

  ## Side conditions

  - All RATE values (72, 104, 136, 144, 168) are ≤ 200 and multiples of 8.
  - All RATE values are ≥ 1.
  - For ema specs: `digest.val.length = <DIGEST_SIZE>` (28/32/48/64) and
    `payload.val.length ≤ U32.MAX` (to discharge the impl's two `massert`s).
-/
import LibcruxIotSha3.Sponge.Keccak

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
