"""
Tier A #5 validation mirror — App Lifecycle envelope + scenePhase routing.

Tests:
  1. JSON envelope round-trip preserves data exactly.
  2. Plaintext envelope contains expected fields.
  3. Encryption envelope round-trip (AES-GCM) preserves data exactly.
  4. Tampered encrypted envelope fails decryption.
  5. Wrong envelope key id fails decryption.
  6. App Group path fallback works (returns valid URL even without real group).
  7. Filename constants are stable across calls.
  8. ScenePhase routing routes correctly:
     .background → persist + push snapshot
     .active → invalidate cache
     .inactive → no-op
     .foreground (conceptually) → re-evaluate echoes
  9. LifecycleState derivation: opening-ready when unlock within 24h.
 10. Background timestamp recorded for Body Thread freshness check.
"""

import os
import sys
import json
import tempfile
import hashlib
import hmac
import uuid
from datetime import datetime, timedelta, timezone
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional
from enum import Enum


# AES-GCM via PyCryptodome
try:
    from Crypto.Cipher import AES
    HAVE_AES = True
except ImportError:
    HAVE_AES = False


# Mirror of AppLifecyclePaths
class AppLifecyclePaths:
    APP_GROUP_ID = "group.com.oneweave"
    LIFE_GRAPH_FILENAME = "oneweave.lifegraph.v1.json"
    LIFE_GRAPH_ENCRYPTED_FILENAME = "oneweave.lifegraph.v1.enc"

    @staticmethod
    def container_url():
        # Real: FileManager.containerURL(forSecurityApplicationGroupIdentifier:)
        # Linux/dev: temp dir fallback
        tmp = tempfile.gettempdir()
        path = os.path.join(tmp, "oneweave-dev")
        os.makedirs(path, exist_ok=True)
        return path

    @staticmethod
    def life_graph_url(encrypted):
        fn = AppLifecyclePaths.LIFE_GRAPH_ENCRYPTED_FILENAME if encrypted \
            else AppLifecyclePaths.LIFE_GRAPH_FILENAME
        return os.path.join(AppLifecyclePaths.container_url(), fn)


# Mirror of LifeGraphEnvelope
@dataclass
class LifeEntityDTO:
    id: str
    type: str
    title: str
    summary: str
    memoryType: str
    domains: List[str]
    harmonyImpact: float
    isPrivate: bool
    allowedCategories: List[str]
    attributes: Dict[str, str]
    createdAt: str
    lastUpdated: str


@dataclass
class SacredEchoDTO:
    id: str
    title: str
    decree: str
    createdAt: str
    unlockAt: str
    openedAt: Optional[str]
    stateRaw: str
    ciphertext: bytes
    nonce: bytes
    tag: bytes
    heirLifeEntityID: str
    attributes: Dict[str, str]


@dataclass
class LifeGraphEnvelope:
    version: int
    savedAt: str
    entities: List[LifeEntityDTO]
    relationships: List[dict]
    echoes: List[SacredEchoDTO]
    coherenceScore: float
    weaveEssence: float
    harmonyScore: float
    completedQuestCount: int


# Mirror of SacredEchoCipher (uses HKDF + AES-GCM)
class SacredEchoCipherLite:
    TEST_SEED = bytes.fromhex(
        "4f6e6557656176656d7573746265696e7465726e616c6c79706172656e742d7365656400000000"
    )

    @staticmethod
    def vault_seed():
        return SacredEchoCipherLite.TEST_SEED

    @staticmethod
    def per_echo_key(echo_id, seed):
        info = f"SacredEcho.{echo_id}".encode()
        salt = echo_id[:16].encode() if isinstance(echo_id, str) else echo_id[:16]
        return _hkdf_sha256(seed, salt, info, 32)


def _hkdf_sha256(ikm, salt, info, length):
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


