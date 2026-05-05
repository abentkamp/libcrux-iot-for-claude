-- Implementations for items missing from the current Aeneas extraction.
-- The originals were `axiom` declarations; they have been replaced with `def`s
-- whose bodies match the underlying Rust semantics (cross-checked against
-- `c/combined/generated/libcrux_secrets.h` for the libcrux-secrets casts and
-- against rust-core-models / Aeneas Std for the trait dictionaries).
--
-- The I32 `Step` instance uses the structure shape supplied by review
-- feedback (Clone + PartialOrd dictionaries plus 7 arithmetic methods); the
-- arithmetic methods are stubbed (`ok none` / `fail panic`) because the
-- broader Range iterator dispatch they would feed into has unresolved deps.

import Aeneas
import CoreModels

open Aeneas Aeneas.Std Result

noncomputable section

-- libcrux_secrets::traits::Classify::Blanket::classify
-- Blanket impl that wraps any value into a successful Result. Identity in C
-- (see libcrux_secrets_int_public_integers_classify_27_*).
namespace libcrux_secrets.traits.Classify.Blanket
def classify {T : Type} (a : T) : Aeneas.Std.Result T := ok a
end libcrux_secrets.traits.Classify.Blanket

namespace Aeneas.Std

-- Integer cast operations from libcrux_secrets.
-- C extraction shows these are classify(cast(declassify(x))), i.e. plain
-- primitive casts after stripping classify/declassify identities.
def U32.Insts.Libcrux_secretsIntCastOps.as_u64 (x : U32) : Result U64 :=
  ok (UScalar.cast .U64 x)

def U64.Insts.Libcrux_secretsIntCastOps.as_u32 (x : U64) : Result U32 :=
  ok (UScalar.cast .U32 x)

