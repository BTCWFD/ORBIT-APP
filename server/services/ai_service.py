import os
import logging
from typing import Optional
from openai import OpenAI

logger = logging.getLogger("Orbit.AIService")

class AIService:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.client: Optional[OpenAI] = None
        self.model = "gpt-4o-mini" # Fast, cheap, smart enough for Agent Control in V1

        if self.api_key:
            try:
                self.client = OpenAI(api_key=self.api_key)
                logger.info("🧠 AI Brain initialized (OpenAI)")
            except Exception as e:
                logger.error(f"Failed to init AI Client: {e}")
        else:
            logger.warning("⚠️ OPENAI_API_KEY not found. AI features will be disabled.")

    def process_prompt(self, prompt: str) -> str:
        if not self.client:
            return "❌ AI OFF: Configura OPENAI_API_KEY en el servidor."

        try:
            # System Prompt that defines the Persona
            system_msg = (
                "Eres ORBIT, la IA central de una plataforma de desarrollo cloud. "
                "Tu misión es asistir al desarrollador. Eres conciso, técnico y algo cínico (estilo sci-fi). "
                "Si te piden ayuda técnica, dalo. Si te piden ejecutar comandos, di que aún no tienes manos (V2)."
            )

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_msg},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=150
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"AI Error: {e}")
            return f"❌ Error Cerebral: {str(e)}"

# Singleton
ai_brain = AIService()
