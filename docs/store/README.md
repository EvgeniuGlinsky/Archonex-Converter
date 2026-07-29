# Store assets

Everything Google Play asks for as a file, plus the sources it is built from.
`PLAY_LISTING.md` beside this folder holds the text.

| File | What it is |
| --- | --- |
| `feature-graphic.png` | 1024×500 banner for the listing. Mandatory — Play will not publish without it. |
| `feature-graphic.html` | Source of the above. Rendered, not drawn. |
| `feature-graphic-bg.png` | Generated background the banner is composed over. |
| `icon-512.png` | 512×512 listing icon. |
| `icon-master.png` | 950×950 icon artwork every size is derived from. |
| `generate_icons.py` | Builds every launcher, app and web icon from the master. |
| `01-catalogue.png`, `02-media-converter.png` | Phone screenshots, numbered in the order the listing reads them. |

## Regenerating the feature graphic

The command is in `feature-graphic.html`'s own header. Change the wording in the
HTML, run it, and the PNG is replaced — no design tool involved, and the type
stays the NotoSans the app screens are already set in.

## Regenerating the icon sizes

    python docs/store/generate_icons.py     # from anywhere; needs Pillow

Everything comes out of `icon-master.png` in one pass: the Android adaptive icon
layers, the iOS and macOS asset catalogues, and the web icons. Two files it does
**not** touch, on purpose — `icon-512.png`, which Play wants uploaded by hand, and
`mipmap-*/ic_launcher.png`, the legacy PNGs only API 24–25 still reads — Flutter's
`minSdkVersion` is 24, so that window is two releases wide — where
nothing masks the icon and edge-to-edge is the right thing to hand over.

Each platform gets the master shaped the way that platform expects:

| Where | Shape |
| --- | --- |
| Android `mipmap-*/ic_launcher_foreground.png` | 108 dp layer, emblem at 62 dp — inside the guaranteed 66 dp circle, and ~20% larger than the legacy treatment drew it. Backdrop pushed to `@color/ic_launcher_background`. |
| Android `ic_launcher_monochrome.png` | Alpha-only silhouette for the Android 13 themed icon. |
| iOS | Edge to edge, no alpha: iOS masks it itself, and alpha in the 1024 marketing icon is an App Store rejection. |
| macOS | Apple's grid — a rounded square at 824/1024 with a 185.4/1024 radius, on transparency, because macOS applies no mask. |
| web `Icon-*.png` | Edge to edge. |
| web `Icon-maskable-*.png` | Plate to the edges, emblem inside the central 80% the maskable spec guarantees. |

The plate colour lives twice: `PLATE` in the script and
`@color/ic_launcher_background` in `android/app/src/main/res/values/colors.xml`.
They have to stay equal — Android 12 draws the launcher icon over
`windowSplashScreenBackground`, which aliases that colour, so a drift of a shade
puts a visible disc on the launch screen.

The master itself was cropped out of a generated image that arrived as a rounded
plaque floating on black, which is what image generators produce when asked for an
app icon. Two things had to go: the black margin, because every platform applies
its own shape mask and a pre-baked one rounds twice, and the plaque's own corner
radius, measured at ~265 px, which meant insetting `r(1 − 1/√2)` ≈ 76 px per side
to land the crop on artwork rather than on black.

## Still outstanding

- **Screenshots that show the app working.** Both current ones are empty states;
  the catalogue reads well as an opening frame, but the media converter shows a
  disabled button and nothing happening.
- **The macOS drop shadow.** Apple's grid puts one under the rounded square. The
  generator draws the square only, which is legible but not quite native.
- **iOS launch images.** `LaunchImage.imageset` is still Flutter's 1×1
  placeholders, so the iOS launch screen is blank white where Android's is
  `#1B1F2A`. Neither iOS nor macOS is being released yet.