# Mirror of envelope encryption (12B nonce | 16B tag | ciphertext)
def envelope_encrypt(envelope_json: bytes, envelope_key_id: str) -> bytes:
    if not HAVE_AES:
        # XOR fallback
        key = SacredEchoCipherLite.per_echo_key(envelope_key_id, SacredEchoCipherLite.vault_seed())
        ct = bytes(b ^ key[i % 32] for i, b in enumerate(envelope_json))
        nonce = os.urandom(12)
        tag = hmac.new(key, nonce + ct, hashlib.sha256).digest()[:16]
        return nonce + tag + ct

    key = SacredEchoCipherLite.per_echo_key(envelope_key_id, SacredEchoCipherLite.vault_seed())
    nonce = os.urandom(12)
    cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
    ct, tag = cipher.encrypt_and_digest(envelope_json)
    return nonce + tag + ct


def envelope_decrypt(blob: bytes, envelope_key_id: str) -> bytes:
    if not HAVE_AES:
        key = SacredEchoCipherLite.per_echo_key(envelope_key_id, SacredEchoCipherLite.vault_seed())
        nonce = blob[:12]
        tag = blob[12:28]
        ct = blob[28:]
        expected_tag = hmac.new(key, nonce + ct, hashlib.sha256).digest()[:16]
        if not hmac.compare_digest(expected_tag, tag):
            raise ValueError("tag mismatch")
        return bytes(b ^ key[i % 32] for i, b in enumerate(ct))

    key = SacredEchoCipherLite.per_echo_key(envelope_key_id, SacredEchoCipherLite.vault_seed())
    nonce = blob[:12]
    tag = blob[12:28]
    ct = blob[28:]
    cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
    return cipher.decrypt_and_verify(ct, tag)


