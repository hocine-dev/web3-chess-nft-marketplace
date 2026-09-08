# Architecture

The application is organized as a monorepo.

## Applications

- `apps/web` — Next.js frontend
- `apps/api` — Fastify backend

## Packages

- `packages/contracts` — Solidity / Foundry
- `packages/shared` — shared TypeScript types and configuration

## Blockchain

Development:

Base Sepolia

Production target:

Base Mainnet

## Principle

The testnet architecture must remain structurally compatible with the future mainnet version.

Testnet is treated as mainnet without real economic value.