/// Keccak-f[1600] permutation — FIPS 202, Section 3.3.
///
/// The state is a 5×5 array of 64-bit lanes stored as a flat `[u64; 25]`.
/// Lane `A[x, y]` maps to flat index `5*y + x`, matching the natural
/// flat indexing induced by FIPS 202 §3.1.2 (`A[x, y, z] = S[w(5y + x) + z]`)
/// and the Keccak reference implementation.
use crate::createi;

/// Keccak-f[1600] state: 5×5 lanes of 64-bit words.
/// Keccak state type, exposed for cross-crate verification.
pub type State = [u64; 25];

/// Read lane `A[x, y]`.
#[inline]
#[hax_lib::requires(x < 5 && y < 5)]
pub fn get(state: &State, x: usize, y: usize) -> u64 {
    state[5 * y + x]
}

// =========================================================================
// Constants — FIPS 202, Section 3.3 / Algorithm 5
// =========================================================================

/// Round constants `RC[ir]` for `ir = 0..23` — FIPS 202, Algorithm 5.
pub const ROUND_CONSTANTS: [u64; 24] = [
    0x0000_0000_0000_0001,
    0x0000_0000_0000_8082,
    0x8000_0000_0000_808A,
    0x8000_0000_8000_8000,
    0x0000_0000_0000_808B,
    0x0000_0000_8000_0001,
    0x8000_0000_8000_8081,
    0x8000_0000_0000_8009,
    0x0000_0000_0000_008A,
    0x0000_0000_0000_0088,
    0x0000_0000_8000_8009,
    0x0000_0000_8000_000A,
    0x0000_0000_8000_808B,
    0x8000_0000_0000_008B,
    0x8000_0000_0000_8089,
    0x8000_0000_0000_8003,
    0x8000_0000_0000_8002,
    0x8000_0000_0000_0080,
    0x0000_0000_0000_800A,
    0x8000_0000_8000_000A,
    0x8000_0000_8000_8081,
    0x8000_0000_0000_8080,
    0x0000_0000_8000_0001,
    0x8000_0000_8000_8008,
];

/// Rotation offsets for ρ step — FIPS 202, Algorithm 2 / Table 2.
///
/// Indexed as `RHO_OFFSETS[5*y + x]`.
pub const RHO_OFFSETS: [u32; 25] = [
    //  x=0  x=1  x=2  x=3  x=4
    0, 1, 62, 28, 27, // y = 0
    36, 44, 6, 55, 20, // y = 1
    3, 10, 43, 25, 39, // y = 2
    41, 45, 15, 21, 8, // y = 3
    18, 2, 61, 56, 14, // y = 4
];

// =========================================================================
// The five step mappings — FIPS 202, Algorithms 1–6
// =========================================================================

/// θ step — FIPS 202, Algorithm 1.
///
///   C[x]    = A[x,0] ⊕ A[x,1] ⊕ A[x,2] ⊕ A[x,3] ⊕ A[x,4]
///   D[x]    = C[x−1 mod 5] ⊕ rot(C[x+1 mod 5], 1)
///   A′[x,y] = A[x,y] ⊕ D[x]
pub fn theta(state: State) -> State {
    let c: [u64; 5] = createi(|x| {
        get(&state, x, 0)
            ^ get(&state, x, 1)
            ^ get(&state, x, 2)
            ^ get(&state, x, 3)
            ^ get(&state, x, 4)
    });
    let d: [u64; 5] = createi(|x| c[(x + 4) % 5] ^ c[(x + 1) % 5].rotate_left(1));
    // Under the layout `state[5*y + x] = A[x, y]`, the x-coordinate is
    // `idx % 5`.
    createi(|idx| state[idx] ^ d[idx % 5])
}

/// ρ step — FIPS 202, Algorithm 2.
///
///   A′[x,y] = rot(A[x,y], offset(x,y))
pub fn rho(state: State) -> State {
    createi(|idx| state[idx].rotate_left(RHO_OFFSETS[idx]))
}

/// π step — FIPS 202, Algorithm 3.
///
///   A′[x,y] = A[(x + 3y) mod 5, x]
pub fn pi(state: State) -> State {
    createi(|idx| {
        // Under the layout `state[5*y + x] = A[x, y]`,
        // x = idx % 5, y = idx / 5.
        let y = idx / 5;
        let x = idx % 5;
        get(&state, (x + 3 * y) % 5, x)
    })
}

/// χ step — FIPS 202, Algorithm 4.
///
///   A′[x,y] = A[x,y] ⊕ (¬A[(x+1) mod 5, y] ∧ A[(x+2) mod 5, y])
pub fn chi(state: State) -> State {
    createi(|idx| {
        // Under the layout `state[5*y + x] = A[x, y]`,
        // x = idx % 5, y = idx / 5.
        let y = idx / 5;
        let x = idx % 5;
        get(&state, x, y) ^ (!get(&state, (x + 1) % 5, y) & get(&state, (x + 2) % 5, y))
    })
}

/// ι step — FIPS 202, Algorithm 6.
///
///   A′[0,0] = A[0,0] ⊕ RC[ir]
#[hax_lib::requires(round < 24)]
pub fn iota(mut state: State, round: usize) -> State {
    state[0] ^= ROUND_CONSTANTS[round];
    state
}

