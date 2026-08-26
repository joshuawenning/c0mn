# c0mn.com
> Encounter something meaningful. Then, save it.

c0mn is a *commonplace* Rails app for collecting and sharing ideas, without requiring content creation.

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
- Private owner administration

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

## Owner Setup

Run the migrations, then create the initial owner once:

```sh
OWNER_EMAIL="you@example.com" \
OWNER_USERNAME="admin" \
bin/rails owner:bootstrap
```

The task securely prompts for a password, which is stored only as a BCrypt digest. For non-interactive automation, provide `OWNER_PASSWORD` through a secret manager. Sign in at `/login`; the admin navigation appears only while the platform owner is signed in.

## Links

- [Live collection](https://c0mn.com/)
- [About c0mn](https://c0mn.com/about)
- [Joshua Wenning](https://joshuawenning.com/)
