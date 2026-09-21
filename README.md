# dnsid Scoop bucket

The [DNSid](https://dnsid.ai) CLI for Windows — verifiable, domain-anchored
identity for AI agents.

```powershell
scoop bucket add dnsid https://github.com/dnsid-ai/scoop-bucket
scoop install dnsid
```

Then:

```powershell
dnsid --version
dnsid            # command list
```

To upgrade, `scoop update dnsid`. To remove, `scoop uninstall dnsid`.

Windows x64 only. macOS and Linux users want the
[Homebrew tap](https://github.com/dnsid-ai/homebrew-tap) instead.

## Publishing a new version

Actions → **Update manifest** → Run workflow → enter the release version.

That is the whole process. The workflow fetches `SHA256SUMS` for that version,
checks the archive is actually downloadable, renders `bucket/dnsid.json`, and
commits it. Tick **dry run** to see the result without committing.

It fails without committing if the version has no artifacts behind it, so
running it against a tag whose release never uploaded anything is safe.

To render locally instead:

```sh
./scripts/render-manifest.sh 2026.08.25-22f2882
```

## Making this automatic

Scoop can update the manifest itself, on a schedule, with no workflow of ours —
but only once it has a public source to read versions from. `dnsid` is
currently in a private repository, so there is nothing for `checkver` to watch.

When `dnsid-ai/dnsid` is public and publishing release assets, add these two
stanzas to `templates/dnsid.json.tmpl` and adopt the scheduled excavator job
from [BucketTemplate](https://github.com/ScoopInstaller/BucketTemplate):

```json
"checkver": {
    "github": "https://github.com/dnsid-ai/dnsid"
},
"autoupdate": {
    "architecture": {
        "64bit": {
            "url": "https://github.com/dnsid-ai/dnsid/releases/download/$version/dnsid_windows_amd64.zip"
        }
    }
}
```

At that point the Update manifest workflow can go away.

## About this repository

`bucket/dnsid.json` is generated. **Do not edit it by hand** — the next publish
overwrites it. Change `templates/dnsid.json.tmpl` instead.

The download host is stated in exactly one place, `ARTIFACT_BASE` in
`scripts/render-manifest.sh`. Changing where artifacts are served is a one-line
edit here and a re-run — the CLI's own repository holds no Scoop configuration
and needs no credential for this bucket.

`license` is `Proprietary` with a `url` pointing at [LICENSE](LICENSE), the
terms the dnsid binary is distributed under. `scoop info dnsid` shows both.

Issues with the CLI itself belong on the upstream tracker, not here.
