# Backend Services

A modular, high-performance server architecture designed for a real-time Web3 racing game. Composed of four dedicated, loosely coupled services—each optimized for its specific role and scalable independently.

## 🛡️ FightServer  
Handles low-latency, deterministic combat and race-state synchronization:  
- Real-time kart collision, boost interactions, and item-based effects (e.g., missiles, shields)  
- Frame-accurate physics reconciliation using lockstep + snapshot interpolation  
- Anti-cheat validation for movement inputs and action timing  
- Connects directly to GameServer via gRPC for authoritative state updates  

## 🎮 GameServer  
The core game logic and world management service:  
- Manages persistent player profiles, NFT kart inventories, and progression data  
- Orchestrates matchmaking, session lifecycle, and track/season state  
- Integrates with on-chain oracles for NFT ownership verification and reward minting  
- Exposes WebSocket endpoints for real-time client communication  

## 🌐 HttpServer  
RESTful gateway and frontend-facing API layer:  
- Serves static assets, auth flows (wallet connect, email login), and metadata (leaderboards, events)  
- Handles webhook ingestion (e.g., blockchain confirmations, payment receipts)  
- Caches & aggregates data from GameServer and external chains for fast reads  

## 🤖 TelegramBot  
Official in-app bot for community engagement and utility:  
- Notifies users about race results, rewards, and tournament deadlines  
- Enables quick actions: view kart stats, claim tokens, join lobbies via inline buttons  
- Supports wallet linking, balance checks, and $TOKEN faucet (for devs/testers)  

## ✅ Design Principles  
- **Resilient**: Each service runs in isolation; failure in one does not crash others  
- **Extensible**: Clear interfaces (gRPC/REST/WebSocket) enable easy plugin or chain integration  
- **Web3-Ready**: Built-in support for EVM-compatible chains, signature verification, and event indexing  

All services are containerized (Docker), observability-enabled (Prometheus + Grafana), and deployed via Kubernetes.