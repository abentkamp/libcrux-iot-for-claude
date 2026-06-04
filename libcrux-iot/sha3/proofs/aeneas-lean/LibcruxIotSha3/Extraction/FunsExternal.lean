-- Manual definitions for the external functions referenced by `Funs.lean`.
-- Replaces the auto-generated `FunsExternal_Template.lean`.
import Aeneas
import LibcruxIotSha3.Extraction.Types
open Aeneas Aeneas.Std Result ControlFlow Error
set_option linter.dupNamespace false
set_option linter.hashCommand false
set_option linter.unusedVariables false

open libcrux_iot_sha3

/-! ## `core::iter::range::Step for i32` -/

/-- [core::iter::range::{impl core::iter::range::Step for i32}::backward_checked]:
    `start - n` if it fits in `i32`, else `None`. -/
@[rust_fun "core::iter::range::{core::iter::range::Step<i32>}::backward_checked"]
def I32.Insts.CoreIterRangeStep.backward_checked
    (start : Std.I32) (n : Std.Usize) : Result (Option Std.I32) :=
  ok (Std.Option.ofResult (Std.IScalar.tryMk .I32 (start.val - (n.val : Int))))

/-- [core::iter::range::{impl core::iter::range::Step for i32}::forward_checked]:
    `start + n` if it fits in `i32`, else `None`. -/
@[rust_fun "core::iter::range::{core::iter::range::Step<i32>}::forward_checked"]
def I32.Insts.CoreIterRangeStep.forward_checked
    (start : Std.I32) (n : Std.Usize) : Result (Option Std.I32) :=
  ok (Std.Option.ofResult (Std.IScalar.tryMk .I32 (start.val + (n.val : Int))))

/-- [core::iter::range::{impl core::iter::range::Step for i32}::steps_between]:
    Number of steps from `start` to `end_`, if non-negative. -/
@[rust_fun "core::iter::range::{core::iter::range::Step<i32>}::steps_between"]
def I32.Insts.CoreIterRangeStep.steps_between
    (start end_ : Std.I32) : Result (Std.Usize × (Option Std.Usize)) :=
  if start.val > end_.val then
    ok ⟨0#usize, none⟩
  else
    let steps := Std.Usize.ofNatCore (end_.val - start.val).toNat (by scalar_tac)
    ok ⟨steps, some steps⟩

/-! ## `libcrux_secrets` casts and blanket `Classify` -/

/-- [libcrux_secrets::int::public_integers::{impl libcrux_secrets::traits::Classify<T> for T}::classify]:
    Identity on public integer types. -/
@[rust_fun
  "libcrux_secrets::int::public_integers::{libcrux_secrets::traits::Classify<@T, @T>}::classify"]
def libcrux_secrets.traits.Classify.Blanket.classify {T : Type} (x : T) : Result T :=
  ok x

/-- [libcrux_secrets::int::{impl libcrux_secrets::int::CastOps for u64}::as_u32]:
    Truncating cast. -/
@[rust_fun
  "libcrux_secrets::int::{libcrux_secrets::int::CastOps<u64>}::as_u32"]
def U64.Insts.Libcrux_secretsIntCastOps.as_u32 (x : Std.U64) : Result Std.U32 :=
  ok (Std.UScalar.cast .U32 x)

/-- [libcrux_secrets::int::{impl libcrux_secrets::int::CastOps for u32}::as_u64]:
    Zero-extending cast. -/
@[rust_fun
  "libcrux_secrets::int::{libcrux_secrets::int::CastOps<u32>}::as_u64"]
def U32.Insts.Libcrux_secretsIntCastOps.as_u64 (x : Std.U32) : Result Std.U64 :=
  ok (Std.UScalar.cast .U64 x)
