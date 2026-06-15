import os
import json
import httpx
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

    def to_dict(self):
        return {
            "question": self.question,
            "answer": self.answer,
            "hint": self.hint,
            "difficulty": self.difficulty
        }


class BaseAIService(ABC):
    @abstractmethod
    async def generate_cards(self, text: str, topic: str, count: int = 10) -> list[GeneratedCard]:
        pass

    @abstractmethod
    async def evaluate_answer(self, question: str, user_answer: str, correct_answer: str) -> float:
        pass

    @abstractmethod
    async def generate_hint(self, question: str, answer: str) -> str:
        pass


class GeminiAIService(BaseAIService):
    """Uses Google Gemini API to generate flashcards and evaluate metrics asynchronously."""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.url = f"[https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=](https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=){api_key}"

    async def generate_cards(self, text: str, topic: str, count: int = 10) -> list[GeneratedCard]:
        prompt = f"""You are an advanced flashcard generator. Given the provided text about "{topic}", 
generate exactly {count} high-quality question-answer flashcard pairs.

Rules:
- Questions must test deep understanding of the concepts, not just raw memory.
- Answers must be clear, accurate, and concise (1-3 sentences).
- Vary the difficulty level dynamically from 1 (easiest) to 5 (hardest).
- Your entire response MUST comply with the requested JSON schema.

Text to process:
{text[:4000]}"""

        # Enforce JSON output format natively via Gemini Config
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.3,  # Lower temperature for deterministic structural schemas
                "responseMimeType": "application/json",
                "responseSchema": {
                    "type": "ARRAY",
                    "items": {
                        "type": "OBJECT",
                        "properties": {
                            "question": {"type": "STRING"},
                            "answer": {"type": "STRING"},
                            "hint": {"type": "STRING"},
                            "difficulty": {"type": "INTEGER"}
                        },
                        "required": ["question", "answer", "difficulty"]
                    }
                }
            }
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(self.url, json=payload)
                response.raise_for_status()
                data = response.json()
                
                raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
                cards_data = json.loads(raw_text)
                
                return [
                    GeneratedCard(
                        question=c.get("question", ""),
                        answer=c.get("answer", ""),
                        hint=c.get("hint"),
                        difficulty=int(c.get("difficulty", 3))
                    ) for c in cards_data
                ]
        except Exception as e:
            print(f"❌ Gemini API Error in generate_cards: {e}")
            return self._fallback_cards()

    def _fallback_cards(self) -> list[GeneratedCard]:
        return [GeneratedCard(
            question="What did you learn from this document?",
            answer="Review the uploaded document for key concepts.",
            difficulty=3
        )]

    async def evaluate_answer(self, question: str, user_answer: str, correct_answer: str) -> float:
        """Uses LLM semantic matching rather than raw word counts to evaluate user accuracy."""
        prompt = f"""Evaluate the accuracy of the user's answer compared to the correct reference answer for the given question.
Return a score between 0.0 (completely wrong) and 1.0 (completely correct) as a JSON object containing a singular float key 'score'.

Question: "{question}"
Correct Reference Answer: "{correct_answer}"
User's Answer: "{user_answer}"
"""
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.0,
                "responseMimeType": "application/json",
                "responseSchema": {
                    "type": "OBJECT",
                    "properties": {
                        "score": {"type": "NUMBER"}
                    },
                    "required": ["score"]
                }
            }
        }

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(self.url, json=payload)
                response.raise_for_status()
                data = response.json()
                res_text = data["candidates"][0]["content"]["parts"][0]["text"]
                return float(json.loads(res_text).get("score", 0.0))
        except Exception as e:
            print(f"⚠️ AI evaluation failed ({e}). Falling back to word intersection logic.")
            # Fallback to local string handling if API times out
            user_words = set(user_answer.lower().split())
            correct_words = set(correct_answer.lower().split())
            if not correct_words: return 0.0
            return round(len(user_words & correct_words) / len(correct_words), 2)

    async def generate_hint(self, question: str, answer: str) -> str:
        """Generates contextual hints instead of plain string truncation."""
        prompt = f"""Provide a short, subtle, helpful hint for a user trying to answer this question. 
Do not reveal the actual answer.

Question: "{question}"
Answer: "{answer}"
"""
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.5, "maxOutputTokens": 60}
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(self.url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data["candidates"][0]["content"]["parts"][0]["text"].strip()
        except Exception:
            words = answer.split()
            return f"Starts with: '{' '.join(words[:2])}...'"


class RulesBasedAIService(BaseAIService):
    """Local text parsing fallback when no API key is initialized."""

    async def generate_cards(self, text: str, topic: str, count: int = 10) -> list[GeneratedCard]:
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

    async def evaluate_answer(self, question: str, user_answer: str, correct_answer: str) -> float:
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
    """Instantiates the correct service context."""
    api_key = os.environ.get("GEMINI_API_KEY") or getattr(settings, "GEMINI_API_KEY", None)
    if api_key:
        print(f"✅ Using Gemini Asynchronous AI service")
        return GeminiAIService(api_key=api_key)
    print("⚠️ No GEMINI_API_KEY found, fallback to rules-based processing")
    return RulesBasedAIService()
