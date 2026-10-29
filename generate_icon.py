import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def create_asad_icon(size=1024):
    # Render at 2048x2048 supersampled for ultra-sharp clarity
    scale = 2
    full_sz = size * scale
    img = Image.new("RGBA", (full_sz, full_sz), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # 1. Background Gradient (First Color: Royal Dark Emerald)
    top_color = (6, 78, 59, 255)       # #064E3B
    bottom_color = (11, 19, 17, 255)   # #0B1311
    for y in range(full_sz):
        t = y / full_sz
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * t)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * t)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * t)
        draw.line([(0, y), (full_sz, y)], fill=(r, g, b, 255))

    # Center radial glow
    cx, cy = full_sz / 2, full_sz * 0.47
    glow_img = Image.new("RGBA", (full_sz, full_sz), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    glow_radius = int(full_sz * 0.44)
    for rad in range(glow_radius, 0, -8):
        alpha = int(45 * (1 - rad / glow_radius))
        glow_draw.ellipse(
            [cx - rad, cy - rad, cx + rad, cy + rad],
            fill=(16, 185, 129, alpha)
        )
    img = Image.alpha_composite(img, glow_img)
    draw = ImageDraw.Draw(img)

    w = full_sz
    h = full_sz

    # 2. Outer Protective Academic Shield
    shield_pts = [
        (w * 0.16, h * 0.13),
        (w * 0.84, h * 0.13),
        (w * 0.88, h * 0.32),
        (w * 0.84, h * 0.54),
        (cx, h * 0.88),
        (w * 0.16, h * 0.54),
        (w * 0.12, h * 0.32),
    ]

    shield_mask = Image.new("L", (full_sz, full_sz), 0)
    ImageDraw.Draw(shield_mask).polygon(shield_pts, fill=255)

    shield_fill = Image.new("RGBA", (full_sz, full_sz), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shield_fill)
    s_top = (13, 94, 72, 255)   # #0D5E48
    s_bot = (4, 47, 36, 255)    # #042F24
    for y in range(full_sz):
        t = y / full_sz
        r = int(s_top[0] + (s_bot[0] - s_top[0]) * t)
        g = int(s_top[1] + (s_bot[1] - s_top[1]) * t)
        b = int(s_top[2] + (s_bot[2] - s_top[2]) * t)
        s_draw.line([(0, y), (full_sz, y)], fill=(r, g, b, 255))
    img.paste(shield_fill, (0, 0), shield_mask)

    # Shield Inner Glow & Border
    draw.polygon(shield_pts, outline=(16, 185, 129, 230), width=int(full_sz * 0.015))
    inner_shield = [
        (p[0] + (cx - p[0]) * 0.038, p[1] + (cy - p[1]) * 0.038) for p in shield_pts
    ]
    draw.polygon(inner_shield, outline=(5, 150, 105, 110), width=int(full_sz * 0.007))

    # 3. Emerald QR Brackets (أركان الـ QR الخضراء)
    bracket_len = full_sz * 0.11
    bracket_w = int(full_sz * 0.017)
    qr_col = (16, 185, 129, 255)

    def draw_bracket(bx, by, dx, dy):
        draw.line([(bx, by), (bx + dx * bracket_len, by)], fill=qr_col, width=bracket_w)
        draw.line([(bx, by), (bx, by + dy * bracket_len)], fill=qr_col, width=bracket_w)
        dot_x = bx + dx * bracket_len * 0.45
        dot_y = by + dy * bracket_len * 0.45
        dr = bracket_w * 0.8
        draw.ellipse([dot_x - dr, dot_y - dr, dot_x + dr, dot_y + dr], fill=qr_col)

    draw_bracket(full_sz * 0.08, full_sz * 0.08, 1, 1)
    draw_bracket(full_sz * 0.92, full_sz * 0.08, -1, 1)
    draw_bracket(full_sz * 0.11, full_sz * 0.80, 1, -1)
    draw_bracket(full_sz * 0.89, full_sz * 0.80, -1, -1)

    # 4. Faceted Geometric Lion Head (Transparent / Glassmorphic)
    topP = (cx, h * 0.22)
    topL = (w * 0.38, h * 0.26)
    topR = (w * 0.62, h * 0.26)
    outerTopL = (w * 0.27, h * 0.32)
    outerTopR = (w * 0.73, h * 0.32)

    midL = (w * 0.24, h * 0.48)
    midR = (w * 0.76, h * 0.48)
    innerMidL = (w * 0.36, h * 0.45)
    innerMidR = (w * 0.64, h * 0.45)

    browMid = (cx, h * 0.38)
    eyeL = (w * 0.42, h * 0.44)
    eyeR = (w * 0.58, h * 0.44)

    noseTop = (cx, h * 0.52)
    noseTip = (cx, h * 0.60)
    noseL = (w * 0.44, h * 0.58)
    noseR = (w * 0.56, h * 0.58)

    jawL = (w * 0.35, h * 0.68)
    jawR = (w * 0.65, h * 0.68)
    chin = (cx, h * 0.76)

    # Glassy / Transparent Facets (Very subtle sheen, background shines completely through!)
    glass_layer = Image.new("RGBA", (full_sz, full_sz), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glass_layer)

    g1 = (255, 255, 255, 26)    # 10% white glass sheen
    g2 = (16, 185, 129, 30)     # 11% emerald glass tint
    g3 = (255, 255, 255, 14)    # 5% soft reflection
    g4 = (16, 185, 129, 20)

    for pts, col in [
        ([topP, topL, browMid], g1),
        ([topP, topR, browMid], g2),
        ([topL, outerTopL, innerMidL], g3),
        ([topR, outerTopR, innerMidR], g4),
        ([outerTopL, midL, innerMidL], g2),
        ([outerTopR, midR, innerMidR], g1),
        ([innerMidL, jawL, chin], g4),
        ([innerMidR, jawR, chin], g3),
        ([browMid, innerMidL, noseTop], g2),
        ([browMid, innerMidR, noseTop], g1),
        ([noseTop, innerMidL, jawL, noseTip], g3),
        ([noseTop, innerMidR, jawR, noseTip], g4),
        ([noseTop, noseL, noseTip], g1),
        ([noseTop, noseR, noseTip], g2),
    ]:
        g_draw.polygon(pts, fill=col)

    img = Image.alpha_composite(img, glass_layer)
    draw = ImageDraw.Draw(img)

    # Facet lines - Crisp Silver White
    line_w = int(full_sz * 0.011)
    line_col = (248, 250, 252, 235)

    def draw_path(pts):
        for i in range(len(pts) - 1):
            draw.line([pts[i], pts[i + 1]], fill=line_col, width=line_w)

    draw_path([topP, topL, outerTopL, midL, jawL, chin, jawR, midR, outerTopR, topR, topP])
    draw_path([topL, browMid, topR])
    draw_path([browMid, noseTop])
    draw_path([topL, innerMidL, noseTop, innerMidR, topR])
    draw_path([innerMidL, midL])
    draw_path([innerMidR, midR])
    draw_path([innerMidL, jawL])
    draw_path([innerMidR, jawR])
    draw_path([noseTop, noseL, noseTip, noseR, noseTop])
    draw_path([noseTip, chin])

    # Distinctive Glowing Gold Eyes
    eye_w = int(full_sz * 0.013)
    gold_col = (251, 191, 36, 255)
    draw.line([(eyeL[0] - full_sz * 0.035, eyeL[1]), (eyeL[0], eyeL[1] - full_sz * 0.018)], fill=gold_col, width=eye_w)
    draw.line([(eyeL[0], eyeL[1] - full_sz * 0.018), (eyeL[0] + full_sz * 0.025, eyeL[1])], fill=gold_col, width=eye_w)
    draw.line([(eyeL[0] - full_sz * 0.035, eyeL[1]), (eyeL[0] + full_sz * 0.025, eyeL[1])], fill=gold_col, width=eye_w)

    draw.line([(eyeR[0] + full_sz * 0.035, eyeR[1]), (eyeR[0], eyeR[1] - full_sz * 0.018)], fill=gold_col, width=eye_w)
    draw.line([(eyeR[0], eyeR[1] - full_sz * 0.018), (eyeR[0] - full_sz * 0.025, eyeR[1])], fill=gold_col, width=eye_w)
    draw.line([(eyeR[0] + full_sz * 0.035, eyeR[1]), (eyeR[0] - full_sz * 0.025, eyeR[1])], fill=gold_col, width=eye_w)

    # 5. ASAD Wordmark
    font_size = int(full_sz * 0.088)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
    text = "ASAD"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    tx = (full_sz - tw) / 2
    ty = full_sz * 0.888
    draw.text((tx, ty + 3), text, font=font, fill=(0, 0, 0, 180))
    draw.text((tx, ty), text, font=font, fill=(248, 250, 252, 255))

    return img.resize((size, size), Image.Resampling.LANCZOS)

def distribute_icons(master_img):
    # iOS Icons
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_targets = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    if os.path.exists(ios_dir):
        for name, sz in ios_targets:
            res = master_img.resize((sz, sz), Image.Resampling.LANCZOS)
            res.save(os.path.join(ios_dir, name), "PNG")
        print("Updated iOS app icons in", ios_dir)

    # Android Mipmaps
    android_targets = [
        ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
        ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
        ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
        ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
        ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
    ]
    for path, sz in android_targets:
        if os.path.exists(os.path.dirname(path)):
            res = master_img.resize((sz, sz), Image.Resampling.LANCZOS)
            res.save(path, "PNG")
    print("Updated Android launcher icons in mipmap folders")

    # macOS Icons
    macos_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    macos_targets = [
        ("app_icon_16.png", 16),
        ("app_icon_32.png", 32),
        ("app_icon_64.png", 64),
        ("app_icon_128.png", 128),
        ("app_icon_256.png", 256),
        ("app_icon_512.png", 512),
        ("app_icon_1024.png", 1024),
    ]
    if os.path.exists(macos_dir):
        for name, sz in macos_targets:
            res = master_img.resize((sz, sz), Image.Resampling.LANCZOS)
            res.save(os.path.join(macos_dir, name), "PNG")
        print("Updated macOS app icons in", macos_dir)

    # Web Icons
    web_targets = [
        ("web/icons/Icon-192.png", 192),
        ("web/icons/Icon-512.png", 512),
        ("web/icons/Icon-maskable-192.png", 192),
        ("web/icons/Icon-maskable-512.png", 512),
        ("web/favicon.png", 32),
    ]
    for path, sz in web_targets:
        if os.path.exists(os.path.dirname(path)):
            res = master_img.resize((sz, sz), Image.Resampling.LANCZOS)
            res.save(path, "PNG")
    print("Updated Web icons and favicon")

if __name__ == "__main__":
    icon = create_asad_icon()
    os.makedirs("assets/images", exist_ok=True)
    icon.save("assets/images/asad_icon_1024.png", "PNG")
    print("Master 1024x1024 ASAD Icon generated at assets/images/asad_icon_1024.png")
    distribute_icons(icon)
    print("All icons successfully distributed!")
