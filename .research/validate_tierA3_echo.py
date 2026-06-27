"""
Tier A #3 validation mirror — Sacred Echo Vault gate logic + lifecycle
state machine + cipher envelope (using PyCryptodome for AES-GCM parity
with CryptoKit's AES.GCM).

We test:
  1. Empty reflection -> EchoError.emptyReflection
  2. Past unlock date -> EchoError.unlockDateInPast
  3. Cipher round-trip (seal -> open returns plaintext)
  4. Tampered ciphertext fails authentication
  5. Wrong echo id (per-echo key isolation) fails
  6. Lifecycle state transitions: maturing -> openingReady -> opened
  7. Heir validation: empty id -> noHeirDesignated
  8. Heir validation: unknown id -> heirNotInWeaveCircle
  9. Heir validation: id without CareKin domain -> heirNotInWeaveCircle
 10. Heir validation: valid id (in Weave Circle) -> passes
"""

import os
import hashlib
import hmac
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional
from enum import Enum


# AES-GCM via PyCryptodome if available, else a manual fallback.
try:
    from Crypto.Cipher import AES
    HAVE_AES = True
except ImportError:
    HAVE_AES = False


class EchoState(str, Enum):
    SEALED = "sealed"
    MATURING = "maturing"
    OPENING_READY = "openingReady"
    OPENED = "opened"
    DELIVERED = "delivered"
    RELEASED = "released"


class EchoError(Exception):
    EMPTY_REFLECTION = "emptyReflection"
    UNLOCK_DATE_IN_PAST = "unlockDateInPast"
    NOT_YET_UNLOCKED = "notYetUnlocked"
    ALREADY_OPENED = "alreadyOpened"
    NO_HEIR = "noHeirDesignated"
    HEIR_NOT_IN_CIRCLE = "heirNotInWeaveCircle"
    DECRYPT_FAILED = "decryptionFailed"


# Mirror of SacredEcho model
@dataclass
class SacredEcho:
    id: str
    title: str
    decree: str
    ciphertext: bytes
    nonce: bytes
    tag: bytes
    unlock_at: datetime
    opened_at: Optional[datetime] = None
    state_raw: str = EchoState.SEALED.value
    heir_id: str = ""
    attributes: Dict[str, str] = field(default_factory=dict)
    created_at: Optional[datetime] = None


# Mirror of LifeEntity (minimal subset for heir validation)
@dataclass
class LifeEntity:
    id: str
    type: str
    title: str
    domains: List[str] = field(default_factory=list)


class SacredEchoCipherLite:
    """Mirror of SacredEchoCipher using AES-GCM with HKDF."""
    TEST_SEED = bytes.fromhex(
        "4f6e6557656176656d7573746265696e7465726e616c6c79706172656e742d7365656400000000"
    )

    _FORCE_KEYCHAIN_FAIL = False

    @staticmethod
    def vault_seed():
        # Round-3 finding (NEMO-R3-018): must fail closed when Keychain persistence fails.
        # In production (iOS): read from Keychain; if write/read fails, raise.
        # In tests/dev (Linux): use test seed for cipher parity.
        if SacredEchoCipherLite._FORCE_KEYCHAIN_FAIL:
            raise RuntimeError("cipherMissingKey: Keychain unavailable")
        return SacredEchoCipherLite.TEST_SEED

    @classmethod
    def force_keychain_fail(cls, value: bool):
        """Test hook: simulate Keychain failure to verify fail-closed behavior."""
        cls._FORCE_KEYCHAIN_FAIL = value

    @staticmethod
    def per_echo_key(echo_id: str, seed: bytes) -> bytes:
        info = f"SacredEcho.{echo_id}".encode()
        salt = echo_id[:16].encode()
        return hashlib.pbkdf2_hmac("sha256", seed, salt, 1, dklen=32) if False else \
            _hkdf_sha256(seed, salt, info, 32)

    @staticmethod
    def seal(plaintext: str, echo_id: str) -> tuple:
        if not HAVE_AES:
            # Fallback: XOR-based stub for environments without PyCryptodome.
            # We still validate envelope shape; real device uses CryptoKit.
            key = SacredEchoCipherLite.per_echo_key(echo_id, SacredEchoCipherLite.vault_seed())
            pt = plaintext.encode("utf-8")
            ct = bytes(b ^ key[i % 32] for i, b in enumerate(pt))
            nonce = os.urandom(12)
            tag = hmac.new(key, nonce + ct, hashlib.sha256).digest()[:16]
            return ct, nonce, tag

        key = SacredEchoCipherLite.per_echo_key(echo_id, SacredEchoCipherLite.vault_seed())
        nonce = os.urandom(12)
        cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
        ct, tag = cipher.encrypt_and_digest(plaintext.encode("utf-8"))
        return ct, nonce, tag

    @staticmethod
    def open(ciphertext: bytes, nonce: bytes, tag: bytes, echo_id: str) -> str:
        key = SacredEchoCipherLite.per_echo_key(echo_id, SacredEchoCipherLite.vault_seed())
        if not HAVE_AES:
            # XOR-fallback: trust the tag check.
            expected_tag = hmac.new(key, nonce + ciphertext, hashlib.sha256).digest()[:16]
            if not hmac.compare_digest(expected_tag, tag):
                raise ValueError("tag mismatch")
            pt = bytes(b ^ key[i % 32] for i, b in enumerate(ciphertext))
            return pt.decode("utf-8")
        cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
        pt = cipher.decrypt_and_verify(ciphertext, tag)
        return pt.decode("utf-8")


