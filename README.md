# DeployZ-luau

A tiny static site host written in [Luau](https://luau.org), running on [Lune](https://github.com/lune-org/lune).
No Node, no `node_modules`: one runtime binary plus a few `.luau` files.

## Run

```sh
# install Lune once: https://github.com/lune-org/lune/releases
lune run deployz            # uses config.json
lune run deployz my.json    # custom config
PORT=3000 lune run deployz  # override port
```

Put your HTML/CSS/JS in `webroot/` and open http://localhost:8080.

## config.json

| Key | What it does |
|---|---|
| `port` | Port to listen on (default `8080`; `SERVER_PORT` or `PORT` env var overrides) |
| `host` | Address to listen on (default `0.0.0.0`) |
| `webroot` | Default folder to serve |
| `liveReload` | Browser auto-refreshes when files change |
| `domains` | `"host": "sites/folder"` serves a whole site per domain (multi-site hosting), or `"host": "page.html"` serves one page |
| `redirects` | `"old.com": "https://new.com"` → HTTP 301 |
| `blockFeature` / `blockedFiles` | Glob patterns (`*.env`, `secret/*`) return 403. CSS is never blocked |
| `logsEnabled` | Blocked requests → `logs/blocked.log` |
| `requestLogsEnabled` | All requests → `logs/requests.log` |
| `debugLogsEnabled` / `debugLogLevel` | `error`, `warn`, `info`, `debug` → `logs/debug.log` |

Other behaviour: `/about` serves `about.html` or `about/index.html`, a `404.html` in the site root is used for missing pages, and `..` path traversal is rejected.

## HTTPS

Lune serves plain HTTP. For HTTPS, put [Caddy](https://caddyserver.com) in front; it fetches real certificates automatically:

```
yourdomain.com, *.yourdomain.com {
    reverse_proxy localhost:8080
}
```

## Pterodactyl

An egg is included at [`pterodactyl/egg-deployz.json`](pterodactyl/egg-deployz.json).

1. **Import:** Admin panel → Nests → create a nest (e.g. "DeployZ") → **Import Egg** → upload `egg-deployz.json`.
2. **Create a server** with the DeployZ-luau egg. 64 MB RAM and 200 MB disk are plenty for small sites.
3. **Start it.** The installer downloads Lune and DeployZ; the server uses the port you assigned.
4. **Upload your site** with the File Manager or SFTP into `webroot/`, or into `sites/<name>/` and map a domain in `config.json`.

Egg variables: `LUNE_VERSION`, `GIT_REPO`, `GIT_BRANCH`. To update DeployZ, use **Reinstall**: it replaces the server code (`deployz.luau`, `src/`) but keeps your `config.json`, `webroot/` and `sites/`.

Tip: set `"liveReload": false` on hosted servers to save CPU.

## Layout

```
deployz.luau      entry point
src/router.luau   domains, redirects, blocking
src/static.luau   file resolving, MIME types, path safety
src/reload.luau   live reload
src/log.luau      logging
pterodactyl/      egg + install script
webroot/          default site
sites/            per-domain sites
```
