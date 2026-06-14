import pytest
from app.services.ai_service import RulesBasedAIService, get_ai_service


@pytest.mark.asyncio
class TestRulesBasedAIService:
    async def test_generate_cards_returns_list(self):
        service = RulesBasedAIService()
        text = (
            "Python is a high-level programming language. "
            "A list is a mutable, ordered sequence of elements. "
            "Dictionaries are key-value stores in Python. "
            "Functions are reusable blocks of code. "
            "Classes are blueprints for creating objects."
        )
        cards = await service.generate_cards(text, topic="Python", count=5)
        assert isinstance(cards, list)
        assert len(cards) <= 5
        for card in cards:
            assert card.question
            assert card.answer

    async def test_generate_cards_respects_count_limit(self):
        service = RulesBasedAIService()
        text = " ".join([
            f"Concept {i} is the definition of item {i}." for i in range(50)
        ])
        cards = await service.generate_cards(text, topic="Test", count=10)
        assert len(cards) <= 10

    async def test_evaluate_answer_perfect_match(self):
        service = RulesBasedAIService()
        score = await service.evaluate_answer(
            question="What is Python?",
            user_answer="Python is a high-level language",
            correct_answer="Python is a high-level language",
        )
        assert score == 1.0

    async def test_evaluate_answer_no_match(self):
        service = RulesBasedAIService()
        score = await service.evaluate_answer(
            question="What is Python?",
            user_answer="Java is compiled",
            correct_answer="Python is interpreted and dynamic",
        )
        assert score < 0.5

    async def test_generate_hint_short_answer(self):
        service = RulesBasedAIService()
        hint = await service.generate_hint("What is X?", "ABC")
        assert "A" in hint

    async def test_generate_hint_long_answer(self):
        service = RulesBasedAIService()
        hint = await service.generate_hint(
            "What is Python?",
            "Python is a high level interpreted programming language"
        )
        assert "Python" in hint

    def test_get_ai_service_returns_instance(self):
        service = get_ai_service()
        assert service is not None
        assert isinstance(service, RulesBasedAIService)
