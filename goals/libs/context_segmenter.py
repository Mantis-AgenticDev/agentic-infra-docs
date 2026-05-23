---
artifact_id: "goals-libs-context-segmenter"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/context_segmenter.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:context-segmenter-v2.0.0"
generated_at: "2026-05-22T06:30:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Divide el contexto histórico en segmentos indexados para evitar la pérdida de contexto.
"""

import json
from typing import List, Dict, Optional

class ContextSegmenter:
    def __init__(self, max_segment_tokens: int = 2000):
        self.max_segment_tokens = max_segment_tokens

    def segment(self, full_context: str) -> List[Dict[str, str]]:
        """Divide el texto en segmentos con metadatos para indexación."""
        # Simplificación: segmentación por párrafos (en producción usar tokenización real)
        paragraphs = [p.strip() for p in full_context.split("\n\n") if p.strip()]
        segments = []
        current_chunk = ""
        token_estimate = 0
        for p in paragraphs:
            p_tokens = len(p.split())
            if token_estimate + p_tokens > self.max_segment_tokens and current_chunk:
                segments.append({"content": current_chunk.strip(), "token_estimate": token_estimate})
                current_chunk = p
                token_estimate = p_tokens
            else:
                current_chunk += "\n\n" + p if current_chunk else p
                token_estimate += p_tokens
        if current_chunk:
            segments.append({"content": current_chunk.strip(), "token_estimate": token_estimate})
        return segments

    def extract_relevant(self, segments: List[Dict], keywords: List[str]) -> List[Dict]:
        """Devuelve solo los segmentos que contengan alguna de las palabras clave."""
        relevant = []
        for seg in segments:
            content_lower = seg["content"].lower()
            if any(kw.lower() in content_lower for kw in keywords):
                relevant.append(seg)
        return relevant