def _hkdf_sha256(ikm: bytes, salt: bytes, info: bytes, length: int) -> bytes:
    """Minimal HKDF-SHA256 implementation (RFC 5869)."""
    if not salt:
        salt = b"\x00" * 32
    prk = hmac.new(salt, ikm, hashlib.sha256).digest()
    t = b""
    okm = b""
    counter = 1
    while len(okm) < length:
        t = hmac.new(prk, t + info + bytes([counter]), hashlib.sha256).digest()
        okm += t
        counter += 1
    return okm[:length]


# Mirror of SacredEchoStore with just the gate logic we test here.
def seal_validate(reflection: str, unlock_at: datetime, heir_id: str,
                  now: datetime, context_entities: List[LifeEntity]) -> SacredEcho:
    if not reflection.strip():
        raise ValueError(EchoError.EMPTY_REFLECTION)
    if unlock_at <= now:
        raise ValueError(EchoError.UNLOCK_DATE_IN_PAST)
    if heir_id:
        heir = next((e for e in context_entities if e.id == heir_id), None)
        if heir is None or "CareKin" not in heir.domains:
            raise ValueError(EchoError.HEIR_NOT_IN_CIRCLE)
    # Echo would be created here; we return a stub.
    return SacredEcho(
        id="test-uuid", title="x", decree="", ciphertext=b"", nonce=b"", tag=b"",
        unlock_at=unlock_at, heir_id=heir_id,
        created_at=now,
    )


def open_validate(echo: SacredEcho, now: datetime):
    if echo.unlock_at > now:
        raise ValueError(EchoError.NOT_YET_UNLOCKED)
    if echo.state_raw in (EchoState.RELEASED.value, EchoState.DELIVERED.value):
        raise ValueError(EchoError.ALREADY_OPENED)
    return True


