## Where things are

| What | Where |
| --- | --- |
| The code, the bun runtime, node_modules | `/var/www/memo` |
| Every board, in one SQLite file | `/home/yunohost.app/memo/memo.sqlite` |
| Configuration | `/var/www/memo/.env` |
| Log | `/var/log/memo/memo.log` |

Removing the app leaves the boards behind. `yunohost app remove memo --purge`
is what deletes them.

## Accounts

Anyone the permission lets in arrives already signed in, under their YunoHost
name. memo mints no session of its own here, so signing out of the portal signs
you out of memo too, and there is no second password to manage.

The account you chose at install time got memo's admin page, at
`https://your.domain/memo/admin`, which lists, searches and deletes boards and
manages accounts. That grant happens once, while memo has no admin at all.
Changing the setting afterwards does nothing. To add or remove an admin later,
do it from that page.

YunoHost group membership is not forwarded, so memo's `ADMIN_GROUP` and its
group-based board sharing have nothing to read. Share a private board with
people by name.

## Configuration

Three settings have a config panel: the default interface language, and a logo
and favicon URL to replace memo's own. Everything else lives in
`/var/www/memo/.env`, one `KEY=value` per line, documented in
[memo's README](https://codeberg.org/mrflos/memo#options). After editing it:

```bash
systemctl restart memo
```

An upgrade rewrites that file from the package template. YunoHost notices the
file changed, keeps a copy next to it, and tells you where. The three config
panel settings survive because YunoHost stores them separately and puts them
back.

## When nobody is signed in

If memo shows everyone as anonymous, the chain to check is short. SSOwat sets
`YNH_USER` on the request from the portal cookie; the app's nginx config turns
it into the `Remote-User` header memo reads. That translation is these two
lines of `/etc/nginx/conf.d/your.domain.d/memo.conf`:

```nginx
proxy_set_header Remote-User $http_ynh_user;
proxy_set_header Remote-Name $http_ynh_user_fullname;
```

and it only happens at all because the permission asks for it, with
`main.auth_header = true` in the manifest. If the header never arrives, set
memo to read SSOwat's names directly instead: put `PROXY_USER_HEADER=ynh_user`
and `PROXY_NAME_HEADER=ynh_user_fullname` in `.env`, restart, and drop the two
nginx lines.

## Backups

The archive carries the whole install directory, and about 100 MB of that is
the bun runtime and node_modules. A restore then needs no network. If you back
up nightly and the size bothers you, back up the data directory alone: the
boards are all of it, and a reinstall plus a restore of `$data_dir` gets you
back.

## Architecture

Bun publishes builds for x86-64 and aarch64 only. An armhf board or a 32 bit
machine cannot run this package. The x86-64 build shipped here is the baseline
one, which works on CPUs older than 2013 at some cost in speed.
