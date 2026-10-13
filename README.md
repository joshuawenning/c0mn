# c0mn.com
> Commonplace Rails app for collecting and sharing ideas

c0mn turns URLs into a visual collection of inspiration from around the web. Save a link, add tags or notes, and c0mn organizes it into a browsable archive while preserving the original source. Instead of creating new content, you collect and connect what already matters to you.

**The URL is the raw material.**

## How It Works

1. **Capture:** Save a URL to an image, article, video, song, tool, or anything else worth returning to.
2. **Context:** Let c0mn infer its source and media type, then add tags and Markdown notes.
3. **Connect:** Search and filter a visual archive where relationships emerge across sources and subjects.

## Features

- URL-first collection
- Automatic source and media-type inference
- Tags with colored visual markers
- Markdown notes
- Masonry-style collection browsing
- Search and tag filtering
- Private administrator access

## Tech Stack

| Layer | Technology |
| --- | --- |
| Application | Ruby / Rails |
| Assets | Propshaft / Vanilla CSS |
| Data | SQLite / Solid Cache / Solid Queue / Solid Cable |
| Deployment | Docker / Kamal |
| Hosting | Hetzner Cloud / AMD64 |

## Development

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

## Administrator Setup

Run the migrations, then create a platform administrator:

```sh
OWNER_EMAIL="you@example.com" \
OWNER_USERNAME="admin" \
bin/rails owner:bootstrap
```

The task name and environment variables are retained as the deployment interface. It securely prompts for a password, which is stored only as a BCrypt digest. For non-interactive automation, provide `OWNER_PASSWORD` through a secret manager. Run the task again with a unique email and username to create another administrator. Sign in at `/login`; the admin navigation appears only while a platform administrator is signed in.

## Fonts and Performance

### Local images

Image entry URLs and accompanying image URLs are automatically downloaded by a
background job. The source URL remains unchanged. Only the first frame is kept,
converted to metadata-stripped WebP, with no upscaling:

| Copy | Maximum dimensions (aspect ratio preserved) | Hard byte cap |
| --- | --- | --- |
| Detail master | 1600 × 1600 | 500,000 |
| Collection card | 640 × 640 | 100,000 |
| Admin thumbnail | 224 × 224 | 25,000 |

Quality and dimensions are reduced until the actual output meets each cap. The
original download is discarded. Downloads are limited to 20 MiB and 30 seconds;
decoded images are limited to 40 million pixels. Only supported raster contents
are accepted. HTTPS redirects are bounded and every destination is checked and
pinned to a public IP address.

All three copies are published together. Failed replacements retain the previous
copies; obsolete files are purged through background jobs. Public previews use
local, browser-cacheable URLs. Missing imports show a placeholder. The admin detail
page shows status/errors and offers **Import image again**. Network failures and
HTTP 429/5xx responses get up to three automatic attempts.

Run `bin/rails db:prepare` after updating. To import existing image URLs:

```sh
bin/rails images:backfill
```

The task queues missing/failed imports in batches of 100 and can be rerun safely;
pending and ready imports are skipped. Run `bin/jobs` when using Solid Queue.
Development's default async adapter processes jobs in the running Rails process;
run the task with a persistent queue adapter if jobs must survive task exit. For
the existing production deployment:

```sh
bin/kamal app exec --reuse "bin/rails images:backfill"
```

Production already runs Solid Queue in Puma and stores attachments in the
`c0mn_storage` persistent volume. Back up that volume, including image files,
alongside SQLite. Retained image data is capped at 625,000 bytes per image-bearing
entry (625 MB per 1,000), excluding backups and temporary/replacement files.

Image sizes and byte caps are defined in `app/services/image_optimizer.rb`.
Source URLs that are already broken need a replacement URL; backfilling cannot
recover their contents.

Inter's variable fonts and stylesheet are fingerprinted by Propshaft for application pages.
Static error pages use the explicitly versioned `public/inter-v4.1.css` and matching
font files so they can render without Rails. When updating those fallback assets,
use new versioned filenames and update the static pages rather than overwriting
long-cached URLs. Both copies use the license in `public/fonts/Inter-LICENSE.txt`.

See [Rails performance checks](docs/rails-performance.md) for the collection-query
and Markdown-rendering baselines.

## Links

- [Live collection](https://c0mn.com/)
- [About c0mn](https://c0mn.com/about)
- [Joshua Wenning](https://joshuawenning.com/)
