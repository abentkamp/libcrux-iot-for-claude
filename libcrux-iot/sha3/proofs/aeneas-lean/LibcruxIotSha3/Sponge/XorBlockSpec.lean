/-
  # Spec-side scaffolding for `sponge.xor_block_into_state`.

  Installed:

  - `from_fn_pure_spec` — generic `@[spec]` analog of `createi_pure_spec`
    (HacspecBridge.lean:663) but stated over the *direct* `FnMut` instance
    (no `Fn` wrapper required). `sponge.xor_block_into_state` uses
    `core.array.from_fn` directly with a `FnMut`, not the `Fn`-wrapped
    `createi`. Reusable for any pure FnMut closure.
  - `list_8_at` / `list_8_at_val_eq_slice` — helpers that extract 8 bytes
    from a list at offset `o`, padded to length 8, with a proof that the
    padded form coincides with the exact slice when `o + 8 ≤ length`.
  - `xor_block_value_at` — the per-cell pure value characterizing the
    closure body (`f`-side for `from_fn_pure_spec`).
  - `xor_block_into_state_closure_call_mut_spec` — the per-cell `@[spec]`
    for the 25-cell `from_fn` body. Drives the inner do-chain
    `div/rem → mul/add → div → if → (slice-index → try_from → unwrap →
    from_le_bytes → lift) | (Array.index_usize)`. In the `b < rate/8`
    branch, matches the constructed 8-byte array's `.val` with
    `list_8_at block.val (8b)` via `list_8_at_val_eq_slice`.

  ## Closure body (Extraction/Funs.lean:1076-1105)

  Given `c = (rate, state, block)` and cell index `k`:

  ```
  x = k / 5
  y = k % 5
  b = 5*y + x   -- = 5*(k%5) + k/5  (the "byte_lane_idx" inverse)
  if b < rate/8 then
    state[k] ^^^ U64.from_le_bytes(block[8b..8b+8])
  else
    state[k]
  ```

  Both branches return `(value, c)` — the closure state is preserved, so
  `from_fn_pure_spec` applies even though the body has an `if`.
-/
import LibcruxIotSha3.Sponge.Interleave
import LibcruxIotSha3.Sponge.SliceSpecs

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
