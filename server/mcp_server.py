import os
import json
import jwt
import asyncio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status
from dotenv import load_dotenv

# Cargar configuración desde .env
load_dotenv()
SECRET_KEY = os.getenv("MCP_SECRET", "default_secret_fallback")
ALGORITHM = "HS256"

app = FastAPI()

# Estado global del agente (Thread-safe Lock)
agent_state = {
    "status": "IDLE",
    "current_task": "Waiting for commands...",
}
state_lock = asyncio.Lock()

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except:
                pass

manager = ConnectionManager()

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub") == "orbit_commander"
    except:
        return False

@app.websocket("/ws/mcp")
async def mcp_endpoint(websocket: WebSocket):
    # Handshake authentication
    token = websocket.query_params.get("token")
    if not token or not verify_token(token):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await manager.connect(websocket)
    try:
        await websocket.send_text(json.dumps({"type": "STATE_UPDATE", "data": agent_state}))
        
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            async with state_lock:
                if message["type"] == "HALT_SIGNAL":
                    agent_state["status"] = "HALTED"
                    agent_state["current_task"] = "EMERGENCY STOP ACTIVATED"
                    await manager.broadcast(json.dumps({"type": "ALERT", "msg": "SISTEMA PROTEGIDO: AGENTES CONGELADOS"}))
                
                # Actualizar a todos con el nuevo estado verificado
                await manager.broadcast(json.dumps({"type": "STATE_UPDATE", "data": agent_state}))

    except WebSocketDisconnect:
        manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