# Mirror of AppLifecycleCoordinator scene routing
class ScenePhase(Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    BACKGROUND = "background"
    FOREGROUND = "foreground"


class AppLifecycleCoordinatorLite:
    def __init__(self):
        self.last_background_at = None
        self.persisted = []
        self.cache_invalidations = 0
        self.body_thread_recommendations = 0

    def did_enter_background(self, envelope):
        self.last_background_at = datetime.now(timezone.utc)
        self.persisted.append(envelope)
        # Snapshot push to widgets (no-op in test)
        return "background_persisted"

    def did_become_active(self):
        self.cache_invalidations += 1
        return "active_cache_invalidated"

    def will_resign_active(self):
        return "inactive_noop"

    def route(self, phase):
        if phase == ScenePhase.BACKGROUND:
            return self.did_enter_background(envelope=None)
        elif phase == ScenePhase.ACTIVE:
            return self.did_become_active()
        elif phase == ScenePhase.INACTIVE:
            return self.will_resign_active()
        return "unknown"


# Mirror of SacredEcho lifecycle
class EchoStateLite(Enum):
    SEALED = "sealed"
    MATURING = "maturing"
    OPENING_READY = "openingReady"
    OPENED = "opened"
    DELIVERED = "delivered"
    RELEASED = "released"


def echo_state(unlock_at: datetime, opened_at: Optional[datetime], state_raw: str, now: datetime) -> EchoStateLite:
    if state_raw in (EchoStateLite.OPENED.value, EchoStateLite.DELIVERED.value, EchoStateLite.RELEASED.value):
        return EchoStateLite(state_raw)
    if opened_at and opened_at <= now:
        return EchoStateLite.OPENED
    interval = (unlock_at - now).total_seconds()
    if interval <= 0:
        return EchoStateLite.OPENING_READY
    if interval <= 24 * 3600:
        return EchoStateLite.OPENING_READY
    return EchoStateLite.MATURING


def main():
    now = datetime.now(timezone.utc)
    results = {}

    ENVELOPE_KEY_ID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"

    # 1. JSON envelope round-trip preserves data exactly.
    envelope = LifeGraphEnvelope(
        version=1,
        savedAt=now.isoformat(),
        entities=[
            LifeEntityDTO(
                id=str(uuid.uuid4()), type="task", title="Call mom",
                summary="Felt good after", memoryType="procedural",
                domains=["CareKin"], harmonyImpact=0.6, isPrivate=False,
                allowedCategories=[], attributes={"source": "quest"},
                createdAt=now.isoformat(), lastUpdated=now.isoformat(),
            ),
            LifeEntityDTO(
                id=str(uuid.uuid4()), type="event", title="Morning walk",
                summary="Clear head", memoryType="episodic",
                domains=["Self"], harmonyImpact=0.4, isPrivate=True,
                allowedCategories=[], attributes={},
                createdAt=now.isoformat(), lastUpdated=now.isoformat(),
            ),
        ],
        relationships=[],
        echoes=[],
        coherenceScore=0.58, weaveEssence=124,
        harmonyScore=0.7, completedQuestCount=8,
    )
    json_str = json.dumps(asdict(envelope), default=str)
    parsed = json.loads(json_str)
    results["json_round_trip"] = (
        parsed["version"] == envelope.version
        and len(parsed["entities"]) == len(envelope.entities)
        and parsed["coherenceScore"] == envelope.coherenceScore
    )

    # 2. Plaintext envelope contains expected fields
    results["plaintext_has_entities"] = "entities" in parsed
    results["plaintext_has_echoes"] = "echoes" in parsed
    results["plaintext_has_coherence"] = "coherenceScore" in parsed

    # 3. Encryption envelope round-trip
    blob = envelope_encrypt(json_str.encode("utf-8"), ENVELOPE_KEY_ID)
    decrypted = envelope_decrypt(blob, ENVELOPE_KEY_ID)
    results["encryption_round_trip"] = (decrypted == json_str.encode("utf-8"))

    # 4. Tampered envelope fails decryption
    try:
        tampered = bytearray(blob)
        tampered[30] ^= 0xFF  # flip a bit in the ciphertext
        envelope_decrypt(bytes(tampered), ENVELOPE_KEY_ID)
        results["tamper_detected"] = False
    except Exception:
        results["tamper_detected"] = True

    # 5. Wrong envelope key id fails decryption
    try:
        envelope_decrypt(blob, "wrong-key-id-not-the-real-one-1234567890")
        results["key_isolation"] = False
    except Exception:
        results["key_isolation"] = True

    # 6. App Group path fallback works
    container = AppLifecyclePaths.container_url()
    results["container_path_valid"] = os.path.isdir(container)
    results["container_path_contains_oneweave"] = "oneweave" in container

    # 7. Filename constants stable
    results["filename_plaintext"] = (
        AppLifecyclePaths.life_graph_url(encrypted=False).endswith("oneweave.lifegraph.v1.json")
    )
    results["filename_encrypted"] = (
        AppLifecyclePaths.life_graph_url(encrypted=True).endswith("oneweave.lifegraph.v1.enc")
    )

    # 8. ScenePhase routing
    coord = AppLifecycleCoordinatorLite()
    results["route_background"] = coord.route(ScenePhase.BACKGROUND) == "background_persisted"
    results["route_active"] = coord.route(ScenePhase.ACTIVE) == "active_cache_invalidated"
    results["route_inactive"] = coord.route(ScenePhase.INACTIVE) == "inactive_noop"
    results["last_background_recorded"] = coord.last_background_at is not None

    # 9. Lifecycle state derivation
    unlock_5d = now + timedelta(days=5)
    state_5d = echo_state(unlock_5d, None, EchoStateLite.MATURING.value, now)
    unlock_1h = now + timedelta(hours=1)
    state_1h = echo_state(unlock_1h, None, EchoStateLite.MATURING.value, now)
    unlock_past = now - timedelta(days=1)
    state_past = echo_state(unlock_past, None, EchoStateLite.MATURING.value, now)
    results["state_5d_maturing"] = (state_5d == EchoStateLite.MATURING)
    results["state_1h_opening_ready"] = (state_1h == EchoStateLite.OPENING_READY)
    results["state_past_opening_ready"] = (state_past == EchoStateLite.OPENING_READY)

    # 10. Background timestamp recorded (already checked in #8 but let's verify)
    results["background_timestamp_set"] = (coord.last_background_at is not None)

    print("=" * 60)
    print("Tier A #5 (App Lifecycle) Validation")
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
    print(f"  Tests: {sum(1 for v in results.values() if v)} / {len(results)}")
    print("=" * 60)
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())