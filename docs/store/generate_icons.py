#!/usr/bin/env python3
"""Every launcher, store and web icon the project ships, resampled from
`icon-master.png` in one pass.

    python docs/store/generate_icons.py     # runs from any directory

Rejected: `flutter_launcher_icons`. The package writes adaptive icons happily,
but it has to be handed a foreground layer that already carries the emblem alone
on transparency, and producing that layer is the whole job here -- the master is
a 3D render with soft shading and a glow, so there is no clean alpha to key out.
What the package would be left doing is the resampling, in exchange for a dev
dependency in a `pubspec.yaml` that is kept bare on purpose.

PLATE is the one number this file shares with the app: it must stay equal to
`@color/ic_launcher_background` in `android/app/src/main/res/values/colors.xml`,
because the Android 12 SplashScreen API draws the launcher icon over that colour
and a shade of difference puts a visible disc on the launch screen -- which is
the bug this whole file exists to fix.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageMath

ROOT = Path(__file__).resolve().parents[2]
MASTER = Path(__file__).resolve().parent / "icon-master.png"

# The launch screen's colour, and now the icon's plate. Keep in step with
# @color/ic_launcher_background.
PLATE = (0x1B, 0x1F, 0x2A)

# Everything is composed at 10x an adaptive icon layer (108dp) and resampled
# down, so no output is ever an upscale of a smaller intermediate.
WORK = 1080

# Measured from icon-master.png: the emblem fits a circle of this radius, as a
# fraction of the master's width. Slightly over 0.5 -- the artwork reaches past
# its own inscribed circle -- which is what sets the mask radii below.
CONTENT_RADIUS = 0.5084
# The band over which the master's edge dissolves into the plate, and the blur
# that softens it, both as a fraction of the master's side. Their sum has to stay
# under 0.061 -- the measured gap between the emblem and the master's edge at its
# narrowest, along the bottom -- or the feather starts eating the artwork.
FEATHER_INSET = 0.010
FEATHER_BLUR = 0.008

# An adaptive layer is 108dp, of which the centre 72dp is shown and a 66dp circle
# is guaranteed. At this scale the emblem spans 62dp: ~20% larger than the legacy
# treatment used to render it, with 4dp still in hand.
ANDROID_SCALE = 0.565
# A maskable web icon only has to keep its content inside the central 80%, so the
# same artwork can sit larger there than on Android.
WEB_MASKABLE_SCALE = 0.78

# Adaptive icon layers, one per density.
ANDROID_DENSITIES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

# Apple's macOS icon grid: the artwork is a rounded square inset in the canvas
# rather than edge to edge, because macOS applies no mask of its own.
MACOS_SIDE = 824 / 1024
MACOS_RADIUS = 185.4 / 1024
MACOS_SIZES = (16, 32, 64, 128, 256, 512, 1024)

# Contents.json already names these files; only the pixels change.
IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# Silhouette extraction for the <monochrome> layer: everything brighter than the
# backdrop, plus everything the blue channel dominates, which is how the arrow
# survives a threshold the grey "A" sets. Rejected: keying on what differs from a
# heavily blurred copy of the master. That finds the emblem's outline but leaves
# its wide flat faces hollow -- a blur wide enough to model the backdrop returns
# the face's own colour inside the face -- and the layer came out a ring soup.
MONO_MEDIAN = 7
MONO_LUMA = 45
MONO_BLUE = 35
MONO_CLOSE = 9

# Pushing the master's own backdrop to PLATE. The backdrop is estimated by
# diffusing it inwards over the emblem -- a plain wide blur would drag the
# emblem's grey out into the estimate and leave a bright ghost of it behind.
BACKDROP_PASSES = 8
BACKDROP_BLUR = 40
BACKDROP_GUARD = 10
# How far out the correction is applied, as a fraction of the master's width:
# nothing at the centre, everything past the outer bound. The centre is spared so
# the blue glow behind the "A" survives -- it is low-frequency enough that the
# estimate would otherwise read it as backdrop and flatten it away.
FLATTEN_FROM = 0.25
FLATTEN_TO = 0.45


def _radial_mask(size: int, r1: float, r2: float) -> Image.Image:
    """Opaque within r1 of the centre, smoothstepped to nothing at r2."""
    centre = (size - 1) / 2
    r1_sq, r2_sq = r1 * r1, r2 * r2
    span = r2 - r1
    buf = bytearray(size * size)
    for y in range(size):
        dy_sq = (y - centre) ** 2
        row = y * size
        for x in range(size):
            d_sq = dy_sq + (x - centre) ** 2
            if d_sq <= r1_sq:
                buf[row + x] = 255
            elif d_sq < r2_sq:
                t = (math.sqrt(d_sq) - r1) / span
                buf[row + x] = int(255 * (1 - t * t * (3 - 2 * t)) + 0.5)
    return Image.frombytes("L", (size, size), bytes(buf))


def _plate_mask(size: int, side: int) -> Image.Image:
    """Where the master shows through the plate.

    Two masks, taken at their minimum. The radial one throws the master's light
    corners away entirely; the rectangular feather softens the four edges along
    the axes, which the radial one cannot reach because the square's edge there
    is nearer the centre than the radius that clears the emblem.
    """
    radial = _radial_mask(size, CONTENT_RADIUS * side, 0.62 * side)

    inset = max(1, round(FEATHER_INSET * side))
    offset = (size - side) // 2
    feather = Image.new("L", (size, size), 0)
    ImageDraw.Draw(feather).rectangle(
        [offset + inset, offset + inset, offset + side - 1 - inset, offset + side - 1 - inset],
        fill=255,
    )
    feather = feather.filter(ImageFilter.GaussianBlur(max(1, round(FEATHER_BLUR * side))))

    return ImageChops.darker(radial, feather)


def flatten(master: Image.Image, shape: Image.Image) -> Image.Image:
    """The master with its backdrop pushed to exactly PLATE towards the edges.

    Without this the icon still reads as a soft square: the artwork's backdrop
    runs from #171A25 at its edges to #272B37 at its corners, and dissolving that
    into a flat plate leaves a halo where the two meet. Correcting it needs the
    backdrop known under the emblem too, which is what the diffusion below is
    for -- the emblem is punched out and the surrounding backdrop repeatedly
    blurred into the hole until it closes.
    """
    hole = ImageChops.invert(
        shape.filter(ImageFilter.GaussianBlur(BACKDROP_GUARD)).point(lambda v: 255 if v > 20 else 0)
    )
    estimate = master
    for _ in range(BACKDROP_PASSES):
        estimate = Image.composite(
            master, estimate.filter(ImageFilter.GaussianBlur(BACKDROP_BLUR)), hole
        )
    estimate = estimate.filter(ImageFilter.GaussianBlur(BACKDROP_BLUR * 2))

    corrected = Image.merge(
        "RGB",
        [
            ImageMath.lambda_eval(
                lambda a, level=level: a["m"] - a["e"] + level,
                m=channel.convert("I"),
                e=reference.convert("I"),
            ).convert("L")
            for channel, reference, level in zip(master.split(), estimate.split(), PLATE)
        ],
    )
    side = master.width
    weight = ImageChops.invert(_radial_mask(side, FLATTEN_FROM * side, FLATTEN_TO * side))
    return Image.composite(corrected, master, weight)


def plate(master: Image.Image, scale: float, size: int = WORK) -> Image.Image:
    """The master dissolved into a flat PLATE square, fully opaque.

    Opaque on purpose: with transparent margins Android 12's
    `SplashscreenContentDrawer` decides the foreground has room and enlarges it,
    so the emblem on the launch screen stops matching the launcher.
    """
    side = round(scale * size)
    flat = Image.new("RGB", (size, size), PLATE)
    art = flat.copy()
    art.paste(master.resize((side, side), Image.LANCZOS), ((size - side) // 2,) * 2)
    return Image.composite(art, flat, _plate_mask(size, side))


def silhouette(master: Image.Image) -> Image.Image:
    """The emblem's shape as an alpha mask, for the themed-icon layer."""
    smoothed = master.filter(ImageFilter.MedianFilter(MONO_MEDIAN))
    red, green, blue = smoothed.split()
    shape = ImageChops.lighter(
        smoothed.convert("L").point(lambda v: 255 if v > MONO_LUMA else 0),
        ImageChops.subtract(blue, ImageChops.lighter(red, green))
        .point(lambda v: 255 if v > MONO_BLUE else 0),
    )
    # The master's top-left corner is the one patch of backdrop bright enough to
    # pass the luma threshold, so the measured content circle vetoes it.
    side = master.width
    shape = ImageChops.darker(
        shape, _radial_mask(side, CONTENT_RADIUS * side, CONTENT_RADIUS * side + 1)
    )
    # A close, not a dilate: it fills the render's speckle while leaving the
    # counter of the "A" open, which is the one feature that reads at 48px.
    return shape.filter(ImageFilter.MaxFilter(MONO_CLOSE)).filter(ImageFilter.MinFilter(MONO_CLOSE))