-- I32 range step instance.
-- The `Step` structure has Clone + PartialOrd dictionaries plus 7 arithmetic
-- methods; we provide identity clone, BitVec-based PartialOrd, and stubs for
-- the arithmetic (`fail panic`) since this Step is currently only referenced
-- via the broader Range iterator dispatch which itself has unresolved deps.
@[reducible] def I32.Insts.Core_modelsIterRangeStep : core_models.iter.range.Step I32 :=
  let cloneInst : core_models.clone.Clone I32 :=
    { clone := fun s => ok s }
  let partialEqInst : core_models.cmp.PartialEq I32 I32 :=
    { eq := fun a b => ok (decide (a = b)) }
  let partialOrdInst : core_models.cmp.PartialOrd I32 I32 :=
    { PartialEqInst := partialEqInst
      partial_cmp := fun a b =>
        ok (some (if a.val < b.val then core_models.cmp.Ordering.Less
                  else if a.val = b.val then core_models.cmp.Ordering.Equal
                  else core_models.cmp.Ordering.Greater)) }
  { cloneCloneInst := cloneInst
    cmpPartialOrdInst := partialOrdInst
    steps_between := fun _ _ => ok (0#usize, none)
    forward_checked := fun _ _ => ok none
    backward_checked := fun _ _ => ok none
    forward := fun _ _ => fail Error.panic
    forward_unchecked := fun _ _ => fail Error.panic
    backward := fun _ _ => fail Error.panic
    backward_unchecked := fun _ _ => fail Error.panic }

-- Slice indexing via a SliceIndex instance: dispatch to Aeneas's existing
-- index / index_mut helpers (which call the trait dictionary internally).
def Slice.Insts.Core_modelsOpsIndexIndex.index
  {T I Output : Type}
  (inst : core.slice.index.SliceIndex I (Slice T) Output)
  (s : Slice T) (i : I) : Result Output :=
  core.slice.index.Slice.index inst s i

def Slice.Insts.Core_modelsOpsIndexIndexMut.index_mut
  {T I Output : Type}
  (inst : core.slice.index.SliceIndex I (Slice T) Output)
  (s : Slice T) (i : I) : Result (Output × (Output → Slice T)) :=
  core.slice.index.Slice.index_mut inst s i

-- Array indexing via a SliceIndex instance: convert to slice and delegate.
def Array.Insts.Core_modelsOpsIndexIndex.index
  {T I Output : Type} {N : Usize}
  (inst : core.slice.index.SliceIndex I (Slice T) Output)
  (arr : Array T N) (i : I) : Result Output :=
  core.slice.index.Slice.index inst (Array.to_slice arr) i

def Array.Insts.Core_modelsOpsIndexIndexMut.index_mut
  {T I Output : Type} {N : Usize}
  (inst : core.slice.index.SliceIndex I (Slice T) Output)
  (arr : Array T N) (i : I) : Result (Output × (Output → Array T N)) := do
  let (s, to_arr) := Array.to_slice_mut arr
  let (out, to_slice) ← core.slice.index.Slice.index_mut inst s i
  ok (out, fun o => to_arr (to_slice o))

-- Display / Debug instances. Faithful given that core_models models
-- `Formatter`, `Arguments`, and `Error` as `Unit`: the structures have a
-- single `fmt` (resp. `dbg_fmt`) method returning `(Ok (), formatter)`.
-- Display has field `fmt`; Debug has field `dbg_fmt` (per
-- rust-core-models/lean/CoreModels/Types.lean at the pinned revision).
@[reducible] def Usize.Insts.Core_modelsFmtDisplay : core_models.fmt.Display Usize :=
  { fmt := fun _ f => ok (core_models.result.Result.Ok (), f) }

@[reducible] def Usize.Insts.Core_modelsFmtDebug : core_models.fmt.Debug Usize :=
  { dbg_fmt := fun _ f => ok (core_models.result.Result.Ok (), f) }

-- Debug instance builder for Array (parameterised over element Debug).
-- Element-level Debug is unused because Formatter is modelled as `Unit`.
@[reducible] def Array.Insts.Core_modelsFmtDebug
  {T : Type} (_N : Usize) (_elem : core_models.fmt.Debug T) :
  core_models.fmt.Debug (Array T _N) :=
  { dbg_fmt := fun _ f => ok (core_models.result.Result.Ok (), f) }

-- Slice index instance wrappers: identity coercions used by the dispatch
-- layer. The Aeneas SliceIndex *is* the Index/IndexMut implementation, so
-- forwarding the dictionary unchanged is correct.
def Slice.Insts.Core_modelsOpsIndexIndex
  {T I O : Type} (inst : core.slice.index.SliceIndex I (Slice T) O) :
  core.slice.index.SliceIndex I (Slice T) O := inst

def Slice.Insts.Core_modelsOpsIndexIndexMut
  {T I O : Type} (inst : core.slice.index.SliceIndex I (Slice T) O) :
  core.slice.index.SliceIndex I (Slice T) O := inst

end Aeneas.Std

namespace core_models

-- core::result::Result::unwrap.
-- Rust panics on `Err`, consulting `Debug` only on the panic path; we drop
-- the dictionary and `fail` with `Error.panic` to match.
def result.Result.unwrap
  {T E : Type} (_dbg : fmt.Debug E) (r : result.Result T E) :
  Aeneas.Std.Result T :=
  match r with
  | .Ok x => Aeneas.Std.Result.ok x
  | .Err _ => Aeneas.Std.Result.fail Aeneas.Std.Error.panic

-- core::fmt::Arguments::new — Arguments is modelled as Unit.
def fmt.Arguments.new
  {N M : Aeneas.Std.Usize}
  (_ : Aeneas.Std.Array Aeneas.Std.U8 N)
  (_ : Aeneas.Std.Array fmt.rt.Argument M) :
  Aeneas.Std.Result fmt.Arguments :=
  Aeneas.Std.Result.ok ()

-- core::fmt::Formatter::write_str — Formatter / Error are Unit.
def fmt.Formatter.write_str
  (f : fmt.Formatter) (_ : Aeneas.Std.Str) :
  Aeneas.Std.Result (result.Result Unit fmt.Error × fmt.Formatter) :=
  Aeneas.Std.Result.ok (.Ok (), f)

-- core::fmt::Formatter::debug_struct_field4_finish — same trivial model.
def fmt.Formatter.debug_struct_field4_finish
  (f : fmt.Formatter) (_ : Aeneas.Std.Str)
  (_ : Aeneas.Std.Str) (_ : Aeneas.Std.Dyn (fun _dyn => fmt.Debug _dyn))
  (_ : Aeneas.Std.Str) (_ : Aeneas.Std.Dyn (fun _dyn => fmt.Debug _dyn))
  (_ : Aeneas.Std.Str) (_ : Aeneas.Std.Dyn (fun _dyn => fmt.Debug _dyn))
  (_ : Aeneas.Std.Str) (_ : Aeneas.Std.Dyn (fun _dyn => fmt.Debug _dyn)) :
  Aeneas.Std.Result (result.Result Unit fmt.Error × fmt.Formatter) :=
  Aeneas.Std.Result.ok (.Ok (), f)

-- core::slice::[T]::copy_from_slice — equal-length copy or panic.
-- We can't directly delegate to Aeneas's `core.slice.Slice.copy_from_slice`
-- because it expects a `core.marker.Copy T`, not a `core_models.marker.Copy T`.
-- The body is identical (the Copy dictionary is a witness only).
def slice.Slice.copy_from_slice
  {T : Type} (_cpy : marker.Copy T)
  (dst : Aeneas.Std.Slice T) (src : Aeneas.Std.Slice T) :
  Aeneas.Std.Result (Aeneas.Std.Slice T) :=
  if Aeneas.Std.Slice.len dst = Aeneas.Std.Slice.len src then
    Aeneas.Std.Result.ok src
  else Aeneas.Std.Result.fail Aeneas.Std.Error.panic

-- Debug instance for shared references (&T modelled as T): identity.
def Shared0T.Insts.Core_modelsFmtDebug
  {T : Type} (d : fmt.Debug T) : fmt.Debug T := d

-- Debug instance for array::TryFromSliceError (Unit-modelled).
@[reducible] def array.TryFromSliceError.Insts.Core_modelsFmtDebug :
  fmt.Debug array.TryFromSliceError :=
  { dbg_fmt := fun _ f => Aeneas.Std.Result.ok (.Ok (), f) }

-- SliceIndex instances for the core_models Range types.
-- core_models's `ops.range.Range`, `RangeTo`, `RangeFrom` are structurally
-- identical to Aeneas's `core.ops.range.Range` / `RangeTo` (and a one-field
-- `RangeFrom` with `start`). We adapt by structural conversion and delegate
-- to Aeneas's per-shape SliceIndex implementations for `Range Usize`,
-- `RangeTo Usize`, `RangeFrom Usize`. The `Sealed` marker is empty so we can
-- construct `{}` for any Self type.

