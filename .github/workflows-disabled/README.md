# Disabled workflows

These come from upstream PhotoCraft. `release.yml`, `windows-arm64.yml` and `packaging-lint.yml` call
reusable workflows in `storytold/craft-common-actions` and self-hosted runners (`macos-release`,
Windows ARM64) that exist only in the ArtCraft team's GitHub organisation, along with their
code-signing secrets. `freebsd.yml` and `perf-nightly.yml` run nightly on a schedule, which would
spend a private repository's Actions minutes every day.

They are kept here for reference. To use one, copy it back into `../workflows/` and adapt it to
GitHub-hosted runners and your own signing certificates.
