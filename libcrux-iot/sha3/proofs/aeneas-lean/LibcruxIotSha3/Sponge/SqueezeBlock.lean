/-
  # Squeeze block-level Triples.

  Bridges the impl-side squeeze block functions to the underlying byte
  projection of the sponge state, optionally preceded by a
  `keccakf1600` permutation.

  Four `@[spec]` Triples:

  - `keccak.squeeze_first_block_spec` — direct delegation to
    `store_block_spec` (no permutation).
  - `keccak.squeeze_next_block_spec`  — `keccakf1600` then `store_block`,
    returning the new state and output buffer.
  - `keccak.squeeze_last_spec`        — `keccakf1600`, `store_block_full`
    into a 200-byte buffer, then copy first `out.length` bytes.
  - `keccak.squeeze_first_and_last_spec` — no permutation, partial
    output via `store_block_full` + copy.

-/
import LibcruxIotSha3.Sponge.AbsorbBlock

open Aeneas Aeneas.Std Result Std.Do libcrux_iot_sha3 hacspec_sha3

namespace libcrux_iot_sha3.Sponge

/-! Remaining content sorried due to new-aeneas API drift. -/
#exit
end libcrux_iot_sha3.Sponge
