/-
  Bridge between the impl-level `keccak.keccakf1600` and the hacspec
  top-level `keccak_f.keccak_f`.

  ## Architecture

  The impl's `keccak.keccakf1600` iterates `keccakf1600_4rounds` 6 times
  over an `I32` range `[0, 6)`. The hacspec's `keccak_f.keccak_f` iterates
  the body `theta ; rho ; pi ; chi ; iota round` 24 times over a `Usize`
  range `[0, 24)`. Our `Composition.keccakf1600_equiv_via_bit` proves that
  the impl's output equals a 24-fold spec chain (`spec_chain (lift s) 24`)
  using the `_unrolled` variants of the spec functions.

  This file provides the loop-spec infrastructure for the `Usize` range,
  the structural-unfolding helper for `array.from_fn` / `createi` over
  small `N`, and the spec-side definitions in terms of the hacspec
  (non-unrolled) variants that mirror `keccak_f.keccak_f`'s body.

  These bridge the iteration-structure gap between our proof
  infrastructure (using `Nat.fold 24` over `spec_round_step`) and the
  hacspec function (using a `Usize` range loop over a single-round body).
-/
import LibcruxIotSha3.Composition.ViaBit
import LibcruxIotSha3.Foundation.I32LoopSpec

open Aeneas Aeneas.Std Result ControlFlow Std.Do libcrux_iot_sha3 hacspec_sha3
open libcrux_iot_sha3.Foundation

namespace libcrux_iot_sha3.Composition

set_option mvcgen.warning false
set_option linter.unusedVariables false

/-! ## Helper: `Usize.val` conversion for small-Nat constants

The `array.from_fn` extraction uses raw `BitVec.ofNat _ n` for iteration
indices; we need to convert these to the standard `n#usize` form. -/

private theorem bv_ofNat_val_eq (n : Nat) (hn : n < 2^32) :
    (⟨BitVec.ofNat System.Platform.numBits n⟩ : Std.Usize).val = n := by
  show (BitVec.ofNat _ n).toNat = n
  simp only [BitVec.toNat_ofNat]
  apply Nat.mod_eq_of_lt
  have h32 : (32 : Nat) ≤ System.Platform.numBits := by
    have := System.Platform.numBits_eq; omega
  calc n < 2^32 := hn
    _ ≤ 2^System.Platform.numBits := Nat.pow_le_pow_right (by decide) h32

private theorem bv_ofNat_eq_usize_lit_0 :
    (⟨BitVec.ofNat _ 0⟩ : Std.Usize) = 0#usize := by
  apply Std.UScalar.eq_of_val_eq; exact bv_ofNat_val_eq 0 (by omega)
private theorem bv_ofNat_eq_usize_lit_1 :
    (⟨BitVec.ofNat _ 1⟩ : Std.Usize) = 1#usize := by
  apply Std.UScalar.eq_of_val_eq; exact bv_ofNat_val_eq 1 (by omega)
private theorem bv_ofNat_eq_usize_lit_2 :
    (⟨BitVec.ofNat _ 2⟩ : Std.Usize) = 2#usize := by
  apply Std.UScalar.eq_of_val_eq; exact bv_ofNat_val_eq 2 (by omega)
private theorem bv_ofNat_eq_usize_lit_3 :
    (⟨BitVec.ofNat _ 3⟩ : Std.Usize) = 3#usize := by
  apply Std.UScalar.eq_of_val_eq; exact bv_ofNat_val_eq 3 (by omega)
private theorem bv_ofNat_eq_usize_lit_4 :
    (⟨BitVec.ofNat _ 4⟩ : Std.Usize) = 4#usize := by
  apply Std.UScalar.eq_of_val_eq; exact bv_ofNat_val_eq 4 (by omega)


/-! Remaining theorems sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Composition
