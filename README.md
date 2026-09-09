# Memo for YunoHost

[![Install Memo with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=memo)

*[Lire ce readme en français.](./README_fr.md)*

> *This package lets you install Memo quickly and simply on a YunoHost server.
> If you don't have YunoHost, please consult [the guide](https://yunohost.org/install) to learn how to install it.*

## Overview

Memo is a board of sticky notes that several people write on at once. Drag a
note, type in it, watch it move on everyone else's screen. It was built after
scrumblr, and it keeps every board in a single SQLite file, so there is no
database server to run alongside it.

A board holds two things. Notes, which are the usual coloured squares, and
wikicards, two-sided cards built from a wiki page: a question on the front, an
answer on the back. Columns can be renamed, reordered and resized, cards can be
filtered, and the whole board pans and zooms like a map.

**Shipped version:** 0.9.0~ynh1

## What this package does

- Runs memo under systemd as its own user, behind nginx, on a port picked by YunoHost
- Puts every board in `/home/yunohost.app/memo/memo.sqlite`, kept out of the install directory so an upgrade never goes near it and a removal without `--purge` leaves it alone
- Wires memo to the YunoHost portal, so people arrive already signed in under their YunoHost name and never see a second login form
- Hands memo's admin page to the account you name at install time
- Installs at the root of a domain or in a subdirectory, and moves between the two with `yunohost app changeurl`

Read [the admin documentation](./doc/ADMIN.md) for where the files live, how the
single sign-on is wired, and what to check when it isn't working.

## Packaging notes

memo runs on [Bun](https://bun.sh), which Debian does not package and YunoHost
has no resource for, the way it has `ynh_nodejs_install` for Node. So bun is
fetched like any other asset. The manifest declares the release zip as a second
source with a checksum per architecture, and the install script unpacks it into
`$install_dir/bin/bun`:

```toml
[resources.sources.bun]
amd64.url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.2/bun-linux-x64-baseline.zip"
amd64.sha256 = "..."
arm64.url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.2/bun-linux-aarch64.zip"
arm64.sha256 = "..."
```

Two consequences worth knowing about. The package works on x86-64 and aarch64
only, because those are the only Linux builds bun publishes. And nothing
updates that runtime for you: YunoHost's autoupdate bot follows the app's own
sources, not the interpreter underneath. `dev/update-bun.sh` re-pins both
architectures from the GitHub API, and `dev/update-source.sh` re-pins memo
itself.

The amd64 asset is the *baseline* build on purpose. The regular one needs AVX2,
which means a CPU from 2013 or later, and on an older box it dies with a
signal and no explanation.

The source is pinned to the `v0.9.0` tag, and `autoupdate.strategy` is
`latest_forgejo_tag`, so the bot follows new tags on Codeberg. Pinning a tag
rather than a branch is what makes the checksum hold: Codeberg serves the same
bytes for a tag archive every time, while a branch archive changes under it.

## Documentation and resources

- Upstream app code repository: <https://codeberg.org/mrflos/memo>
- YunoHost documentation for this app: <https://codeberg.org/mrflos/memo#readme>

## Developer info

To try the testing branch:

```bash
sudo yunohost app install https://github.com/YunoHost-Apps/memo_ynh/tree/testing --debug
# or
sudo yunohost app upgrade memo -u https://github.com/YunoHost-Apps/memo_ynh/tree/testing --debug
```

**More info regarding app packaging:** <https://yunohost.org/packaging_apps>
