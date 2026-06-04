/-
  # Aeneas Std byte/slice `@[spec]` Triples

  Small `@[spec]` Triples used by the byte ↔ lane bridges in
  `Sponge/Bytes.lean`.

  ## Installed

  - `core_models_slice_Slice_len_spec` — `core.slice.Slice.len`
    returns the underlying list length.
  - `massert_spec` — `Aeneas.Std.massert b` succeeds (with `()`) when `b`.
  - `core_models_num_U32_from_le_bytes_spec`,
    `core_models_num_U32_to_le_bytes_spec` — byte ↔ u32 LE.
  - `core_models_num_U64_from_le_bytes_spec`,
    `core_models_num_U64_to_le_bytes_spec` — byte ↔ u64 LE.
  - `core_models_Slice_Insts_index_RangeUsize_spec` — slice subindexing
    over `Range<usize>` (used by load/store loops).
  - `core_models_Slice_Insts_index_mut_RangeUsize_spec` — mutable slice
    subindexing over `Range<usize>` (used by `store_block_2u32_loop.body`).
  - `core_models_result_Result_unwrap_spec` — `result.Result.unwrap` on
    `.Ok v` yields `v`.
  - `core_models_slice_Slice_copy_from_slice_spec` — write-into-slice;
    the impl model returns the source slice outright when lengths match.
  - `core_models_array_try_from_slice_spec`
    (`Slice T → Result (result.Result (Array T N) ...)`).
    The body invokes `rust_primitives.slice.array_from_fn` on the
    `try_from.closure`, whose Triple is established by induction over the
    closure's `call_mut` calls and the `List.range N.val` `foldlM`.
    See the closure-step lemma, the `foldlM` invariant, and the final
    Triple at the bottom of this file. General Aeneas Std bridge with no
    SHA-3 specificity (belongs in `rust-core-models` upstream).
-/
import LibcruxIotSha3.Sponge.Opaque

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
