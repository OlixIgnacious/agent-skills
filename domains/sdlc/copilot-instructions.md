# GitHub Copilot Instructions
<!-- Place this file at .github/copilot-instructions.md in your repository root -->

## Project Overview

This repository uses a structured SDLC workflow with four phases: requirements → architecture → implementation → review. Copilot suggestions should align with the conventions, patterns, and constraints defined below.

## Code Style and Conventions

- Follow existing patterns in the codebase — if a file uses a particular naming convention, match it.
- Prefer explicit over implicit. Name variables and functions after what they do, not how they do it.
- No placeholder implementations. If a complete implementation isn't possible, explain the gap in a comment rather than writing `// TODO: implement`.
- Tests are required. When suggesting implementation code, include the corresponding test.

## Architecture Rules

- Do not suggest changes that bypass the established layer boundaries (e.g., calling the database directly from a controller if the project uses a service layer).
- Do not introduce new dependencies without flagging them — suggest the standard in-project approach first.
- For any change touching authentication, authorization, or data storage: add a comment flagging it for security review.

## Test Conventions

- Unit tests: test one unit of behavior per test. Name tests as: `[unit] [scenario] [expected result]`.
- Integration tests: test real I/O (database, network). Never mock what you can use for real.
- Do not write tests that only assert the implementation details — test observable behavior.

## API and Interface Design

- REST endpoints: noun-based paths, HTTP verbs for actions, consistent error response shape.
- All public API changes require a deprecation path — do not make breaking changes silently.
- Document new endpoints with request/response examples inline.

## Security

- Never suggest hardcoded credentials, tokens, or secrets — use environment variables or a secrets manager.
- Validate all inputs at system boundaries. Trust nothing from external callers.
- Sanitize all outputs that reach a UI to prevent XSS.

## Database

- All schema changes go through migrations — never suggest `ALTER TABLE` outside a migration file.
- Prefer explicit column lists over `SELECT *`.
- Flag any query that could produce N+1 issues.

## Pull Request Standards

- Each PR should do one thing. Suggest splitting when a diff touches unrelated concerns.
- Commit messages: `<type>(<scope>): <what changed>` — e.g., `feat(auth): add refresh token rotation`.
- Every PR needs a test that would have caught the bug or validated the feature.

## Codebase Context

<!-- Customize per repository -->
- Stack: [language, framework, data layer, test framework]
- Architecture: [describe layer boundaries]
- Key constraints: [compliance, performance, compatibility]
