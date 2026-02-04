# Development Standards

> This document defines the common coding standards, versioning, commit conventions, and review requirements for the Pushed monorepo.

---

## Versioning

- **Semantic Versioning**: All releases follow `MAJOR.MINOR.PATCH` format
  - `MAJOR`: Breaking changes to the shared contract
  - `MINOR`: New features, backward-compatible
  - `PATCH`: Bug fixes, no API changes
  
- **Contract Version**: The shared notification payload schema includes a `schemaVersion` field
  - Both apps MUST validate incoming payloads against expected schema versions
  - Maintain backward compatibility for at least 2 minor versions

---

## Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style (formatting, not logic)
- `refactor`: Code restructure without behavior change
- `perf`: Performance improvement
- `test`: Test additions/modifications
- `chore`: Build, CI, tooling changes

**Scopes:**
- `android`: Changes to `pushed_android`
- `firebase`: Changes to `pushed_firebase`
- `watch`: Changes to `pushed_watch`
- `contract`: Changes to shared data models
- `infra`: Infrastructure/CI changes
- `agents`: AGENTS.md governance changes

**Examples:**
```bash
feat(android): add notification grouping support
fix(watch): resolve memory leak in notification list
docs(contract): update payload schema documentation
refactor(android): migrate to Kotlin Coroutines for async ops
```

---

## Branch Naming

```
<type>/<scope>-<short-description>

# Examples:
feat/android-notification-filtering
fix/watch-memory-leak
docs/contract-schema-v2
```

---

## Code Review Requirements

- All PRs require at least **1 approval** before merging
- PRs modifying the shared contract require **approval from both platform leads**
- Automated tests must pass before merge
- No direct commits to `main` branch

---

## Testing Guidelines

### Android Testing
- Use `Robolectric` for unit tests.
- Use instrumented tests for service lifecycle verification.

### watchOS Testing
- Use `Swift Testing` (@Test) for modern unit tests.
- Verify JSON decoding and View Model state changes.

---

## Security & Privacy

### Data Protection

- **Encryption**: All network traffic MUST use TLS 1.3+
- **Local Storage**: Use encrypted storage (Android EncryptedSharedPreferences, iOS Keychain)
- **Sensitive Data**: Never log full notification content in production
- **Icon Data**: Strip EXIF data, limit size to 10KB

### Permission Transparency

- Clearly explain why notification access is needed
- Provide granular control over which apps to monitor
- Allow users to pause/disable bridging at any time
- Respect "Do Not Disturb" modes on both platforms

### Data Retention

- Notifications auto-delete after 7 days
- Users can manually clear all data
- No server-side storage of notification content (direct P2P only)
