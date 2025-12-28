# Data Contracts Schemas

This directory is a reference pointer to the actual contract schemas.

**Actual Location:** [`../../../claude-flow/contracts/`](../../../claude-flow/contracts/)

## Available Schemas

See [`claude-flow/contracts/`](../../../claude-flow/contracts/) for:

- [`intent-spec.schema.json`](../../../claude-flow/contracts/intent-spec.schema.json) - Intent specification contract
- [`run-record.schema.json`](../../../claude-flow/contracts/run-record.schema.json) - Run record specification
- [`tool-spec.schema.json`](../../../claude-flow/contracts/tool-spec.schema.json) - Tool specification contract

## Why the Separation?

- `claude-flow/` contains the active Claude Code integration and contracts
- This `contracts/schemas/` directory provides a logical location for contract references
- Symlinks or references would point to the actual files in claude-flow/

## Documentation

See [Claude Flow Documentation](../../../claude-flow/) for more details.
