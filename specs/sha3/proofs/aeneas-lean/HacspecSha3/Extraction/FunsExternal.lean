-- Manual definitions for the external functions referenced by `Funs.lean`.
-- Replaces the auto-generated `FunsExternal_Template.lean`.
import Aeneas
import CoreModels
import HacspecSha3.Extraction.Types
open Aeneas Aeneas.Std Result ControlFlow Error
set_option linter.dupNamespace false
set_option linter.hashCommand false
set_option linter.unusedVariables false

open hacspec_sha3

/-- Coerce an `Aeneas.Std.core.ops.function.FnMut` into the
    `CoreModels.core.ops.function.FnMut` shape so we can reuse the
    rust-core-models implementation of array-style helpers. -/
def fnMutToCoreModels {F A B : Type}
    (inst : core.ops.function.FnMut F A B) :
    CoreModels.core.ops.function.FnMut F A B :=
  { FnOnceInst := { call_once := inst.FnOnceInst.call_once }
    call_mut := inst.call_mut }

/-- [core::array::from_fn]: defined by reusing
    `CoreModels.rust_primitives.slice.array_from_fn`. -/
@[rust_fun "core::array::from_fn"]
noncomputable def core.array.from_fn
  {T : Type} {F : Type} (N : Std.Usize)
  (inst : core.ops.function.FnMut F Std.Usize T) :
  F → Result (Array T N) := fun f =>
  CoreModels.rust_primitives.slice.array_from_fn N (fnMutToCoreModels inst) f
