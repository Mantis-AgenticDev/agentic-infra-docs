"""
---
artifact_id: "goals-recursive-test-test-context-segmenter"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_context_segmenter.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del segmentador de contexto.
"""

import pytest
from goals.libs.context_segmenter import ContextSegmenter


def test_segment_basic():
    seg = ContextSegmenter(max_segment_tokens=5)
    text = "uno dos tres cuatro cinco\n\nseis siete ocho nueve diez\n\nonce doce"
    segments = seg.segment(text)
    assert len(segments) >= 1
    for s in segments:
        assert "content" in s
        assert "token_estimate" in s


def test_segment_small_text():
    seg = ContextSegmenter(max_segment_tokens=1000)
    text = "texto corto"
    segments = seg.segment(text)
    assert len(segments) == 1


def test_extract_relevant():
    seg = ContextSegmenter(max_segment_tokens=10)
    text = "gato perro ratón\n\ngato elefante\n\nperro jirafa"
    segments = seg.segment(text)
    relevant = seg.extract_relevant(segments, ["gato"])
    assert len(relevant) >= 1
    for r in relevant:
        assert "gato" in r["content"].lower()


def test_extract_relevant_no_match():
    seg = ContextSegmenter()
    text = "manzana naranja\n\npera uva"
    segments = seg.segment(text)
    relevant = seg.extract_relevant(segments, ["sandía"])
    assert relevant == []


def test_empty_input():
    seg = ContextSegmenter()
    segments = seg.segment("")
    assert segments == []
