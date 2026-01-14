import os
from typing import Dict, Any, Optional
from enum import Enum
from pydantic import BaseModel, ValidationError
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, Query, status
from fastapi.security import APIKeyHeader
import jwt
import asyncio
import logging
from dotenv import load_dotenv
from services.ai_service import ai_brain

# --- CONFIGURATION & LOGGING ---
load_dotenv()
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("Orbit.MCPServer")

class Settings:
    SECRET_KEY: str = os.getenv("MCP_SECRET", "changeme_in_prod_critical_warning")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

settings = Settings()

if settings.SECRET_KEY == "changeme_in_prod_critical_warning":
    logger.warning("⚠️  RUNNING WITH DEFAULT INSECURE SECRET KEY. SET 'MCP_SECRET' IN ENV.")

# --- DOMAIN MODELS (DDD) ---
class AgentStatus(str, Enum):
    IDLE = "IDLE"
    BUSY = "BUSY"
    HALTED = "HALTED"
    OFFLINE = "OFFLINE"

class AgentState(BaseModel):
    status: AgentStatus = AgentStatus.IDLE
    current_task: str = "System Ready"
    metadata: Dict[str, Any] = {}

class WebSocketMessage(BaseModel):
    type: str
    payload: Optional[Dict[str, Any]] = None

# --- STATE MANAGEMENT (Repositories) ---
class StateManager:
    """Thread-safe State Manager. Ready for Redis implementation."""
    def __init__(self):
        self._state = AgentState()
        self._lock = asyncio.Lock()

    async def update(self, **kwargs) -> AgentState:
        async with self._lock:
            current_data = self._state.dict()
            current_data.update(kwargs)
            self._state = AgentState(**current_data)
            return self._state

    async def get_snapshot(self) -> AgentState:
        async with self._lock:
            return self._state

# Singleton Instance (Check 'Dependency Injection' below for scalability)
state_manager = StateManager() 

# --- AUTHENTICATION LAYER ---
async def verify_jwt(token: str = Query(..., alias="token")) -> Dict[str, Any]:
    """Validates JWT with expiration and signature check."""
    try:
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM],
            options={"require": ["exp", "sub"]}
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception("Token expired")
    except jwt.PyJWTError as e:
        logger.warning(f"Auth failed: {e}")
        raise Exception("Invalid credentials")

# --- CONNECTION MANAGER ---
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"Client connected. Total: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast_state(self, state: AgentState):
        json_data = {"type": "STATE_UPDATE", "data": state.dict()}
        # Optimization: Use asyncio.gather for parallel send
        if self.active_connections:
            await asyncio.gather(
                *[c.send_json(json_data) for c in self.active_connections],
                return_exceptions=True
            )

manager = ConnectionManager()
app = FastAPI()

# --- ENDPOINTS ---
@app.websocket("/ws/mcp")
async def websocket_endpoint(
    websocket: WebSocket, 
    # Dependencia inyectada para validación automática antes de aceptar socket
    user: Dict = Depends(verify_jwt) 
):
    try:
        await manager.connect(websocket)
        logger.info(f"Accepted connection from user: {user.get('sub')}")
        
        # Send initial state
        current_state = await state_manager.get_snapshot()
        await websocket.send_json({"type": "INIT", "data": current_state.dict()})

        while True:
            data = await websocket.receive_json()
            try:
                message = WebSocketMessage(**data) # Validate input schema
                
                if message.type == "HALT_SIGNAL":
                    logger.critical("🚨 EMERGENCY HALT SIGNAL RECEIVED")
                    new_state = await state_manager.update(
                        status=AgentStatus.HALTED,
                        current_task="🚨 EMERGENCY HALT EXECUTED"
                    )
                    await manager.broadcast_state(new_state)
                    # Implement logic to kill subprocesses here

                elif message.type == "AI_PROMPT":
                    # Non-blocking AI processing (in real implementation, use threadpool)
                    user_text = message.payload.get("text", "")
                    logger.info(f"🧠 Thinking about: {user_text}")
                    
                    # Notify we are busy thinking
                    await state_manager.update(status=AgentStatus.BUSY, current_task="Procesando consulta IA...")
                    await manager.broadcast_state(state_manager._state)

                    # Simpler for POC: Await directly (blocks event loop briefly, optimize later)
                    response_text = ai_brain.process_prompt(user_text)
                    
                    await websocket.send_json({
                        "type": "AI_RESPONSE", 
                        "data": {"text": response_text}
                    })

                    # Back to IDLE
                    await state_manager.update(status=AgentStatus.IDLE, current_task="Esperando comandos...")
                    await manager.broadcast_state(state_manager._state)

                    
            except ValidationError as e:
                await websocket.send_json({"type": "ERROR", "msg": "Invalid Schema", "details": e.errors()})

    except WebSocketDisconnect:
        logger.info("Client disconnected")
        manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"Critical WS Error: {e}")
        # If connection is already accepted, we might need strict closing
        try:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        except:
            pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
