import os
import json
import urllib.request
import urllib.error
from abc import ABC, abstractmethod
from typing import Optional
from app.config import settings


class GeneratedCard:
    def __init__(self, question: str, answer: str, 
                 hint: Optional[str] = None, difficulty: int = 3):
        self.question = question
        self.answer = answer
        self.hint = hint
        self.difficulty = difficulty


class BaseAIService(ABC):
    @abstractmethod
    async def generate_cards(self, text: str, topic: str, 
                             count: int = 10) -> list[GeneratedCard]:
        pass

    @abstractmethod
    async def evaluate_answer(self, question: str, 
                              user_answer: str, correct_answer: str) -> float:
        pass

    @abstractmethod
    async def generate_hint(self, question: str, answer: str) -> str:
        pass


class GeminiAIService(BaseAIService):
    """Uses Google Gemini API to generate flashcards."""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"gemini-1.5-flash:generateContent?key={api_key}"
        )

    async def generate_cards(self, text: str, topic: str,
                             count: int = 10) -> list[GeneratedCard]:
        import asyncio

        prompt = f"""You are a flashcard generator. Given the following text about "{topic}", 
generate exactly {count} high-quality question-answer flashcard pairs.

Rules:
- Questions should test understanding, not just memory
- Answers should be clear and concise (1-3 sentences)
- Vary difficulty from easy to hard
- Return ONLY valid JSON, no markdown, no explanation

Return this exact JSON format:
[
  {{
    "question": "What is...?",
    "answer": "It is...",
    "hint": "Think about...",
    "difficulty": 3
  }}
]

Text to process:
{text[:4000]}"""

        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, self._call_api, prompt)
        return result

    def _call_api(self, prompt: str) -> list[GeneratedCard]:
        payload = json.dumps({
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 2048,
            }
        }).encode("utf-8")

        req = urllib.request.Request(
            self.url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                text = data["candidates"][0]["content"]["parts"][0]["text"]

                # Clean JSON
                text = text.strip()
                if text.startswith("```"):
                    text = text.split("```")[1]
                    if text.startswith("json"):
                        text = text[4:]
                text = text.strip()

                cards_data = json.loads(text)
                cards = []
                for c in cards_data:
                    cards.append(GeneratedCard(
                        question=c.get("question", ""),
                        answer=c.get("answer", ""),
                        hint=c.get("hint"),
                        difficulty=int(c.get("difficulty", 3)),
                    ))
                return cards
        except Exception as e:
            print(f"Gemini API error: {e}")
            return self._fallback_cards()

    def _fallback_cards(self) -> list[GeneratedCard]:
        return [GeneratedCard(
            question="What did you learn from this document?",
            answer="Review the uploaded document for key concepts.",
            difficulty=3
        )]

    async def evaluate_answer(self, question: str,
                              user_answer: str, correct_answer: str) -> float:
        user_words = set(user_answer.lower().split())
        correct_words = set(correct_answer.lower().split())
        if not correct_words:
            return 0.0
        return round(len(user_words & correct_words) / len(correct_words), 2)

    async def generate_hint(self, question: str, answer: str) -> str:
        words = answer.split()
        if len(words) <= 3:
            return f"Starts with '{answer[0]}...'"
        return f"Starts with: '{' '.join(words[:2])}...'"


class RulesBasedAIService(BaseAIService):
    """Fallback when no API key available."""

    async def generate_cards(self, text: str, topic: str,
                             count: int = 10) -> list[GeneratedCard]:
        import re
        sentences = re.split(r'(?<=[.!?])\s+', text)
        cards = []
        for sentence in sentences:
            sentence = sentence.strip()
            if len(sentence) < 30:
                continue
            pattern = r'^(.+?)\s+(?:is|are|was|were)\s+(.+)$'
            match = re.match(pattern, sentence, re.IGNORECASE)
            if match:
                subject = match.group(1).strip()
                predicate = match.group(2).strip().rstrip(".")
                if len(subject) < 100 and len(predicate) > 10:
                    cards.append(GeneratedCard(
                        question=f"What is {subject}?",
                        answer=f"{subject} is {predicate}.",
                        difficulty=3,
                    ))
            if len(cards) >= count:
                break
        return cards[:count]

    async def evaluate_answer(self, question: str,
                              user_answer: str, correct_answer: str) -> float:
        user_words = set(user_answer.lower().split())
        correct_words = set(correct_answer.lower().split())
        if not correct_words:
            return 0.0
        return round(len(user_words & correct_words) / len(correct_words), 2)

    async def generate_hint(self, question: str, answer: str) -> str:
        words = answer.split()
        if len(words) <= 3:
            return f"Starts with '{answer[0]}...'"
        return f"Starts with: '{' '.join(words[:2])}...'"


def get_ai_service() -> BaseAIService:
    """Returns Gemini if API key set, else rules-based."""
    api_key = os.environ.get("GEMINI_API_KEY") or getattr(settings, "GEMINI_API_KEY", None)
    if api_key:
        print(f"✅ Using Gemini AI service")
        return GeminiAIService(api_key=api_key)
    print("⚠️  No GEMINI_API_KEY found, using rules-based service")
    return RulesBasedAIService()
