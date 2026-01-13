from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import json
import asyncio

app = FastAPI()

# Estado global del agente (Simulado para PoC Fase 2)
agent_state = {
    "status": "IDLE",
    "current_task": "Waiting for commands...",
    "pending_approvals": []
}

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async city_connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.get("/")
async def get():
    return {"status": "Orbit MCP Server Operational"}

@app.websocket("/ws/mcp")
async def mcp_endpoint(websocket: WebSocket):
    await manager.city_connect(websocket)
    try:
        # Enviar estado inicial
        await websocket.send_text(json.dumps({"type": "STATE_UPDATE", "data": agent_state}))
        
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Procesar comandos del Protocolo de Contexto de Modelo
            if message["type"] == "HALT_SIGNAL":
                agent_state["status"] = "HALTED"
                agent_state["current_task"] = "EMERGENCY STOP ACTIVATED"
                await manager.broadcast(json.dumps({"type": "ALERT", "msg": "SISTEMA CONGELADO POR SEÑAL DE PÁNICO"}))
            
            elif message["type"] == "APPROVE_CMD":
                cmd_id = message["cmd_id"]
                # Lógica para marcar comando como aprobado...
                await manager.broadcast(json.dumps({"type": "LOG", "msg": f"Comando {cmd_id} aprobado por el humano."}))

            # Broadcast del nuevo estado
            await manager.broadcast(json.dumps({"type": "STATE_UPDATE", "data": agent_state}))

    except WebSocketDisconnect:
        manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
