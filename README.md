# c0mn.com
> Encounter something meaningful. Then, save it.

c0mn is a *commonplace* Rails app for collecting and sharing ideas, without requiring content creation.

c0mn turns URLs into a visual collection of inspiration from around the web. Save a link, add tags or notes, and c0mn organizes it into a browsable archive while preserving the original source. Instead of creating new content, you collect and connect what already matters to you.

## Owner Setup
Run the migrations, then create the initial owner once:

```sh
OWNER_EMAIL="you@example.com" \
OWNER_USERNAME="josh" \
bin/rails owner:bootstrap
```

The task securely prompts for a password, which is stored only as a BCrypt digest. For non-interactive automation, provide `OWNER_PASSWORD` through a secret manager. Sign in at `/login`; the admin navigation appears only while the platform owner is signed in.
