"""Tests for lib/frustration.py — bilingual emotion detection."""

import sys
import os
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from lib.frustration import detect


# ============================================================
# 3.1 — Strong trigger pattern tests
# ============================================================

class TestStrongTriggers:
    """Any single strong trigger → high."""

    # Agent-correction (EN)
    @pytest.mark.parametrize("prompt", [
        "that's not what I asked",
        "not what I meant, try again",
        "wrong file, check the other one",
        "you didn't read the spec before editing",
        "you're not listening to me",
        "I just told you this",
        "stop ignoring my instructions",
    ])
    def test_agent_correction_en(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'agent-correction' in r['triggers']
        assert r['save'] is True
        assert r['inject'] is True

    # Agent-correction (HU)
    @pytest.mark.parametrize("prompt", [
        "nem ezt kértem",
        "rossz fájlt szerkeszted",
        "miért nem olvastad el a fájlt",
        "te nem figyelsz rám",
        "pont ezt mondtam az előbb",
        "de hát mondtam hogy ne",
        "el se olvastad a specet",
        "mit csináltál megint",
    ])
    def test_agent_correction_hu(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'agent-correction' in r['triggers']

    # Expletives (EN)
    @pytest.mark.parametrize("prompt", [
        "this is fucking broken",
        "what the shit is going on",
        "wtf happened here",
        "ffs just fix it",
        "this is bullshit",
    ])
    def test_expletives_en(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'expletives' in r['triggers']

    # Expletives (HU)
    @pytest.mark.parametrize("prompt", [
        "baszd meg ezt a kódot",
        "basszus megint elrontottad",
        "a kurva életbe mi ez",
        "geci nem működik",
        "mi a faszt csináltál",
        "az istenét mi ez",
    ])
    def test_expletives_hu(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'expletives' in r['triggers']

    # Giving-up (EN)
    @pytest.mark.parametrize("prompt", [
        "I give up on this",
        "forget it, do something else",
        "never mind, I'll do it myself",
        "done with this approach",
        "this is a waste of time",
        "this is hopeless",
    ])
    def test_giving_up_en(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'giving-up' in r['triggers']

    # Giving-up (HU)
    @pytest.mark.parametrize("prompt", [
        "feladom, csináld máshogy",
        "hagyjuk az egészet",
        "nincs értelme ennek",
        "ez reménytelen",
        "felejtsd el, majd én megcsinálom",
    ])
    def test_giving_up_hu(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'high', f"Expected high for '{prompt}', got {r}"
        assert 'giving-up' in r['triggers']


# ============================================================
# 3.1 — Medium trigger pattern tests
# ============================================================

class TestMediumTriggers:
    """Medium triggers: 1 alone = mild, 2+ = moderate."""

    @pytest.mark.parametrize("prompt", [
        "still doesn't work",
        "still not working properly",
        "again it fails to compile",
        "keeps crashing on startup",
        "megint nem működik",
        "már megint elromlott",
        "újra nem megy",
    ])
    def test_repetition_negation(self, prompt):
        r = detect(prompt)
        assert r['level'] in ('mild', 'moderate', 'high'), f"Expected detection for '{prompt}', got {r}"
        assert 'repetition-negation' in r['triggers']

    @pytest.mark.parametrize("prompt", [
        "how many times do I have to say this",
        "I already told you about this",
        "this is the third time",
        "hányszor kell még mondanom",
        "már mondtam korábban",
        "ezt már csináltuk",
        "sokadjára próbálom",
    ])
    def test_temporal(self, prompt):
        r = detect(prompt)
        assert r['level'] in ('mild', 'moderate', 'high'), f"Expected detection for '{prompt}', got {r}"
        assert 'temporal' in r['triggers']

    @pytest.mark.parametrize("prompt", [
        "this never works properly",
        "always breaks after deploy",
        "completely broken module",
        "impossible to fix this",
        "soha nem működik rendesen",
        "lehetetlen megoldani",
    ])
    def test_escalation(self, prompt):
        r = detect(prompt)
        assert r['level'] in ('mild', 'moderate', 'high'), f"Expected detection for '{prompt}', got {r}"
        assert 'escalation' in r['triggers']

    def test_intensifiers_caps(self):
        r = detect("WHY is THIS not WORKING")
        assert 'intensifiers' in r['triggers']

    def test_intensifiers_punctuation(self):
        r = detect("this is broken!!")
        assert 'intensifiers' in r['triggers']


# ============================================================
# 3.1 — Neutral prompts (no detection)
# ============================================================

class TestNeutralPrompts:
    """Neutral/technical prompts → no detection."""

    @pytest.mark.parametrize("prompt", [
        "please read the config file and check the settings",
        "create a new file called config.py",
        "run the test suite",
        "add a function to parse JSON",
        "list all files in the directory",
        "what does this error message mean",
        "olvasd el a README-t",
        "hozz létre egy új fájlt",
        "/opsx:apply frustration-detection",
        "commit the changes",
    ])
    def test_neutral_prompt(self, prompt):
        r = detect(prompt)
        assert r['level'] == 'none', f"Expected none for '{prompt}', got {r}"
        assert r['save'] is False
        assert r['inject'] is False


# ============================================================
# 3.2 — Trigger logic tests
# ============================================================

class TestTriggerLogic:
    """Test the trigger combination rules."""

    def test_single_strong_is_high(self):
        r = detect("I give up")
        assert r['level'] == 'high'
        assert r['save'] is True
        assert r['inject'] is True

    def test_two_medium_is_moderate(self):
        # repetition-negation + temporal
        r = detect("megint nem működik, már mondtam")
        assert r['level'] == 'moderate', f"Expected moderate, got {r}"
        assert r['save'] is True
        assert r['inject'] is True

    def test_single_medium_is_mild(self):
        r = detect("still not working")
        assert r['level'] == 'mild'
        assert r['save'] is False
        assert r['inject'] is True

    def test_no_triggers_is_none(self):
        r = detect("please create a new file")
        assert r['level'] == 'none'
        assert r['save'] is False
        assert r['inject'] is False

    def test_session_boost_escalates_mild_to_moderate(self):
        hist = {'count': 3, 'last_level': 'mild'}
        r = detect("megint nem megy", session_history=hist)
        assert r['level'] == 'moderate', f"Expected moderate with session boost, got {r}"
        assert r['save'] is True
        assert hist['count'] == 4

    def test_session_boost_not_applied_below_threshold(self):
        hist = {'count': 2, 'last_level': 'mild'}
        r = detect("still broken", session_history=hist)
        assert r['level'] == 'mild'
        assert r['save'] is False
        assert hist['count'] == 3

    def test_fresh_session_no_boost(self):
        hist = {'count': 0, 'last_level': 'none'}
        r = detect("still not working", session_history=hist)
        assert r['level'] == 'mild'
        assert hist['count'] == 1

    def test_session_history_not_updated_on_none(self):
        hist = {'count': 2, 'last_level': 'mild'}
        r = detect("please read the file", session_history=hist)
        assert r['level'] == 'none'
        assert hist['count'] == 2  # unchanged


# ============================================================
# 3.3 — Accent tolerance tests
# ============================================================

class TestAccentTolerance:
    """Hungarian patterns match with and without accents."""

    @pytest.mark.parametrize("with_accent,without_accent", [
        ("már megint", "mar megint"),
        ("újra nem", "ujra nem"),
        ("hányszor", "hanyszor"),
        ("sokadjára", "sokadjara"),
        ("már mondtam", "mar mondtam"),
        ("már próbáltuk", "mar probaltuk"),
        ("lehetetlen", "lehetetlen"),  # no accent change
        ("képtelenség", "keptelenseg"),
        ("használhatatlan", "hasznalhatatlan"),
        ("reménytelen", "remenytelen"),
    ])
    def test_accent_equivalence(self, with_accent, without_accent):
        r_accent = detect(with_accent)
        r_no_accent = detect(without_accent)
        assert r_accent['level'] != 'none', f"Accented '{with_accent}' should be detected"
        assert r_no_accent['level'] != 'none', f"Unaccented '{without_accent}' should be detected"

    def test_mixed_accent_sentence(self):
        r = detect("mar sokadszorra rontod el megint")
        assert r['level'] != 'none', f"Mixed accent sentence should be detected, got {r}"


# ============================================================
# 3.4 — Integration test (detect result → hook actions)
# ============================================================

class TestIntegration:
    """End-to-end: detect result drives save/inject decisions."""

    def test_high_saves_and_injects(self):
        r = detect("nem ezt kértem, rossz fájlt szerkeszted!!")
        assert r['save'] is True
        assert r['inject'] is True
        assert r['level'] == 'high'

    def test_moderate_saves_and_injects(self):
        r = detect("this still doesn't work, I already tried that")
        assert r['save'] is True
        assert r['inject'] is True
        assert r['level'] == 'moderate'

    def test_mild_injects_only(self):
        r = detect("keeps failing on this test")
        assert r['save'] is False
        assert r['inject'] is True
        assert r['level'] == 'mild'

    def test_none_does_nothing(self):
        r = detect("open the file and check line 42")
        assert r['save'] is False
        assert r['inject'] is False
        assert r['level'] == 'none'

    def test_session_escalation_full_flow(self):
        """Simulate 4 prompts in a session, mild→mild→mild→moderate."""
        hist = {'count': 0, 'last_level': 'none'}

        # 3 mild prompts
        for _ in range(3):
            r = detect("still broken", session_history=hist)
            assert r['level'] == 'mild'
            assert r['save'] is False

        # 4th prompt: session boost → moderate
        r = detect("again not working", session_history=hist)
        assert r['level'] == 'moderate'
        assert r['save'] is True
        assert hist['count'] == 4

    def test_result_structure(self):
        """Verify all expected keys exist."""
        r = detect("test prompt")
        assert 'level' in r
        assert 'triggers' in r
        assert 'save' in r
        assert 'inject' in r
        assert isinstance(r['triggers'], list)
        assert isinstance(r['save'], bool)
        assert isinstance(r['inject'], bool)
