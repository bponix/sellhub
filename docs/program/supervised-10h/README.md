# SellHub 10-Hour Supervised Production Program

This directory is the master coordination workspace for a long-running
SellHub reseller-platform delivery program.

Goals:
- keep the program resumable across interrupted sessions
- separate exploration, implementation, verification, and review
- preserve fixed ownership boundaries for parallel agents
- enforce test gates before consolidation

Operating rules:
- the master thread owns priorities, integration, and review decisions
- each agent owns one bounded scope at a time
- each agent writes findings and completion notes into its handoff file
- all cross-scope assumptions must be documented before merge
- every checkpoint updates `review-log.md` and `resume-point.md`

Primary deliverables:
- local-first development architecture using SQLite + LocalGraphQLApi
- Bangladesh-first reseller workflows with global-ready structure
- compact, direct, operator-friendly UI/UX
- resume-safe implementation and verification trail

Backlog files:
- `future-mvp-backlog.md` tracks remaining MVP-critical work that future heartbeats and supervised waves should pick up
