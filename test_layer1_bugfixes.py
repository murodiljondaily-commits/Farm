"""Unit tests for the Phase 6 / Layer 1 data-integrity fixes in tools.py and
firestore_db.py. Hermetic — mocks firestore_db so no real Firestore
credentials are needed to run this.

Run: python3 test_layer1_bugfixes.py
"""
import asyncio
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

import tools


class CloseCaseOutcomeStatusTest(unittest.TestCase):
    """close_case must set the animal's status based on the actual outcome,
    not unconditionally mark it healthy (the bug: every close_case call set
    status='sog'lom' even when outcome='oldi'/died)."""

    def _run_close_case(self, outcome: str) -> str:
        """Calls tools.close_case with the given outcome, mocking every
        firestore_db call it touches, and returns the `status` value that
        update_animal was called with."""
        fake_case = {
            "case_id": "c1", "ear_tag": "e001", "opened_at": None,
            "ai_diagnosis": "test", "species": "sigir",
        }
        with patch.object(tools.firestore_db, "get_case", AsyncMock(return_value=fake_case)), \
             patch.object(tools.firestore_db, "update_case", AsyncMock()), \
             patch.object(tools.firestore_db, "update_animal", AsyncMock()) as mock_update_animal, \
             patch.object(tools.firestore_db, "create_event", AsyncMock(return_value="ev1")), \
             patch.object(tools.firestore_db, "find_rag_patterns_by_diagnosis", AsyncMock(return_value=[])):
            asyncio.run(tools.close_case("farm1", "c1", outcome=outcome))
            self.assertTrue(mock_update_animal.called, "update_animal was never called")
            _, kwargs_or_args = mock_update_animal.call_args, None
            call = mock_update_animal.call_args
            # update_animal(farm_id, ear_tag, {"status": ...})
            data = call.args[2] if len(call.args) >= 3 else call.kwargs.get("data")
            return data["status"]

    def test_died_sets_animal_status_oldi_not_healthy(self):
        status = self._run_close_case("oldi")
        self.assertEqual(status, "oldi", "died outcome must NOT resurrect the animal to 'sog'lom'")

    def test_died_with_apostrophe_spelling_also_works(self):
        # agent.py's AI tool schema (ALL_TOOLS) uses "o'ldi" (with apostrophe)
        # while the Flutter close-case sheet sends 'oldi' (no apostrophe) for
        # the same outcome — both callers must land on the same animal status.
        status = self._run_close_case("o'ldi")
        self.assertEqual(status, "oldi")

    def test_worsened_sets_animal_status_kritik(self):
        status = self._run_close_case("yomonlashdi")
        self.assertEqual(status, "kritik")

    def test_healed_sets_animal_status_soglom(self):
        status = self._run_close_case("tuzaldi")
        self.assertEqual(status, "sog'lom")

    def test_transferred_elsewhere_sets_animal_status_sotildi(self):
        status = self._run_close_case("boshqa joyga yuborildi")
        self.assertEqual(status, "sotildi")

    def test_unknown_outcome_falls_back_to_soglom(self):
        # Best-effort fallback, not a raise — matches previous behavior for
        # any outcome string not in the known 3.
        status = self._run_close_case("something_unexpected")
        self.assertEqual(status, "sog'lom")


class CreateCaseAtomicTest(unittest.TestCase):
    """create_case_atomic must batch all writes into ONE Firestore commit."""

    def test_batches_case_animal_and_event_writes_together(self):
        import firestore_db

        mock_batch = MagicMock()
        mock_db = MagicMock()
        mock_db.batch.return_value = mock_batch

        with patch.object(firestore_db, "get_db", return_value=mock_db):
            case_id, event_id = asyncio.run(firestore_db.create_case_atomic(
                "farm1",
                case_data={"ear_tag": "e001", "severity": "high"},
                event_data={"event_type": "photo_diagnosis"},
                animal_ear_tag="e001",
                animal_status="kritik",
            ))

        self.assertTrue(case_id)
        self.assertTrue(event_id)
        # 3 writes staged (case + animal + event)...
        self.assertEqual(mock_batch.set.call_count, 3)
        # ...and exactly one commit — the whole point of batching.
        mock_batch.commit.assert_called_once()

    def test_skips_animal_write_when_no_status_change(self):
        import firestore_db

        mock_batch = MagicMock()
        mock_db = MagicMock()
        mock_db.batch.return_value = mock_batch

        with patch.object(firestore_db, "get_db", return_value=mock_db):
            asyncio.run(firestore_db.create_case_atomic(
                "farm1",
                case_data={"ear_tag": None, "severity": "low"},
                event_data={"event_type": "photo_diagnosis"},
                animal_ear_tag=None,
                animal_status=None,
            ))

        # Only case + event staged — no animal write when unassigned/low severity.
        self.assertEqual(mock_batch.set.call_count, 2)
        mock_batch.commit.assert_called_once()


if __name__ == "__main__":
    unittest.main(verbosity=2)
