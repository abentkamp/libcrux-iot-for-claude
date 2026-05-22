# SHA-3 Keccak-f[1600] impl ↔ spec equivalence

This tree contains the Lean 4 proof that the bit-interleaved Rust
implementation of Keccak-f[1600] in `libcrux-iot/sha3/src/` computes
the same function as the FIPS-202 / hacspec specification in
`specs/sha3/src/`. Both sides are auto-extracted via the
[hax → aeneas → aeneas-lean](https://github.com/AeneasVerif/aeneas)
pipeline; this directory then proves their equivalence.

## Main theorem

[`Composition/HacspecBridge.lean`](Composition/HacspecBridge.lean):

```lean
theorem keccakf1600_equiv_hacspec (s : state.KeccakState)
    (h_i : s.i = 0#usize) :
    ⦃ ⌜ True ⌝ ⦄
    keccak.keccakf1600 s
    ⦃ ⇓ r_impl => ⌜ keccak_f.keccak_f (lift s) = .ok (lift r_impl) ⌝ ⦄
```

Informally: the impl's 24-round Keccak-f[1600] permutation, lifted
to the spec's flat-`u64[25]` representation, equals what the hacspec
top-level `keccak_f.keccak_f` (defined in `specs/sha3/src/keccak_f.rs`,
extracted to `HacspecSha3/Extraction/Funs.lean`) produces when applied
to the same lifted input. Only standard Lean axioms (`propext`,
`Classical.choice`, `Quot.sound`) plus `Lean.ofReduceBool` /
`Lean.trustCompiler` inherited transitively from a single
`native_decide` in
[`Foundation/RcEquiv.lean`](Foundation/RcEquiv.lean) (24-entry
round-constant identity check under `@[irreducible]` arrays).

## Proof architecture

The two sides represent state differently. **Spec**: 25 lanes of
`u64`. **Impl**: 25 lanes split into bit-interleaved 32-bit half
pairs `(z0, z1)` (so 64-bit rotations on 32-bit targets reduce to
32-bit rotations + half-swaps). Additionally, the impl uses storage
relabeling for π: each round reads from a different physical layout.
The relabeling permutation `impl_perm : Fin 25 → Fin 25` has order 4.

The bridge `lift : KeccakState → Array u64 25` (in
[`Foundation/Lift.lean`](Foundation/Lift.lean)) interleaves halves
back into `u64`s. A generalised `lift_perm s p sw` reads each lane
through a permutation `p` and an optional half-swap `sw : Fin 25 → Bool`.

The proof factors through a **pure-Lean intermediate spec**
`bit_keccak_spec : KState → KState` (in
[`BitSpec/Spec.lean`](BitSpec/Spec.lean)) that mirrors the impl's
bit-side data flow without the Aeneas monad. The chain of theorems
runs:

```
              StructuralEquiv          AlgebraicEquiv          Composition.HacspecBridge
impl ─────────────────────→ bit_keccak_spec ──────→ spec_chain (lift s) 24 ─────→ keccak_f.keccak_f (lift s)
   keccakf1600_eq               bit_keccak_spec_alg_eq          spec_chain_hacspec_eq_spec_chain
   (mvcgen + structural)        (algebraic, lift-aware)         + keccak_f_loop_eq_spec_chain_hacspec
                            \____________________________/
                             Composition/ViaBit.lean
                          (keccakf1600_equiv_via_bit)
```

Three named pieces (one file each at the top of the proof tree):

- **`StructuralEquiv.lean`** (impl ≡ `bit_keccak_spec`). Proves the
  Rust extraction equals the pure-Lean bit spec under
  `KState.fromAeneas`. ~3700 lines, no algebraic reasoning; mostly
  `mvcgen` + structural induction.

- **`AlgebraicEquiv.lean`** (`bit_keccak_spec` lifted ≡ hacspec
  unrolled chain). Proves the pure-Lean bit spec, lifted to `u64`,
  equals the spec round application. Per-round identities
  `bit_round{k}_alg_eq` compose into the 24-round
  `bit_keccak_spec_alg_eq`. This is the algebraic content
  (`lift_lane_bv`, `impl_perm`, `impl_swap_k` cycle).

- **`Composition/`**:
  - **`ViaBit.lean`** — composes the two equivalences above to
    produce a Triple on `keccak.keccakf1600` with post against
    `spec_round_step` iterated 24 times.
  - **`HacspecBridge.lean`** — couples the `_unrolled` spec functions
    to the non-`_unrolled` hacspec top-level `keccak_f.keccak_f` and
    its `Usize` loop, then composes with `ViaBit` to yield the top
    theorem `keccakf1600_equiv_hacspec`.

### Time-varying polarity (the load-bearing architectural pivot)

`AlgebraicEquiv`'s per-round identities use a time-varying half-swap
function `impl_swap_k : Nat → Fin 25 → Bool` with a 4-cycle:
`impl_swap_k 0 = swZero`, `impl_swap_k 1 = impl_swap`, `impl_swap_k 2`
and `impl_swap_k 3` track intermediate polarities, `impl_swap_k 4 =
impl_swap_k 0`. Both ends of each 4-round chunk land on `swZero`, so
the canonical `lift` threads through the 24-round chain
unconditionally. An earlier attempt used a `BalancedAt` precondition;
it was abandoned after empirical evidence that `Balanced` is not
preserved across rounds 1–3.

## File map

```
LibcruxIotSha3/
├── README.md                    ← you are here
│
├── Foundation/                  ← shared infrastructure (used by all three
│   │                              of StructuralEquiv, AlgebraicEquiv,
│   │                              Composition)
│   ├── Lift.lean                ← lift_lane_bv, lift, lift_perm, impl_perm,
│   │                              impl_swap, impl_swap_k + 4-cycle lemmas,
│   │                              ~40 bv_decide-closed `rot_N` lemmas
│   ├── UScalarAC.lean           ← Std.Associative/Commutative on
│   │                              Std.UScalar.xor/and/or (Aeneas surface fill)
│   ├── RcEquiv.lean             ← rc_equiv: bit-interleaved round constants
│   │                              match the spec's ROUND_CONSTANTS
│   ├── SpecStep.lean            ← spec_round_step, roundOfNat,
│   │                              keccakf1600_post_canonical, holds_chain_eq_ok
│   ├── SpecChain.lean           ← spec_chain Nat.fold wrapper + helpers
│   ├── I32LoopSpec.lean         ← I32 iterator + loop_range_spec_i32
│   ├── ThetaLiftDefs.lean       ← 11 round-0 θ sub-fn @[spec]s
│   │                              + theta_comp_spec_local
│   │                              + lift_theta_applied(_perm) defs
│   │                              + theta_c_proof macro
│   ├── ThetaLift.lean           ← round-0 theta_lift_spec
│   ├── ThetaLiftRound{1,2,3}.lean ← per-round θ specs
│   ├── PrcLift.lean             ← 10 round-0 πρχι sub-fn @[spec]s
│   │                              + prc_y_zeta_no_rc_proof macro
│   │                              + prc_lift_spec
│   ├── PrcLiftRound{1,2,3}.lean ← per-round πρχι specs
│   └── RoundEquiv.lean          ← round_k_equiv_spec for k=0..3 +
│                                  triple combinators
│
├── BitSpec/                     ← pure-Lean intermediate spec (defs only)
│   ├── State.lean               ← KState
│   ├── StateIso.lean            ← KState ↔ state.KeccakState round-trips
│   ├── Project.lean             ← projections / accessors
│   └── Spec.lean                ← bit_keccak_spec + bit_keccakf1600_*
│                                  pure-Lean step functions
│
├── StructuralEquiv.lean         ← impl ≡ bit_keccak_spec (via mvcgen +
│                                  structural induction, ~3700 LOC)
│
├── AlgebraicEquiv.lean          ← bit_round_k_alg_eq + bit_4rounds_alg_eq
│                                  + bit_keccak_spec_alg_eq (24-round closure)
│
├── Composition/                 ← composition of the two equivalences
│   ├── ViaBit.lean              ← keccakf1600_equiv_via_bit (StructuralEquiv
│   │                              ∘ AlgebraicEquiv) — Triple on the impl
│   └── HacspecBridge.lean       ← hacspec coupling: createi_pure_spec,
│                                  per-closure [spec] Triples, four
│                                  keccak_f.X = keccak_f.X_unrolled equalities,
│                                  spec_chain_hacspec_eq_spec_chain, Usize
│                                  iterator/loop specs, keccak_f_loop_eq_*,
│                                  and the top theorem keccakf1600_equiv_hacspec
│
└── Extraction/
    ├── Funs.lean                ← Rust impl extraction (generated; do not edit)
    └── Missing.lean             ← hand-written aeneas surface fills
```

### Namespaces

| Directory                | Namespace                            |
|--------------------------|--------------------------------------|
| `Foundation/`            | `libcrux_iot_sha3.Foundation`        |
| `BitSpec/`               | `libcrux_iot_sha3.BitSpec`           |
| `StructuralEquiv.lean`   | `libcrux_iot_sha3.Structural`        |
| `AlgebraicEquiv.lean`    | `libcrux_iot_sha3.Algebraic`         |
| `Composition/`           | `libcrux_iot_sha3.Composition`       |

## Verifying

From `libcrux-iot/sha3/proofs/aeneas-lean/`:

```bash
lake exe cache get        # one-time prime
lake build LibcruxIotSha3.Composition.HacspecBridge   # final hacspec coupling
# or LibcruxIotSha3.Composition.ViaBit for the bit-interleaved post only
```

Expected: 0 sorries, only standard Lean axioms.
`keccakf1600_equiv_hacspec` and `keccakf1600_equiv_via_bit` both
report `propext` + `Classical.choice` + `Quot.sound` + `Lean.ofReduceBool`
+ `Lean.trustCompiler`. The non-standard `Lean.ofReduceBool`/
`Lean.trustCompiler` come from a single `native_decide` in
`Foundation/RcEquiv.lean` (24-entry round-constant identity check)
needed because the round-constant arrays are `@[irreducible]`.

```bash
grep -rn "by sorry\|^  sorry" LibcruxIotSha3/   # must be empty
```

## See also

- [`Foundation/README.md`](Foundation/README.md) — extraction pipeline
  and per-file iteration tips.
