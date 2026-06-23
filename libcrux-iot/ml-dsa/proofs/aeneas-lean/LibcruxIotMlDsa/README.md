# Verification of ML-DSA's polynomial API

This directory contains the Lean 4 proof that the Rust implementation of
ML-DSA's **polynomial API** in `libcrux-iot/ml-dsa/src/` computes the same functions
as the ML-DSA specification in `https://github.com/celabshq/libcrux/tree/main/specs`. Both sides are machine-extracted to Lean by the `cargo hax into aeneas-lean` pipeline.

Every theorem below depends only on Lean's three
standard axioms (`propext`, `Classical.choice`, `Quot.sound`).

## Top-level theorems — the `PolynomialRingElement` API

The polynomial API (`PolynomialRingElement`) is generic over the
`simd::traits::Operations` trait. The whole layer is dispatched through a single
concrete instance, `Operations Coefficients`. Every top-level theorem
applies the generic impl function at this instance.

Each is an `mvcgen` Triple `⦃ True ⦄ <impl> <args>… ⦃ ⇓ r => ⌜ <spec> (lift_poly_res <args>)… = .ok (lift_poly_res r)⌝ ⦄`
that ties the impl function directly to its counterpart in the extracted spec. The impl stores coefficients as 32 SIMD units × 8 signed,
Montgomery-domain `i32` lanes, wheras the spec uses a flat array `[i32; 256]`,
Montgomery factor stripped lane-wise.
Lifting functions do the conversion.

Representative statement ([`Polynomial/HacspecNtt.lean`](Polynomial/HacspecNtt.lean)):
`
```lean
theorem ntt_hacspec_fc (re : PolynomialRingElement Coefficients) (B : Nat)
    (hB : …) (hin : …per-lane bound B…) :
    ⦃ ⌜ True ⌝ ⦄
    ntt.ntt portable_ops_inst re
    ⦃ ⇓ r => ⌜ hacspec_ml_dsa.ntt.ntt (lift_poly_res re) = .ok (lift_poly_res r) ⌝ ⦄