// =========================================================================
// Unrolled step functions — straight-line forms for verification.
//
// These compute exactly the same values as `theta`/`rho`/`pi`/`chi` but
// avoid any `createi` closures, so Aeneas extracts them as plain
// `let … ← …; ok [s0, …, s24]` blocks (no `Vector.mapM`, no closure
// trait instances). They are the forms referenced by the Lean
// equivalence proof. Pure Rust tests below pin them to the `createi`
// versions so the two cannot drift.
// =========================================================================

/// θ step — straight-line (unrolled) form. Same value as `theta`.
pub fn theta_unrolled(state: State) -> State {
    // C[x] = A[x,0] ⊕ A[x,1] ⊕ A[x,2] ⊕ A[x,3] ⊕ A[x,4]
    //      = state[x] ⊕ state[5+x] ⊕ state[10+x] ⊕ state[15+x] ⊕ state[20+x]
    let c0 = state[0] ^ state[5] ^ state[10] ^ state[15] ^ state[20];
    let c1 = state[1] ^ state[6] ^ state[11] ^ state[16] ^ state[21];
    let c2 = state[2] ^ state[7] ^ state[12] ^ state[17] ^ state[22];
    let c3 = state[3] ^ state[8] ^ state[13] ^ state[18] ^ state[23];
    let c4 = state[4] ^ state[9] ^ state[14] ^ state[19] ^ state[24];
    // D[x] = C[(x+4)%5] ⊕ rot(C[(x+1)%5], 1)
    let d0 = c4 ^ c1.rotate_left(1);
    let d1 = c0 ^ c2.rotate_left(1);
    let d2 = c1 ^ c3.rotate_left(1);
    let d3 = c2 ^ c4.rotate_left(1);
    let d4 = c3 ^ c0.rotate_left(1);
    // A'[x,y] = A[x,y] ⊕ D[x]; A'[5y+x] = state[5y+x] ⊕ d_x
    [
        state[0] ^ d0,
        state[1] ^ d1,
        state[2] ^ d2,
        state[3] ^ d3,
        state[4] ^ d4,
        state[5] ^ d0,
        state[6] ^ d1,
        state[7] ^ d2,
        state[8] ^ d3,
        state[9] ^ d4,
        state[10] ^ d0,
        state[11] ^ d1,
        state[12] ^ d2,
        state[13] ^ d3,
        state[14] ^ d4,
        state[15] ^ d0,
        state[16] ^ d1,
        state[17] ^ d2,
        state[18] ^ d3,
        state[19] ^ d4,
        state[20] ^ d0,
        state[21] ^ d1,
        state[22] ^ d2,
        state[23] ^ d3,
        state[24] ^ d4,
    ]
}

/// ρ step — straight-line (unrolled) form. Same value as `rho`.
pub fn rho_unrolled(state: State) -> State {
    [
        state[0].rotate_left(0),
        state[1].rotate_left(1),
        state[2].rotate_left(62),
        state[3].rotate_left(28),
        state[4].rotate_left(27),
        state[5].rotate_left(36),
        state[6].rotate_left(44),
        state[7].rotate_left(6),
        state[8].rotate_left(55),
        state[9].rotate_left(20),
        state[10].rotate_left(3),
        state[11].rotate_left(10),
        state[12].rotate_left(43),
        state[13].rotate_left(25),
        state[14].rotate_left(39),
        state[15].rotate_left(41),
        state[16].rotate_left(45),
        state[17].rotate_left(15),
        state[18].rotate_left(21),
        state[19].rotate_left(8),
        state[20].rotate_left(18),
        state[21].rotate_left(2),
        state[22].rotate_left(61),
        state[23].rotate_left(56),
        state[24].rotate_left(14),
    ]
}

/// π step — straight-line (unrolled) form. Same value as `pi`.
///
/// A'[x,y] = A[(x+3y) mod 5, x]
///   = state[5*x + ((x+3y) mod 5)]
pub fn pi_unrolled(state: State) -> State {
    [
        state[0],  // (x=0,y=0): 5*0 + 0
        state[6],  // (x=1,y=0): 5*1 + 1
        state[12], // (x=2,y=0): 5*2 + 2
        state[18], // (x=3,y=0): 5*3 + 3
        state[24], // (x=4,y=0): 5*4 + 4
        state[3],  // (x=0,y=1): 5*0 + 3
        state[9],  // (x=1,y=1): 5*1 + 4
        state[10], // (x=2,y=1): 5*2 + 0
        state[16], // (x=3,y=1): 5*3 + 1
        state[22], // (x=4,y=1): 5*4 + 2
        state[1],  // (x=0,y=2): 5*0 + 1
        state[7],  // (x=1,y=2): 5*1 + 2
        state[13], // (x=2,y=2): 5*2 + 3
        state[19], // (x=3,y=2): 5*3 + 4
        state[20], // (x=4,y=2): 5*4 + 0
        state[4],  // (x=0,y=3): 5*0 + 4
        state[5],  // (x=1,y=3): 5*1 + 0
        state[11], // (x=2,y=3): 5*2 + 1
        state[17], // (x=3,y=3): 5*3 + 2
        state[23], // (x=4,y=3): 5*4 + 3
        state[2],  // (x=0,y=4): 5*0 + 2
        state[8],  // (x=1,y=4): 5*1 + 3
        state[14], // (x=2,y=4): 5*2 + 4
        state[15], // (x=3,y=4): 5*3 + 0
        state[21], // (x=4,y=4): 5*4 + 1
    ]
}