private def cmRangeUsizeToAeneas (r : ops.range.Range Aeneas.Std.Usize) :
    Aeneas.Std.core.ops.range.Range Aeneas.Std.Usize :=
  { start := r.start, «end» := r.«end» }

private def cmRangeToUsizeToAeneas (r : ops.range.RangeTo Aeneas.Std.Usize) :
    Aeneas.Std.core.ops.range.RangeTo Aeneas.Std.Usize :=
  { «end» := r.«end» }

@[reducible] def ops.range.RangeUsize.Insts.Core_modelsSliceIndexSliceIndexSliceSlice
  (T : Type) : Aeneas.Std.core.slice.index.SliceIndex
    (ops.range.Range Aeneas.Std.Usize) (Aeneas.Std.Slice T) (Aeneas.Std.Slice T) :=
  { sealedInst := {}
    get := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.get (cmRangeUsizeToAeneas r) s
    get_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.get_mut (cmRangeUsizeToAeneas r) s
    get_unchecked := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    get_unchecked_mut := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    index := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.index (cmRangeUsizeToAeneas r) s
    index_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.index_mut (cmRangeUsizeToAeneas r) s }

@[reducible] def ops.range.RangeToUsize.Insts.Core_modelsSliceIndexSliceIndexSliceSlice
  (T : Type) : Aeneas.Std.core.slice.index.SliceIndex
    (ops.range.RangeTo Aeneas.Std.Usize) (Aeneas.Std.Slice T) (Aeneas.Std.Slice T) :=
  { sealedInst := {}
    get := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeToUsizeSlice.get (cmRangeToUsizeToAeneas r) s
    get_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeToUsizeSlice.get_mut (cmRangeToUsizeToAeneas r) s
    get_unchecked := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    get_unchecked_mut := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    index := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeToUsizeSlice.index (cmRangeToUsizeToAeneas r) s
    index_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeToUsizeSlice.index_mut (cmRangeToUsizeToAeneas r) s }

-- For `RangeFrom`, we implement get / index inline by reusing Aeneas's full
-- `Range` machinery with `start..s.length`.
@[reducible] def ops.range.RangeFromUsize.Insts.Core_modelsSliceIndexSliceIndexSliceSlice
  (T : Type) : Aeneas.Std.core.slice.index.SliceIndex
    (ops.range.RangeFrom Aeneas.Std.Usize) (Aeneas.Std.Slice T) (Aeneas.Std.Slice T) :=
  let toFullRange (r : ops.range.RangeFrom Aeneas.Std.Usize) (s : Aeneas.Std.Slice T) :
      Aeneas.Std.core.ops.range.Range Aeneas.Std.Usize :=
    { start := r.start, «end» := Aeneas.Std.Slice.len s }
  { sealedInst := {}
    get := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.get (toFullRange r s) s
    get_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.get_mut (toFullRange r s) s
    get_unchecked := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    get_unchecked_mut := fun _ _ => Aeneas.Std.Result.fail Aeneas.Std.Error.undef
    index := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.index (toFullRange r s) s
    index_mut := fun r s =>
      Aeneas.Std.core.slice.index.SliceIndexRangeUsizeSlice.index_mut (toFullRange r s) s }

end core_models

end -- noncomputable section
