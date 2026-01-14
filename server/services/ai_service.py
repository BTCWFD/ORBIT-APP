import os
import logging
from typing import Optional, AsyncGenerator
from openai import AsyncOpenAI

logger = logging.getLogger("Orbit.AIService")

class AsyncAIService:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.client: Optional[AsyncOpenAI] = None
        self.model = "gpt-4-turbo-preview" # Upgraded to Turbo for better reasoning/speed balance

        if self.api_key:
            try:
                self.client = AsyncOpenAI(api_key=self.api_key)
                logger.info("🧠 AI Brain initialized (Async OpenAI)")
            except Exception as e:
                logger.error(f"Failed to init AI Client: {e}")
        else:
            logger.warning("⚠️ OPENAI_API_KEY not found. AI features will be disabled.")

    async def process_prompt_stream(self, prompt: str) -> AsyncGenerator[str, None]:
        """
        Generates a stream of tokens from OpenAI.
        Non-blocking.
        """
        if not self.client:
            yield "❌ AI OFF: Configura OPENAI_API_KEY en el servidor."
            return

        try:
            # System Prompt that defines the Persona
            system_msg = (
                "Eres ORBIT, la IA central de una plataforma de desarrollo cloud. "
                "Tu misión es asistir al desarrollador. Eres conciso, técnico y algo cínico (estilo sci-fi). "
                "Si te piden ayuda técnica, dalo. Si te piden ejecutar comandos, di que aún no tienes manos (V2)."
            )

            stream = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_msg},
                    {"role": "user", "content": prompt}
                ],
                stream=True,
                max_tokens=300
            )

            async for chunk in stream:
                content = chunk.choices[0].delta.content
                if content:
                    yield content

        except Exception as e:
            logger.error(f"AI Stream Error: {e}")
            yield f"❌ Error Cerebral: {str(e)}"

# Singleton Instance
ai_brain = AsyncAIService()
