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

## Links

- [Live collection](https://c0mn.com/)
- [About c0mn](https://c0mn.com/about)
- [Joshua Wenning](https://joshuawenning.com/)