```

| Theorem (file) | impl function | post condition of the triple |
|---|---|---|
| `ntt_hacspec_fc` ([`Polynomial/HacspecNtt.lean`](Polynomial/HacspecNtt.lean)) | `ntt.ntt` | `hacspec_ml_dsa.ntt.ntt (lift_poly_res re) = .ok (lift_poly_res r)` |
| `intt_hacspec_fc` ([`Polynomial/HacspecNtt.lean`](Polynomial/HacspecNtt.lean)) | `ntt.invert_ntt_montgomery` | `hacspec_ml_dsa.ntt.intt (lift_poly_res re) = .ok (lift_poly_res_intt r)` (The impl's inverse NTT leaves its output in the Montgomery domain (`· R`); `lift_poly_res_intt` strips that factor (`· R⁻¹`) so te result matches the extracted `intt`.) |
| `poly_pointwise_mul_hacspec_fc` ([`Polynomial/HacspecFC.lean`](Polynomial/HacspecFC.lean)) | `ntt.ntt_multiply_montgomery` | `hacspec_ml_dsa.polynomial.poly_pointwise_mul (lift_poly_res lhs) (lift_poly_res rhs) = .ok (lift_poly_res r)` |
| `poly_add_hacspec_fc` ([`Polynomial/HacspecFC.lean`](Polynomial/HacspecFC.lean)) | `…PolynomialRingElement.add` | `hacspec_ml_dsa.polynomial.poly_add (lift_poly_res self) (lift_poly_res rhs) = .ok (lift_poly_res r)` |
| `poly_sub_hacspec_fc` ([`Polynomial/HacspecFC.lean`](Polynomial/HacspecFC.lean)) | `…PolynomialRingElement.subtract` | `hacspec_ml_dsa.polynomial.poly_sub (lift_poly_res self) (lift_poly_res rhs) = .ok (lift_poly_res r)` |
| `infinity_norm_exceeds_hacspec_fc` ([`Polynomial/HacspecNorm.lean`](Polynomial/HacspecNorm.lean)) | `…PolynomialRingElement.infinity_norm_exceeds` | `∃ n, hacspec_ml_dsa.polynomial.poly_infinity_norm (canon_raw self) = .ok n ∧ (r = decide (bound.val ≤ n.val))` (The spec does not have a direct equivalent to `infinity_norm_exceeds`. So the postcondition needs to establish equivalence using `poly_infinity_norm`.) |


Four impl ops have no non-trivial counterpart in the spec (it treats them as
identity / a constant / a copy), so they are stated as direct value equations:

| Theorem (file) | impl function | post condition of the triple |
|---|---|---|
| `reduce_fc` ([`Polynomial/NttArith.lean`](Polynomial/NttArith.lean)) | `ntt.reduce` | `lift_poly r = lift_poly re` (Barrett-reduce; residues unchanged) |
| `zero_fc` ([`Polynomial/Convert.lean`](Polynomial/Convert.lean)) | `…zero` | `lift_poly r = Pure.zero_poly` (the zero polynomial) |
| `to_i32_array_fc` ([`Polynomial/Convert.lean`](Polynomial/Convert.lean)) | `…to_i32_array` | `∀ k<256, (r[k]).val = <self coefficient k>` |
| `from_i32_array_fc` ([`Polynomial/Convert.lean`](Polynomial/Convert.lean)) | `…from_i32_array` | `∀ k<256, <r coefficient k> = (array[k]).val` |

## Supporting layers

The top-level theorems are corollaries / loop-compositions of a stack of proven
per-SIMD-unit and NTT-driver results.

### NTT masters (the per-array `[Coefficients; 32]` engines)

| Theorem (file) | impl function |
|---|---|
| `ntt_inner_fc` ([`Vector/Portable/NttMaster.lean`](Vector/Portable/NttMaster.lean)) | `simd.portable.ntt.ntt` (8 forward layers) |
| `invert_ntt_inner_fc` ([`Vector/Portable/InvNttMaster.lean`](Vector/Portable/InvNttMaster.lean)) | `simd.portable.invntt.invert_ntt_montgomery` (8 inverse layers + finalize) |

These compose the per-layer butterfly drivers
([`Vector/Portable/{Ntt,InvNtt,NttDriver,InvNttDriver}.lean`](Vector/Portable/)).

### Per-SIMD-unit (8-lane) arithmetic and rounding

| Theorem (file) | impl function |
|---|---|
| `montgomery_reduce_element_spec` ([`Vector/Portable/Arithmetic.lean`](Vector/Portable/Arithmetic.lean)) | `montgomery_reduce_element` |
| `reduce_element_spec` ([`Vector/Portable/Arithmetic.lean`](Vector/Portable/Arithmetic.lean)) | `reduce_element` (Barrett) |
| `add_spec` / `subtract_spec` / `montgomery_multiply_spec` / `montgomery_multiply_by_constant_spec` ([`Vector/Portable/Element.lean`](Vector/Portable/Element.lean)) | `arithmetic.{add,subtract,montgomery_multiply,montgomery_multiply_by_constant}` |
| `zero_unit_spec` / `to_coefficient_array_spec` / `from_coefficient_array_spec` ([`Vector/Portable/Element.lean`](Vector/Portable/Element.lean)) | `vector_type.{zero,to_coefficient_array,from_coefficient_array}` |
| `shift_left_then_reduce_spec` ([`Vector/Portable/Arithmetic.lean`](Vector/Portable/Arithmetic.lean)) | `shift_left_then_reduce` |
| `infinity_norm_exceeds_unit_spec` ([`Vector/Portable/Arithmetic.lean`](Vector/Portable/Arithmetic.lean)) | `arithmetic.infinity_norm_exceeds` (the bug-fixed sign-mask) |
| `power2round_spec` / `decompose_spec` / `use_hint_spec` / `compute_hint_spec` ([`Vector/Portable/Rounding.lean`](Vector/Portable/Rounding.lean)) | FIPS-204 §7.4 rounding |

## Proof architecture

`hacspec_ml_dsa.*` is the `specs/ml-dsa` Rust spec crate machine-extracted to
aeneas-lean (the same pipeline as the impl), wired in as the `HacspecMlDsa` Lake
dependency. The bridge ([`Spec/HacspecBridge.lean`](Spec/HacspecBridge.lean))
re-encodes between the impl's SIMD lanes and the spec's `[i32; 256]`, proves the
extracted `mod_q` total and residue-preserving (`mod_q_eq`), and matches each
extracted op to the impl; the `ZETAS`-table match (`zetas_bridge`) is a kernel
`decide` in `Z_q` over the full 256-entry table. Internally the equivalence
factors through a clean-`Z_q` Lean restatement
([`Spec/Pure.lean`](Spec/Pure.lean), proven equal to the extracted spec) — a
proof convenience that keeps the algebra in `ZMod q`, not a separately trusted
artifact.

The impl works over `Coefficients`-backed `i32` lanes in the (signed,
non-canonical) **Montgomery** domain, packed as 32 SIMD units of 8 lanes. The
proofs reduce these lane-wise to a clean `Array (ZMod q)` of 256 coefficients —
the working representation in which the algebra is done (the spec's own
`[i32; 256]` is its canonical-residue image). The lift family in
[`Spec/Lift.lean`](Spec/Lift.lean):

- `liftZ x = (x : Z_q) · R⁻¹` (strips one Montgomery factor); `liftZ_std x = (x : Z_q)`.
- `lift_units` / `lift_poly` flatten 32×8 lanes into a 256-element `Z_q` poly,
  mont-stripped lane-wise (`lift_poly re = lift_units re.simd_units`, by `rfl`).
- Seam lemmas: `liftZ_add`/`liftZ_sub` (additivity), `liftZ_of_mont`
  (a Montgomery product lifts to a clean product — the `R⁻¹²` reconciliation
  used by `ntt_multiply_montgomery_fc`).

The poly-layer proofs are either one-step corollaries of the NTT masters
(`ntt`, `invert_ntt_montgomery`) or 32-unit loop compositions of the per-unit
specs (`add`, `subtract`, `ntt_multiply_montgomery`, `reduce`, `zero`,
`to_i32_array`, `from_i32_array`, `infinity_norm_exceeds`), driven by the loop
combinators in [`Util/`](Util/).

## Reproduction

### Prerequisites

- For running the proofs:
  - Lean 4 toolchain `leanprover/lean4:v4.30.0-rc2` (pinned in `lean-toolchain`).
  - Hacspec ML-DSA spec from https://github.com/cryspen/libcrux at commit `a4cfb1ebf26431b2ee81f0dc19383158aaf397b7`
- For extraction:
  - Hax at commit `ffdf432705d409b62ec025d253a340234b59766f`
    (not publicly available yet, https://github.com/cryspen/hax-evit)
    with the corresponding charon/aeneas versions:
    - Charon at https://github.com/AeneasVerif/charon/releases/tag/nightly-2026.06.02
    - Aeneas at https://github.com/cryspen/aeneas/releases/tag/nightly-2026.06.04
      — note: the `aeneas-pin` file in hax-evit at this commit names tag
      `nightly-2026.06.03`, but commit `8d2077c` (the SHA the binary
      must report) actually ships in `nightly-2026.06.04`. Use the
      `06.04` release.

### Verifying the Lean proof

From `libcrux-iot/ml-dsa/proofs/aeneas-lean/`:

```bash
lake exe cache get
lake build
```

### Extraction from Rust into Lean

```bash
# Spec side (from a checkout of cryspen/libcrux):
cd specs/ml-dsa/
./hax_aeneas.py

# Impl side:
cd libcrux-iot/ml-dsa/
./hax_aeneas.py
```