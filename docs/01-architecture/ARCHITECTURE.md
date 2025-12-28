# Architecture

## Purpose
Define system architecture, component interactions, and design principles.

## System Overview

### Layer 1: Ingress
- Traefik reverse proxy
- SSL/TLS termination
- Request routing

### Layer 2: Orchestration
- n8n workflow engine
- ToolForge agent framework
- Claude-Flow MCP server

### Layer 3: Real-Time Services
- LiveKit media server
- Redis pub/sub
- WebSocket management

### Layer 4: State & Persistence
- Redis cache
- File-based persistence (workflows, credentials)
- Export/backup systems

### Layer 5: External Integrations
- Cloud providers (Supabase, Northflank, Fly, Koyeb)
- GitHub API
- Cloudflare DNS/CDN

## Design Principles
1. Fail-safe defaults
2. Observable operations
3. Explicit over implicit
4. Recoverable from exports
5. Portable across platforms

## Component Communication
See [docker/compose.yaml](./docker/compose.yaml) for network configuration.

## Deployment Topology
See [infra/](./infra/) for infrastructure-as-code definitions.