def monochrome(shape: Image.Image, scale: float, size: int = WORK) -> Image.Image:
    """A black layer whose alpha is the emblem; the system supplies the colour."""
    side = round(scale * size)
    alpha = Image.new("L", (size, size), 0)
    alpha.paste(shape.resize((side, side), Image.LANCZOS), ((size - side) // 2,) * 2)
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.002 * size))
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    layer.putalpha(alpha)
    return layer


def rounded(master: Image.Image, size: int, supersample: int = 4) -> Image.Image:
    """The master as a rounded square on transparency, for macOS.

    The mask is built from the same integer box the artwork is pasted into, drawn
    supersampled for the antialiasing: a mask laid out in its own float geometry
    overhangs the artwork by a fraction of a pixel and turns the overhang opaque
    black, which at 16px is a visible sliver.
    """
    side = round(MACOS_SIDE * size)
    offset = (size - side) // 2
    ss = supersample
    mask = Image.new("L", (size * ss, size * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [offset * ss, offset * ss, (offset + side) * ss - 1, (offset + side) * ss - 1],
        radius=MACOS_RADIUS * size * ss,
        fill=255,
    )
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon.paste(master.resize((side, side), Image.LANCZOS), (offset, offset))
    icon.putalpha(mask.resize((size, size), Image.LANCZOS))
    return icon


def write(image: Image.Image, path: Path, mode: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = image.convert(mode)
    out.save(path, "PNG", optimize=True)
    print(f"  {out.width:>4}x{out.height:<4} {mode:<4} {path.relative_to(ROOT).as_posix()}")


def main() -> None:
    master = Image.open(MASTER).convert("RGB")
    print(f"master {master.width}x{master.height} -> plate #{bytes(PLATE).hex()}")

    shape = silhouette(master)
    # Only the layers that sit on the plate get the backdrop correction. iOS,
    # macOS and the non-maskable web icons ship the master edge to edge, where its
    # own backdrop is the whole background and has nothing to match.
    on_plate = flatten(master, shape)
    foreground = plate(on_plate, ANDROID_SCALE)
    themed = monochrome(shape, ANDROID_SCALE)
    print("\nandroid adaptive layers (108dp)")
    res = ROOT / "android/app/src/main/res"
    for density, size in ANDROID_DENSITIES.items():
        box = (size, size)
        write(foreground.resize(box, Image.LANCZOS), res / f"mipmap-{density}/ic_launcher_foreground.png", "RGB")
        write(themed.resize(box, Image.LANCZOS), res / f"mipmap-{density}/ic_launcher_monochrome.png", "RGBA")

    print("\nios (edge to edge, no alpha -- iOS masks it and the App Store rejects alpha)")
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in IOS_ICONS.items():
        write(master.resize((size, size), Image.LANCZOS), ios / name, "RGB")

    print("\nmacos (Apple's grid: rounded square inset in the canvas)")
    macos = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in MACOS_SIZES:
        write(rounded(master, size), macos / f"app_icon_{size}.png", "RGBA")

    print("\nweb")
    web = ROOT / "web"
    for size in (192, 512):
        write(master.resize((size, size), Image.LANCZOS), web / f"icons/Icon-{size}.png", "RGB")
    maskable = plate(on_plate, WEB_MASKABLE_SCALE)
    for size in (192, 512):
        write(maskable.resize((size, size), Image.LANCZOS), web / f"icons/Icon-maskable-{size}.png", "RGB")
    write(master.resize((16, 16), Image.LANCZOS), web / "favicon.png", "RGBA")


if __name__ == "__main__":
    main()
