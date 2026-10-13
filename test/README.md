# Test the contract, not the design

This suite protects application behavior while leaving the UI free to evolve.

## Keep coverage for

- Authentication, authorization, password reset tokens, and session revocation.
- Validation, saved data, transaction rollback, shared tags, and concurrency.
- Search, filtering, pagination destinations, and stable ordering.
- Safe URLs, sanitized Markdown, and security headers.
- Bounded query work, batch caching, and cache invalidation.
- Accessible navigation and error feedback: active state, focusable skip-link
  targets, invalid fields, and references to existing error descriptions.
- A few browser journeys that check navigation and persisted results.

## Let presentation change

Don't assert fonts, colors, CSS classes, component counts, element nesting,
stylesheet splitting, branding, headings, flash wording, or email subject copy.
One generic asset smoke test checks that linked local stylesheets are served;
production asset compilation is checked in CI.

Prefer link destinations, form actions, submitted field names, accessible roles,
and control labels over styling selectors. Browser control labels may need an
update when the interaction is deliberately renamed, but layout and CSS changes
should not require test changes.

Exact output is appropriate for text-processing behavior such as Markdown
excerpts, and seeded record values are useful for checking data. Compare public
responses to each other when testing non-enumeration rather than hard-coding
their wording. Assert validation fields or error types, not full sentences.

Do not test configuration by searching Ruby source strings. Exercise evaluated
behavior when it matters. Add regression tests for meaningful failures, not
every visual edit or reversible styling change.

Run `bin/rails test`, `bin/rails test:system`, and `bin/rubocop` for suite changes.
