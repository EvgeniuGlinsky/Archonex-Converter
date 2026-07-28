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
| `01-catalogue.png`, `02-media-converter.png` | Phone screenshots, numbered in the order the listing reads them. |

## Regenerating the feature graphic

The command is in `feature-graphic.html`'s own header. Change the wording in the
HTML, run it, and the PNG is replaced — no design tool involved, and the type
stays the NotoSans the app screens are already set in.

## Regenerating the icon sizes

`icon-master.png` is the master. From it come `icon-512.png` and the five
launcher densities in `android/app/src/main/res/mipmap-*/ic_launcher.png` — 48,
72, 96, 144 and 192 px for mdpi through xxxhdpi — resampled bicubic and saved
32-bit.

The master was cropped out of a generated image that arrived as a rounded plaque
floating on black, which is what image generators produce when asked for an app
icon. Two things had to go: the black margin, because Play and Android apply
their own shape mask and a pre-baked one rounds twice, and the plaque's own
corner radius, measured at ~265 px, which meant insetting `r(1 − 1/√2)` ≈ 76 px
per side to land the crop on artwork rather than on black. The result is
edge-to-edge, which is what both platforms want to be handed.

## Still outstanding

- **Screenshots that show the app working.** Both current ones are empty states;
  the catalogue reads well as an opening frame, but the media converter shows a
  disabled button and nothing happening.
- **Adaptive launcher icon.** The app ships legacy PNG icons only, so Android 8
  and up applies its legacy treatment rather than masking properly. Doing it
  right needs a foreground layer with the emblem inside the central 66% and a
  background layer behind it.
- **iOS, macOS and web icons** are still Flutter's defaults. Neither platform is
  being released yet.
