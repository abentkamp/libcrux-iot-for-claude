/-
  # `keccak.absorb_final` ↔ `sponge.absorb_final`

  Main Triple `keccak.absorb_final_spec` with the full equality-form post:

  * termination of `keccak.absorb_final`;
  * `r.i.val = 0` on the result (consumed by the top-level `keccak` proof's
    squeeze-first-block precondition);
  * the spec equation
    `sponge.absorb_final (lift s) last start len RATE DELIM = .ok (lift r)`.

  Both impl and spec follow the same 4-step buffer recipe (zero-init,
  copy `last[start..start+len]` into buf[0..len], `buf[len] := DELIM`,
  OR `0x80` into `buf[RATE-1]`), then load and permute. The impl uses
  `if len > 0` to skip the `copy_from_slice` of an empty slice; the
  spec always takes the index_mut path, which is identity when
  `len = 0` (empty slice + `setSlice! 0 []` = no-op). Both yield the
  *same* `buf3`.

  Impl and spec sides are walked as independent `.ok`-equation chains and
  composed at the end:

  1. `h_impl_eq : keccak.absorb_final ... = .ok r`
  2. `h_pad_eq  : sponge.pad_last_block ... = .ok buf3`
  3. `h_block_idx_eq` — the spec's `block[0..rate]` indexing.
  4. Compose via `h_r_spec` from `keccak.absorb_block_spec`.
-/
import LibcruxIotSha3.Sponge.AbsorbBlock

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
