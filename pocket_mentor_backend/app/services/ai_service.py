"""
AI Service — abstracted interface for Q&A card generation.

Phase 1: Rules-based extraction (no LLM cost).
Phase 2: Swap in OpenAI / Anthropic / Ollama behind the same interface.
"""

import re
from abc import ABC, abstractmethod
from typing import Optional
from app.config import settings


class GeneratedCard:
    def __init__(self, question: str, answer: str, hint: Optional[str] = None, difficulty: int = 3):
        self.question = question
        self.answer = answer
        self.hint = hint
        self.difficulty = difficulty


class BaseAIService(ABC):
    @abstractmethod
    async def generate_cards(self, text: str, topic: str, count: int = 10) -> list[GeneratedCard]:
        pass

    @abstractmethod
    async def evaluate_answer(self, question: str, user_answer: str, correct_answer: str) -> float:
        """Return confidence score 0.0–1.0"""
        pass

    @abstractmethod
    async def generate_hint(self, question: str, answer: str) -> str:
        pass


class RulesBasedAIService(BaseAIService):
    """
    Phase 1: Extracts Q&A pairs from text using sentence-splitting heuristics.
    No external API calls. Free and fully offline.
    """

    async def generate_cards(self, text: str, topic: str, count: int = 10) -> list[GeneratedCard]:
        sentences = self._split_sentences(text)
        cards = []

        for i, sentence in enumerate(sentences):
            sentence = sentence.strip()
            if len(sentence) < 30:
                continue

            # Heuristic: "X is Y" / "X are Y" → question "What is X?"
            card = self._try_is_pattern(sentence)
            if card:
                cards.append(card)
                continue

            # Heuristic: definition sentences with colons
            card = self._try_colon_pattern(sentence)
            if card:
                cards.append(card)
                continue

            # Fallback: use sentence as answer, generate "What does this mean?" style Q
            if len(sentence) > 60:
                cards.append(GeneratedCard(
                    question=f"Explain the following concept from {topic}: '{sentence[:80]}...'",
                    answer=sentence,
                    difficulty=3,
                ))

            if len(cards) >= count:
                break

        return cards[:count]

    async def evaluate_answer(self, question: str, user_answer: str, correct_answer: str) -> float:
        """Simple word-overlap scoring for Phase 1."""
        user_words = set(user_answer.lower().split())
        correct_words = set(correct_answer.lower().split())
        if not correct_words:
            return 0.0
        overlap = user_words & correct_words
        return round(len(overlap) / len(correct_words), 2)

    async def generate_hint(self, question: str, answer: str) -> str:
        words = answer.split()
        if len(words) <= 3:
            return f"Starts with '{answer[0]}...'"
        first_words = " ".join(words[:2])
        return f"Starts with: '{first_words}...'"

    # ─── Helpers ───────────────────────────────────────────────────────────────

    def _split_sentences(self, text: str) -> list[str]:
        # Split on . ! ? followed by whitespace or end
        sentences = re.split(r'(?<=[.!?])\s+', text)
        return [s.strip() for s in sentences if s.strip()]

    def _try_is_pattern(self, sentence: str) -> Optional[GeneratedCard]:
        pattern = r'^(.+?)\s+(?:is|are|was|were)\s+(.+)$'
        match = re.match(pattern, sentence, re.IGNORECASE)
        if match:
            subject = match.group(1).strip()
            predicate = match.group(2).strip().rstrip(".")
            if len(subject) < 100 and len(predicate) > 10:
                return GeneratedCard(
                    question=f"What {self._conjugate_is(subject)} {subject}?",
                    answer=f"{subject} {self._get_verb(sentence)} {predicate}.",
                    difficulty=self._estimate_difficulty(sentence),
                )
        return None

    def _try_colon_pattern(self, sentence: str) -> Optional[GeneratedCard]:
        if ":" in sentence:
            parts = sentence.split(":", 1)
            if len(parts[0]) > 5 and len(parts[1]) > 10:
                return GeneratedCard(
                    question=f"What is meant by '{parts[0].strip()}'?",
                    answer=parts[1].strip(),
                    difficulty=self._estimate_difficulty(sentence),
                )
        return None

    def _conjugate_is(self, subject: str) -> str:
        plural_hints = ["they", "these", "those", "we"]
        if any(subject.lower().startswith(h) for h in plural_hints):
            return "are"
        return "is"

    def _get_verb(self, sentence: str) -> str:
        for verb in ["are", "is", "was", "were"]:
            if f" {verb} " in sentence.lower():
                return verb
        return "is"

    def _estimate_difficulty(self, sentence: str) -> int:
        word_count = len(sentence.split())
        if word_count < 15:
            return 2
        elif word_count < 30:
            return 3
        else:
            return 4


def get_ai_service() -> BaseAIService:
    """
    Factory function — returns the best available AI service.
    Phase 2: check for OPENAI_API_KEY / ANTHROPIC_API_KEY and return LLM service.
    """
    # Phase 2 placeholder:
    # if settings.OPENAI_API_KEY:
    #     return OpenAIService(api_key=settings.OPENAI_API_KEY)
    # if settings.ANTHROPIC_API_KEY:
    #     return AnthropicService(api_key=settings.ANTHROPIC_API_KEY)
    return RulesBasedAIService()
