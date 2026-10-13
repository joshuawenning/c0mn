# Rails performance checks

Keep collection queries bounded as the page fills, preserve search/filter URLs,
and measure Markdown work before adding caching or changing search semantics.

## Baseline — 2026-10-13

Local development: Ruby 3.4.11, Rails 8.1.3.1, SQLite, 11 entries and 7 tags.
These are local measurements, not production latency estimates.

- The warm public collection executed 6 uncached SELECTs: count, popular tags,
  page existence, entries, taggings, and tags. The repeated unfiltered count was
  served by the request query cache.
- Collection integration tests verify that association-query counts stay
  constant from 1 to 48 entries and that pagination retains search/tag filters.
- SQLite uses the collected-at index, then a temporary B-tree to finish sorting
  by created-at. Substring search scans candidates and uses the composite
  tagging index for its correlated tag lookup.

Synthetic Markdown excerpts, 48 calls after warming the helper:

| Note size | Time | Ruby objects allocated |
| --- | ---: | ---: |
| 936 bytes | 7.24 ms | 36,778 |
| 9,984 bytes | 73.95 ms | 354,149 |
| 99,996 bytes | 782.49 ms | 3,511,513 |

The sample repeats a paragraph containing emphasis, a link, and inline code.
Time and allocations include parsing, AST traversal, whitespace normalization,
and truncation. Repeat measurements after changes; don't use timing thresholds
as CI assertions.

## Verification

- Subscribe to `sql.active_record`, excluding schema and cached events, around
  a warmed collection request. Count queries separately from their duration.
- Compare a single-entry page with a full page containing shared tags.
- Use `EXPLAIN QUERY PLAN` for recent ordering and filtered search.
- Benchmark 48 excerpts from the same synthetic note sizes. Measure allocations
  using `GC.stat(:total_allocated_objects)` after `GC.start`.
- Preserve exact excerpt output for links, code, Unicode, whitespace, and
  truncation boundaries; verify cache invalidation if caching is introduced.
