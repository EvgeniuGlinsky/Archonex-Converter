# Changelog

Notable changes, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Every released version has a [GitHub Release](https://github.com/EvgeniuGlinsky/Archonex-Converter/releases)
with the installable files attached to it.

## [1.1.0] — 2026-07-29

### Changed

- **Android converts and saves without a ceiling of any kind, and nothing is sold there.** The
  monthly count is gone: a cap nobody can pay to lift is worse than no cap, and the paywall it
  pointed at could never take a payment. The last real limit was the 2 GB a Java `byte[]` carries,
  which bounded a saved result — saving now asks for a folder and copies the output into it with
  `dart:io`, so nothing is resident and no result is too large. The subscription and the count stay
  built and tested behind one switch rather than deleted.

### Added

- **A Windows installer.** One `setup.exe`, double clicked, installing for the current user with no
  administrator prompt, a Start Menu entry and an uninstaller. The portable zip is still published
  beside it for anyone who would rather not run an unsigned installer.
- **A Linux AppImage.** `chmod +x` and run — no package manager, no root, nothing beyond GTK 3. The
  tarball is still published beside it.
- **Per-architecture Android APKs.** `arm64` for effectively every device sold in the last decade,
  `arm32` for 32-bit ones, and the universal build for everything else. The universal APK carries a
  native FFmpeg for every architecture at once and is about three times the size of the one a given
  phone actually needs.
- `SHA256SUMS.txt` covering every published file.
- A rehearsal path: a tag matching `rehearsal-*` runs all three builds and publishes nothing, so a
  packaging change can be tested on the runner that will run it without spending a version number.

### Changed

- **Releases are published, not drafted.** Both earlier tags built successfully and then sat as
  drafts nobody published, while the landing page linked to a Releases page with nothing on it.
- **The Play bundle is no longer attached to the release.** An `.aab` is not installable — it is the
  archive Play opens to build a per-device APK — so on a download page it is a trap. It is kept as a
  workflow artifact named `play-bundle`, which replaces the README asking a human to remember to
  delete it from the draft.
- Release notes now lead with a table saying which file to take for which machine, instead of only
  the generated commit log.
- Windows and Linux builds take their version from `pubspec.yaml` like the Android ones already did,
  rather than from the CI run counter.

### Fixed

- The Windows executable no longer reports `com.example` as its company and copyright holder.

## [1.0.1] — 2026-07-29

### Added

- The app's own icon, across Android, iOS, macOS and the web manifest.
- Store assets and the Play listing copy in English, Russian and Chinese.

### Fixed

- The Android launcher no longer masks the icon into a white circle.
- The launch screen no longer shows a dark icon against white.

## [1.0.0] — 2026-07-28

First public release. Three converters, all running on the device with nothing uploaded anywhere:

- **Media** — audio, video and animation, on FFmpeg.
- **Images** — photos in batches, on FFmpeg.
- **PDF** — photos or text into a PDF, and a PDF back out as one image per page.

English, Russian and Chinese throughout. Android, Windows and Linux builds; Linux carries the PDF
converter only, because no FFmpeg engine ships for it.

[1.1.0]: https://github.com/EvgeniuGlinsky/Archonex-Converter/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/EvgeniuGlinsky/Archonex-Converter/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/EvgeniuGlinsky/Archonex-Converter/releases/tag/v1.0.0
