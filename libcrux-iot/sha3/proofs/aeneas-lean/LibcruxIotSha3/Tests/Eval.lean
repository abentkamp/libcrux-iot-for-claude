-- Executable test harness for the generated SHA-3 / SHAKE code.
--
-- The Aeneas extraction (`LibcruxIotSha3.Extraction.Funs`) wraps everything in a
-- `noncomputable section` purely by default (Aeneas notes this can be dropped via
-- the `-all-computable` CLI option). With that line removed the generated `Result`
-- monad code is ordinary executable Lean, so we can run the hash functions here on
-- known-answer test (KAT) vectors and check the output.
--
-- We use `#eval!` because the Aeneas `Std` library contains a `sorry`-stubbed
-- `core.slice.Slice.get_unchecked` that the sorry-dependency check flags
-- transitively. That stub is never executed on the SHA-3 code path (it is not
-- referenced by the extraction), so evaluation produces the genuine digests, which
-- we then check against the known-answer vectors below.
import LibcruxIotSha3.Extraction.Funs

open Aeneas Aeneas.Std
open libcrux_iot_sha3

namespace LibcruxIotSha3.Tests

/-! ## Marshalling helpers -/

/-- Build a `U8` from a `Nat` (truncating mod 256). -/
def mkU8 (n : Nat) : U8 := { bv := BitVec.ofNat 8 n }

/-- Build a `Slice U8` from a list of byte values. -/
def mkSlice (l : List Nat) (h : l.length ≤ Usize.max := by scalar_tac) : Slice U8 :=
  ⟨ l.map mkU8, by simpa using h ⟩

/-! ## Hex formatting -/

def hexDigit (n : Nat) : Char := "0123456789abcdef".toList[n % 16]!

def hexByte (n : Nat) : String := String.ofList [hexDigit (n / 16), hexDigit (n % 16)]

/-- Render a list of bytes as a lowercase hex string. -/
def toHex (l : List U8) : String := String.join (l.map (fun b => hexByte b.val))

/-- Extract the hex digest from a `Result (Array U8 n)`. -/
def digestHex {n : Usize} (r : Result (Array U8 n)) : String :=
  match r with
  | .ok a => toHex a.val
  | .fail _ => "<fail>"
  | .div => "<div>"

/-- Compare a computed digest against an expected KAT vector. -/
def check (label expected got : String) : String :=
  s!"[{if got == expected then "PASS" else "FAIL"}] {label}\n    got      = {got}\n    expected = {expected}"

/-! ## Known-answer tests

`"Hello, World!"` and SHAKE128 vectors are taken verbatim from the repo's own
Rust KATs (`libcrux-iot/sha3/tests/sha3.rs`); the empty / "abc" vectors are the
canonical FIPS-202 test values. -/

-- "Hello, World!" = 13 bytes (`abbrev` so its length reduces for the bound proof)
abbrev helloBytes : List Nat := [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]

#eval! check "SHA3-224(\"\")"
  "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7"
  (digestHex (sha224 (mkSlice [])))

#eval! check "SHA3-256(\"\")"
  "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
  (digestHex (sha256 (mkSlice [])))

#eval! check "SHA3-256(\"abc\")"
  "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"
  (digestHex (sha256 (mkSlice [97, 98, 99])))

#eval! check "SHA3-384(\"\")"
  "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004"
  (digestHex (sha384 (mkSlice [])))

#eval! check "SHA3-512(\"\")"
  "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26"
  (digestHex (sha512 (mkSlice [])))

#eval! check "SHA3-256(\"Hello, World!\")"
  "1af17a664e3fa8e419b8ba05c2a173169df76162a5a286e0c405b460d478f7ef"
  (digestHex (sha256 (mkSlice helloBytes)))

#eval! check "SHAKE128(\"Hello, World!\", 42)"
  "2bf5e6dee6079fad604f573194ba8426bd4d30eb13e8ba2edae70e529b570cbdd588f2c5dd4e465dfbaf"
  (digestHex (shake128 42#usize (mkSlice helloBytes)))

end LibcruxIotSha3.Tests
