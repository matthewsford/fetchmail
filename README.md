# fetchmail-image

Minimal Alpine image that runs [fetchmail](https://www.fetchmail.info/) as a non-root user
(UID/GID 1002), for pulling mail from a remote IMAP account and delivering it to a local MTA over
LMTP. Built for the `stalwart` namespace in the `server-ops` cluster.

## How it behaves

- Reads the run-control file from `/etc/fetchmail/fetchmailrc` (override with `FETCHMAIL_RC`).
- Copies it to `$HOME/.fetchmailrc` with mode 0600, because fetchmail rejects a file it doesn't
  own and a mounted Secret is owned by root. `HOME` is `/tmp`, so the container works with
  `readOnlyRootFilesystem` as long as `/tmp` is a writable volume.
- Runs `fetchmail --nodetach --nosyslog`, logging to stderr. Extra container args are passed to
  fetchmail.
- Runs under `tini` as PID 1.

## License

The files in this repository are licensed under `GPL-2.0-or-later`, the same base license as
fetchmail (see [LICENSES/](LICENSES/GPL-2.0-or-later.txt) and `REUSE.toml`; check compliance with
`reuse lint`). The image also contains fetchmail, Alpine Linux and their dependencies, which keep
their own licenses.

## Build

```sh
docker build -t fetchmail-image .
```

### Updating pinned versions

The base image is pinned by digest and the `apk` packages by exact version. Alpine removes
superseded package versions from a release's repository, so the build breaks when a pinned
version is replaced. To bump:

1. Base digest: `docker buildx imagetools inspect alpine:3.22` and copy the `Digest:` line.
2. Packages: find the current versions with
   `docker run --rm alpine:3.22@sha256:<digest> sh -c 'apk update && apk policy fetchmail ca-certificates tini'`.
3. Update the `Dockerfile` and rebuild.

GitHub Actions publishes `ghcr.io/<owner>/fetchmail-image` on pushes to `main` (tags `latest` and
`YYYY.MM.DD-<sha>`), on `v*` tags, and on a weekly schedule for base-image updates. Pull requests
build without pushing.

## Using it in Kubernetes

Pin the image by digest in the Deployment. The container needs:

- the run-control file mounted at `/etc/fetchmail/fetchmailrc`
- a writable `/tmp` (an `emptyDir`)
- `runAsUser: 1002`

Example run-control file (IMAP IDLE, deliver over LMTP, delete after delivery):

```
set daemon 300
set no bouncemail
set postmaster "me@example.com"
poll imap.example.com protocol IMAP port 993
  user "me@example.com" there with password "app-password"
  is "me@example.com" here
  ssl sslcertck sslproto TLS1.2+
  idle
  fetchall
  nokeep
  smtphost mail.mail.svc/24
  lmtp
  smtpname "me@example.com"
```
