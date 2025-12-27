# samwise

## Purpose
Self-governing AI agent system with integrated workflow orchestration, real-time communication, and distributed deployment capabilities.

## Non-Negotiable Constraints
- All services run in Docker containers
- All ports must be documented in PORTS_AND_LIMITS.md
- All credentials stored in .env files (never committed)
- All decisions logged in DECISIONS.md
- Recovery procedures must exist before production deployment

## Core Components
- **n8n**: Workflow orchestration and ToolForge integration
- **LiveKit**: Real-time audio/video/data streaming
- **Redis**: Message queue and state cache
- **Traefik**: Reverse proxy and SSL termination
- **Claude Code**: AI agent coordination via MCP

## Quick Start
See individual component README files for setup instructions.

## Architecture
See [ARCHITECTURE.md](./ARCHITECTURE.md) for system design.

## Operations
See [OPERATING_RULES.md](./OPERATING_RULES.md) for operational procedures.
