## Where things are

| What | Where |
| --- | --- |
| The memo binary, with every page and font packed inside it | `/var/www/memo/memo` |
| Every board, in one SQLite file | `/home/yunohost.app/memo/memo.sqlite` |
| Snapshots taken from memo's admin page | `/home/yunohost.app/memo/backups` |
| Configuration | `/var/www/memo/.env` |
| Log | `/var/log/memo/memo.log` |

Removing the app leaves the boards behind. `yunohost app remove memo --purge`
is what deletes them.

## Accounts

Anyone the permission lets in arrives already signed in, under their YunoHost
name. memo mints no session of its own here, so signing out of the portal signs
you out of memo too, and there is no second password to manage.

It works the other way round too. memo's own "Sign out" goes through the
portal's logout, so it ends the YunoHost session and not just memo's idea of
one. You land back on the page you left and the SSO asks you to sign in again.
The "Sign in" link is the mirror of it, and only appears once you open the
permission to visitors.

Both addresses are `PROXY_LOGIN_URL` and `PROXY_LOGOUT_URL` in
`/var/www/memo/.env`, rewritten on every upgrade and whenever you move the app
with `yunohost app change-url`. Empty either one and memo stops showing that
link, which is the honest thing to do with a button that would sign nobody out.
Up to 0.9.1~ynh1 these two redirects lived in the app's nginx config. memo does
it itself now, so an old customisation there has nothing left to override.

Opening a board and writing on it never needs an account. Making one does,
unless the config panel says otherwise, which is a question only an install
opened to visitors ever has to answer.

The account you chose at install time got memo's admin page, at
`https://your.domain/memo/admin`, which lists, searches and deletes boards,
manages accounts, and takes a snapshot of the database. That grant happens
once, while memo has no admin at all. Changing the setting afterwards does
nothing. To add or remove an admin later, do it from that page.

YunoHost group membership is not forwarded, so memo's `ADMIN_GROUP` and its
group-based board sharing have nothing to read. Share a private board with
people by name.

## Configuration

Four settings have a config panel: the default interface language, a logo and a
favicon URL to replace memo's own, and whether a visitor with no account may
create a board. Everything else lives in `/var/www/memo/.env`, one `KEY=value`
per line, documented in
[memo's README](https://codeberg.org/mrflos/memo#options). After editing it:

```bash
systemctl restart memo
```

An upgrade rewrites that file from the package template. YunoHost notices the
file changed, keeps a copy next to it, and tells you where. The config panel
settings survive because YunoHost stores them separately and puts them back.

Board pictures go into the same SQLite file as the boards, sixteen per board by
default. Raise `MAX_IMAGES` if that is tight, and expect the file to grow: a
photograph is a hundred times a card. The 16 MB ceiling on an upload is nginx's
`client_max_body_size`, in the app's config.

## When nobody is signed in

If memo shows everyone as anonymous, the chain to check is short. SSOwat sets
`ynh_user` on the request from the portal cookie, and `proxy_params_with_auth`,
which YunoHost ships and the app's nginx config includes, turns it into the
`Ynh-User` header memo reads. It only happens at all because the permission
asks for it, with `main.auth_header = true` in the manifest. The two lines that
pick those names up are in the `.env`:

```ini
PROXY_USER_HEADER=Ynh-User
PROXY_NAME_HEADER=Ynh-User-Fullname
```

Do not point them at `Remote-User` or any other name. SSOwat strips the headers
a client sent whose name starts with `ynh_` or `ynh-`, and only those, so any
other name is one a visitor can set for themselves and be whoever they like.

## Backups

The YunoHost archive carries the whole install directory, and almost all of
that is the 90 MB binary. A restore then needs no network. If you back up
nightly and the size bothers you, back up the data directory alone: the boards
are all of it, and a reinstall plus a restore of `$data_dir` gets you back.

memo takes its own snapshots too, from the admin page. `VACUUM INTO` copies the
database while the server keeps serving, the copy is opened and checked before
any older one is dropped, and it lands in `/home/yunohost.app/memo/backups`.
Seven are kept, which `BACKUP_KEEP` in the `.env` changes. They are in the data
directory, so a YunoHost archive carries them along with the boards. That is the
price of being able to take one in the middle of a workshop without a shell.

## Architecture

memo is one compiled binary, about 90 MB, holding the bun runtime, the server
and every page, font and background image it serves. Nothing else is installed:
no checkout, no node_modules, and no npm registry to reach.

Upstream compiles it with bun, which has no runtime for armhf or for 32 bit
machines, so this package installs on x86-64 and aarch64 only.

Every release publishes three binaries and the install picks one. On aarch64
there is only the arm64 build. On x86-64 it reads the processor flags in
`/proc/cpuinfo`: AVX2, which means anything since about 2013, gets the fast
build, and an older machine gets the baseline one, which runs the same code
somewhat slower. The binary it chose is then run once with `--help` before the
service ever starts, so a machine that advertises AVX2 it cannot really do
falls back to baseline instead of leaving you a service that dies on `Illegal
instruction`.

Every upgrade makes that choice again. A restore does not: the archive carries
the binary that was picked on the old machine, so after restoring onto a
different processor, run `yunohost app upgrade -F memo` to get the right one.