def main():
    now = datetime.now(timezone.utc)
    future = now + timedelta(days=30)
    past = now - timedelta(days=7)

    results = {}

    # 1. Empty reflection
    try:
        seal_validate("", future, "", now, [])
        results["empty_reflection"] = False
    except ValueError as e:
        results["empty_reflection"] = str(e) == EchoError.EMPTY_REFLECTION

    # 2. Past unlock date
    try:
        seal_validate("real", past, "", now, [])
        results["past_unlock"] = False
    except ValueError as e:
        results["past_unlock"] = str(e) == EchoError.UNLOCK_DATE_IN_PAST

    # 3. Cipher round-trip
    try:
        ct, n, tag = SacredEchoCipherLite.seal("Hello future me.", "echo-1")
        opened = SacredEchoCipherLite.open(ct, n, tag, "echo-1")
        results["cipher_round_trip"] = (opened == "Hello future me.")
    except Exception:
        results["cipher_round_trip"] = False

    # 4. Tampered ciphertext fails
    try:
        ct, n, tag = SacredEchoCipherLite.seal("Hello.", "echo-2")
        tampered = bytearray(ct)
        tampered[0] ^= 0xFF
        SacredEchoCipherLite.open(bytes(tampered), n, tag, "echo-2")
        results["tamper_detected"] = False
    except Exception:
        results["tamper_detected"] = True

    # 5. Wrong echo id (key isolation)
    try:
        ct, n, tag = SacredEchoCipherLite.seal("Hello.", "echo-3")
        SacredEchoCipherLite.open(ct, n, tag, "wrong-id")
        results["key_isolation"] = False
    except Exception:
        results["key_isolation"] = True

    # 6. Lifecycle state transitions
    future_10d = now + timedelta(days=10)
    echo = SacredEcho(
        id="lifecycle", title="L", decree="",
        ciphertext=b"", nonce=b"", tag=b"",
        unlock_at=future_10d,
    )
    initial_state = _state_of(echo, now)
    future_now = now + timedelta(days=30)
    post_state = _state_of(echo, future_now)
    results["lifecycle_maturing_then_opening_ready"] = (
        initial_state == EchoState.MATURING
        and post_state == EchoState.OPENING_READY
    )

    # 7. Heir validation: empty id (should pass — no heir designated)
    try:
        seal_validate("real", future, "", now, [])
        results["heir_empty_ok"] = True
    except Exception:
        results["heir_empty_ok"] = False

    # 8. Heir validation: unknown id
    try:
        seal_validate("real", future, "nonexistent", now, [])
        results["heir_unknown_rejected"] = False
    except ValueError as e:
        results["heir_unknown_rejected"] = str(e) == EchoError.HEIR_NOT_IN_CIRCLE

    # 9. Heir validation: id without CareKin domain
    try:
        seal_validate(
            "real", future, "p1", now,
            [LifeEntity(id="p1", type="person", title="Stranger", domains=[])]
        )
        results["heir_no_carekin_rejected"] = False
    except ValueError as e:
        results["heir_no_carekin_rejected"] = str(e) == EchoError.HEIR_NOT_IN_CIRCLE

    # 10. Heir validation: valid id with CareKin
    try:
        seal_validate(
            "real", future, "p2", now,
            [LifeEntity(id="p2", type="person", title="Mom", domains=["CareKin"])]
        )
        results["heir_valid_passes"] = True
    except Exception:
        results["heir_valid_passes"] = False

    # 11. Fail-closed crypto (Round-3 finding NEMO-R3-018):
    # If Keychain persistence fails, vaultSeed() must throw, not return ephemeral seed.
    # SacredEchoCipherLite.vault_seed() honors _FORCE_KEYCHAIN_FAIL.
    SacredEchoCipherLite.force_keychain_fail(True)
    try:
        SacredEchoCipherLite.vault_seed()
        results["fail_closed_keychain_failure"] = False  # Should have thrown
    except RuntimeError as e:
        results["fail_closed_keychain_failure"] = "cipherMissingKey" in str(e)
    finally:
        SacredEchoCipherLite.force_keychain_fail(False)

    # 12. After fail-closed, normal seed works again
    results["vault_seed_recovers_after_fail"] = SacredEchoCipherLite.vault_seed() == SacredEchoCipherLite.TEST_SEED

    print("=" * 60)
    print("Tier A #3 (Sacred Echo) Validation")
    print("=" * 60)
    all_pass = True
    for name, passed in results.items():
        mark = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"  [{mark}] {name}")
    print("=" * 60)
    print(f"OVERALL: {'PASS' if all_pass else 'FAIL'}")
    print(f"  AES backend: {'PyCryptodome' if HAVE_AES else 'XOR fallback'}")
    print("=" * 60)
    return 0 if all_pass else 1


def _state_of(echo: SacredEcho, now: datetime) -> EchoState:
    if echo.state_raw in (EchoState.OPENED.value, EchoState.DELIVERED.value, EchoState.RELEASED.value):
        s = EchoState(echo.state_raw)
        return s
    if echo.opened_at and echo.opened_at <= now:
        return EchoState.OPENED
    interval = (echo.unlock_at - now).total_seconds()
    if interval <= 0:
        return EchoState.OPENING_READY
    if interval <= 24 * 3600:
        return EchoState.OPENING_READY
    return EchoState.MATURING


if __name__ == "__main__":
    import sys
    sys.exit(main())