/// χ step — straight-line (unrolled) form. Same value as `chi`.
///
/// A'[x,y] = A[x,y] ⊕ (¬A[(x+1)%5, y] ∧ A[(x+2)%5, y])
///   = state[5y+x] ⊕ (¬state[5y + (x+1)%5] ∧ state[5y + (x+2)%5])
pub fn chi_unrolled(state: State) -> State {
    [
        state[0] ^ (!state[1] & state[2]),    // (x=0,y=0)
        state[1] ^ (!state[2] & state[3]),    // (x=1,y=0)
        state[2] ^ (!state[3] & state[4]),    // (x=2,y=0)
        state[3] ^ (!state[4] & state[0]),    // (x=3,y=0)
        state[4] ^ (!state[0] & state[1]),    // (x=4,y=0)
        state[5] ^ (!state[6] & state[7]),    // (x=0,y=1)
        state[6] ^ (!state[7] & state[8]),    // (x=1,y=1)
        state[7] ^ (!state[8] & state[9]),    // (x=2,y=1)
        state[8] ^ (!state[9] & state[5]),    // (x=3,y=1)
        state[9] ^ (!state[5] & state[6]),    // (x=4,y=1)
        state[10] ^ (!state[11] & state[12]), // (x=0,y=2)
        state[11] ^ (!state[12] & state[13]), // (x=1,y=2)
        state[12] ^ (!state[13] & state[14]), // (x=2,y=2)
        state[13] ^ (!state[14] & state[10]), // (x=3,y=2)
        state[14] ^ (!state[10] & state[11]), // (x=4,y=2)
        state[15] ^ (!state[16] & state[17]), // (x=0,y=3)
        state[16] ^ (!state[17] & state[18]), // (x=1,y=3)
        state[17] ^ (!state[18] & state[19]), // (x=2,y=3)
        state[18] ^ (!state[19] & state[15]), // (x=3,y=3)
        state[19] ^ (!state[15] & state[16]), // (x=4,y=3)
        state[20] ^ (!state[21] & state[22]), // (x=0,y=4)
        state[21] ^ (!state[22] & state[23]), // (x=1,y=4)
        state[22] ^ (!state[23] & state[24]), // (x=2,y=4)
        state[23] ^ (!state[24] & state[20]), // (x=3,y=4)
        state[24] ^ (!state[20] & state[21]), // (x=4,y=4)
    ]
}

// =========================================================================
// Keccak-f[1600] — FIPS 202, Algorithm 7
// =========================================================================

/// Keccak-f[1600] permutation — FIPS 202, Algorithm 7.
///
///   Rnd(A, ir) = ι(χ(π(ρ(θ(A)))), ir)
pub fn keccak_f(mut state: State) -> State {
    for round in 0..24 {
        state = iota(chi(pi(rho(theta(state)))), round);
    }
    state
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keccak_f_all_zeros() {
        // Known answer: after Keccak-f on the all-zero state, lane (0,0) has
        // a specific value that serves as a sanity check.
        let state = [0u64; 25];
        let result = keccak_f(state);
        assert_eq!(result[0], 0xF1258F7940E1DDE7);
    }

    #[test]
    fn keccak_f_all_ones() {
        let state = [0xFFFFFFFFFFFFFFFFu64; 25];
        let result = keccak_f(state);
        assert_ne!(result, state);
    }

    // ---------------------------------------------------------------------
    // Unrolled forms agree with the `createi` forms.
    // ---------------------------------------------------------------------

    fn random_state(seed: u64) -> State {
        // Tiny deterministic LCG — no rand dependency in the lib.
        let mut s = seed;
        core::array::from_fn(|_| {
            s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            s
        })
    }

    fn unroll_cases() -> [State; 5] {
        [
            [0u64; 25],
            [u64::MAX; 25],
            core::array::from_fn(|i| i as u64),
            random_state(0xABCDEF01),
            random_state(0xFEEDFACE),
        ]
    }

    #[test]
    fn theta_unrolled_matches_theta() {
        for s in unroll_cases() {
            assert_eq!(theta(s), theta_unrolled(s));
        }
    }

    #[test]
    fn rho_unrolled_matches_rho() {
        for s in unroll_cases() {
            assert_eq!(rho(s), rho_unrolled(s));
        }
    }

    #[test]
    fn pi_unrolled_matches_pi() {
        for s in unroll_cases() {
            assert_eq!(pi(s), pi_unrolled(s));
        }
    }

    #[test]
    fn chi_unrolled_matches_chi() {
        for s in unroll_cases() {
            assert_eq!(chi(s), chi_unrolled(s));
        }
    }
}
