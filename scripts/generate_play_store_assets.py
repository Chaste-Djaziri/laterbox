#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont

def main():
    repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    output_dir = os.path.join(repo_dir, "assets", "play_store")
    os.makedirs(output_dir, exist_ok=True)
    branding_dir = os.path.join(repo_dir, "assets", "branding")

    icon_white_path = os.path.join(branding_dir, "laterbox-icon-white.png")
    icon_black_path = os.path.join(branding_dir, "laterbox-icon.png")
    logo_white_path = os.path.join(branding_dir, "laterbox-logo-white.png")

    # 1. App Icon: 512 x 512 px (solid background, 32-bit PNG, opaque)
    print("🎨 Generating 512x512 App Icon...")
    icon_512 = Image.new("RGB", (512, 512), (23, 23, 17)) # Dark #171711 background
    draw = ImageDraw.Draw(icon_512)
    # Draw a subtle inner rounded card with green accent #E7FF57
    card_bg = (231, 255, 87) # #E7FF57
    draw.rounded_rectangle([48, 48, 464, 464], radius=96, fill=card_bg)
    
    # Paste black laterbox icon
    if os.path.exists(icon_black_path):
        icon_img = Image.open(icon_black_path).convert("RGBA")
        icon_img = icon_img.resize((300, 300), Image.Resampling.LANCZOS)
        icon_512.paste(icon_img, (106, 106), icon_img)
    icon_512.save(os.path.join(output_dir, "app_icon_512.png"), "PNG")

    # 2. Feature Graphic: 1024 x 500 px
    print("🎨 Generating 1024x500 Feature Graphic...")
    fg = Image.new("RGB", (1024, 500), (15, 15, 12))
    fg_draw = ImageDraw.Draw(fg)
    
    # Background glowing gradients / abstract decorative shapes
    fg_draw.ellipse([-100, -100, 400, 400], fill=(26, 32, 20))
    fg_draw.ellipse([700, 200, 1200, 700], fill=(30, 36, 22))
    
    # Accent pill badge
    fg_draw.rounded_rectangle([400, 60, 624, 104], radius=22, fill=(231, 255, 87))
    fg_draw.text((512, 82), "READ & ORGANIZE LATER", fill=(23, 23, 17), anchor="mm")

    # Place Logo
    if os.path.exists(logo_white_path):
        logo_img = Image.open(logo_white_path).convert("RGBA")
        # Resize logo to width ~480
        aspect = logo_img.height / logo_img.width
        new_w = 460
        new_h = int(new_w * aspect)
        logo_img = logo_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        fg.paste(logo_img, (int((1024 - new_w) / 2), 140), logo_img)

    # Subtitle / Tagline
    fg_draw.text((512, 330), "Save anything now. Read, watch & organize later.", fill=(220, 220, 215), anchor="mm")
    fg_draw.text((512, 375), "Offline-First • Real-Time Sync • Smart Tags • Clean Reader", fill=(160, 160, 150), anchor="mm")

    # Subtle feature pills at bottom
    features = ["⚡ Quick Capture", "🔒 Privacy First", "🌐 Cross-Platform", "🌓 Dark Mode"]
    start_x = 220
    for f_text in features:
        fg_draw.rounded_rectangle([start_x, 420, start_x + 130, 456], radius=18, fill=(35, 35, 30), outline=(60, 60, 50))
        fg_draw.text((start_x + 65, 438), f_text, fill=(231, 255, 87), anchor="mm")
        start_x += 150

    fg.save(os.path.join(output_dir, "feature_graphic_1024x500.png"), "PNG")

    # Helper function to generate sleek phone screenshots (1080 x 1920)
    def create_screenshot(filename, title, subtitle, accent_badge, render_ui_type):
        ss = Image.new("RGB", (1080, 1920), (18, 18, 15))
        ss_draw = ImageDraw.Draw(ss)
        
        # Subtle ambient top glow
        ss_draw.ellipse([140, -200, 940, 400], fill=(28, 34, 22))

        # Top Badge
        ss_draw.rounded_rectangle([390, 80, 690, 136], radius=28, fill=(231, 255, 87))
        ss_draw.text((540, 108), accent_badge, fill=(23, 23, 17), anchor="mm")

        # Headline
        ss_draw.text((540, 190), title, fill=(255, 255, 255), anchor="mm")
        # Subtitle
        ss_draw.text((540, 250), subtitle, fill=(161, 161, 154), anchor="mm")

        # Phone Frame (Mockup Frame)
        card_x1, card_y1, card_x2, card_y2 = 120, 330, 960, 1860
        # Phone shadow
        ss_draw.rounded_rectangle([card_x1 - 10, card_y1 - 10, card_x2 + 10, card_y2 + 10], radius=54, fill=(8, 8, 6))
        # Phone body
        ss_draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=48, fill=(23, 23, 17), outline=(50, 50, 44), width=3)
        
        # Phone Notch / Dynamic Island
        ss_draw.rounded_rectangle([450, card_y1 + 18, 630, card_y1 + 48], radius=15, fill=(12, 12, 10))

        # App Header inside Phone
        app_head_y = card_y1 + 75
        # App logo mark inside phone
        if os.path.exists(icon_white_path):
            mini_icon = Image.open(icon_white_path).convert("RGBA").resize((40, 40), Image.Resampling.LANCZOS)
            ss.paste(mini_icon, (card_x1 + 40, app_head_y), mini_icon)
        ss_draw.text((card_x1 + 95, app_head_y + 20), "laterbox", fill=(255, 255, 255), anchor="lm")
        # Sync dot
        ss_draw.ellipse([card_x2 - 80, app_head_y + 12, card_x2 - 64, app_head_y + 28], fill=(231, 255, 87))

        # Render specific mock UI content
        content_y = app_head_y + 70
        if render_ui_type == "inbox":
            # Search Bar
            ss_draw.rounded_rectangle([card_x1 + 36, content_y, card_x2 - 36, content_y + 60], radius=16, fill=(35, 35, 28))
            ss_draw.text((card_x1 + 60, content_y + 30), "🔍 Search laterbox...", fill=(161, 161, 154), anchor="lm")
            
            # Tags filter row
            tag_y = content_y + 85
            tags = ["All Items", "Articles", "Design", "Tech", "Videos"]
            tx = card_x1 + 36
            for idx, tag in enumerate(tags):
                bg_c = (231, 255, 87) if idx == 0 else (35, 35, 28)
                fg_c = (23, 23, 17) if idx == 0 else (200, 200, 190)
                ss_draw.rounded_rectangle([tx, tag_y, tx + 130, tag_y + 44], radius=22, fill=bg_c)
                ss_draw.text((tx + 65, tag_y + 22), tag, fill=fg_c, anchor="mm")
                tx += 145

            # Item Cards
            card_items = [
                ("Designing for Spatial Computing", "apple.developer.com • 8 min read", "Tech", (231, 255, 87)),
                ("State Management in Flutter with Riverpod", "flutter.dev • 5 min read", "Flutter", (90, 200, 250)),
                ("The Architecture of Modern Databases", "highscalability.com • 12 min read", "Architecture", (255, 149, 0)),
                ("Minimalist UI Design Principles for 2026", "uxdesign.cc • 6 min read", "Design", (175, 82, 222)),
                ("Understanding Vector Indexes & Embeddings", "arxiv.org • 15 min read", "AI", (52, 199, 89))
            ]
            item_y = tag_y + 75
            for title_text, meta_text, tag_label, tag_color in card_items:
                ss_draw.rounded_rectangle([card_x1 + 36, item_y, card_x2 - 36, item_y + 190], radius=20, fill=(32, 32, 25), outline=(48, 48, 40))
                # Preview thumbnail box
                ss_draw.rounded_rectangle([card_x1 + 56, item_y + 25, card_x1 + 196, item_y + 165], radius=14, fill=(48, 54, 38))
                ss_draw.text((card_x1 + 126, item_y + 95), "🔗", fill=(255, 255, 255), anchor="mm")
                
                # Title & meta
                ss_draw.text((card_x1 + 220, item_y + 40), title_text[:30] + "...", fill=(255, 255, 255), anchor="lm")
                ss_draw.text((card_x1 + 220, item_y + 80), meta_text, fill=(161, 161, 154), anchor="lm")
                # Tag pill
                ss_draw.rounded_rectangle([card_x1 + 220, item_y + 115, card_x1 + 330, item_y + 155], radius=12, fill=(45, 45, 36))
                ss_draw.text((card_x1 + 275, item_y + 135), tag_label, fill=tag_color, anchor="mm")
                
                item_y += 215

        elif render_ui_type == "capture":
            # Quick capture card
            ss_draw.rounded_rectangle([card_x1 + 36, content_y + 40, card_x2 - 36, content_y + 540], radius=24, fill=(32, 32, 25), outline=(231, 255, 87), width=2)
            ss_draw.text((card_x1 + 70, content_y + 90), "Quick Capture", fill=(255, 255, 255), anchor="lm")
            
            # Input field mockup
            ss_draw.rounded_rectangle([card_x1 + 70, content_y + 130, card_x2 - 70, content_y + 230], radius=16, fill=(23, 23, 17))
            ss_draw.text((card_x1 + 95, content_y + 165), "https://github.com/flutter/flutter", fill=(231, 255, 87), anchor="lm")
            ss_draw.text((card_x1 + 95, content_y + 200), "Flutter engine architecture reference", fill=(161, 161, 154), anchor="lm")
            
            # Tags selection
            ss_draw.text((card_x1 + 70, content_y + 270), "Select Tags:", fill=(200, 200, 190), anchor="lm")
            tx = card_x1 + 70
            for tag in ["#Dev", "#Flutter", "#OpenSource"]:
                ss_draw.rounded_rectangle([tx, content_y + 300, tx + 160, content_y + 350], radius=16, fill=(231, 255, 87))
                ss_draw.text((tx + 80, content_y + 325), tag, fill=(23, 23, 17), anchor="mm")
                tx += 180

            # Save Button
            ss_draw.rounded_rectangle([card_x1 + 70, content_y + 400, card_x2 - 70, content_y + 490], radius=20, fill=(231, 255, 87))
            ss_draw.text((540, content_y + 445), "Save to laterbox ⚡", fill=(23, 23, 17), anchor="mm")

            # Notification popup simulation
            pop_y = content_y + 600
            ss_draw.rounded_rectangle([card_x1 + 36, pop_y, card_x2 - 36, pop_y + 140], radius=20, fill=(23, 23, 17), outline=(60, 60, 50))
            ss_draw.text((card_x1 + 70, pop_y + 50), "✅ Saved to laterbox", fill=(255, 255, 255), anchor="lm")
            ss_draw.text((card_x1 + 70, pop_y + 90), "Syncing to all devices in background", fill=(161, 161, 154), anchor="lm")

        elif render_ui_type == "reader":
            # Clean article reader
            ss_draw.text((card_x1 + 50, content_y + 40), "Designing for Spatial Computing", fill=(255, 255, 255), anchor="lm")
            ss_draw.text((card_x1 + 50, content_y + 85), "apple.developer.com • Published Aug 2026", fill=(161, 161, 154), anchor="lm")
            
            # Action icons (Bookmark, Share, Font size, Dark mode)
            ss_draw.rounded_rectangle([card_x1 + 50, content_y + 120, card_x2 - 50, content_y + 175], radius=14, fill=(35, 35, 28))
            ss_draw.text((540, content_y + 148), "🔤 Aa   •   ⭐ Favorite   •   📤 Share   •   🌙 Theme", fill=(231, 255, 87), anchor="mm")

            # Article paragraphs simulation
            text_lines = [
                "Spatial computing blends physical and digital worlds seamlessly.",
                "When designing spatial interfaces, typography scale, depth cues,",
                "and contrast are paramount to ensuring effortless legibility.",
                "",
                "Key Design Principles:",
                "1. Maintain comfortable reading distance and field of view.",
                "2. Dynamic lighting reflects ambient surroundings.",
                "3. Subtle motion enhances navigation without fatigue.",
                "",
                "Immersive Audio and Visual Integration:",
                "Spatial audio provides contextual cues to guide user attention",
                "naturally across interface elements."
            ]
            para_y = content_y + 220
            for line in text_lines:
                if line.startswith("Key Design") or line.startswith("Immersive Audio"):
                    ss_draw.text((card_x1 + 50, para_y), line, fill=(231, 255, 87), anchor="lm")
                else:
                    ss_draw.text((card_x1 + 50, para_y), line, fill=(220, 220, 215), anchor="lm")
                para_y += 48

        elif render_ui_type == "sync":
            # Offline & Multi-Device Sync View
            ss_draw.rounded_rectangle([card_x1 + 36, content_y + 30, card_x2 - 36, content_y + 360], radius=24, fill=(32, 32, 25), outline=(231, 255, 87))
            ss_draw.text((card_x1 + 70, content_y + 80), "Real-Time Cloud Sync", fill=(255, 255, 255), anchor="lm")
            ss_draw.text((card_x1 + 70, content_y + 125), "Instant sync across all your devices", fill=(161, 161, 154), anchor="lm")

            devices = [
                ("📱 iPhone & iPad", "Synced just now", (52, 199, 89)),
                ("💻 macOS & Windows Desktop", "Synced 2m ago", (52, 199, 89)),
                ("🌐 Web App & Browser Extensions", "Live connection active", (231, 255, 87)),
            ]
            dev_y = content_y + 175
            for dev_name, dev_status, status_color in devices:
                ss_draw.rounded_rectangle([card_x1 + 60, dev_y, card_x2 - 60, dev_y + 75], radius=16, fill=(23, 23, 17))
                ss_draw.text((card_x1 + 85, dev_y + 38), dev_name, fill=(255, 255, 255), anchor="lm")
                ss_draw.text((card_x2 - 85, dev_y + 38), dev_status, fill=status_color, anchor="rm")
                dev_y += 90

            # Offline Capability Feature Box
            off_y = content_y + 400
            ss_draw.rounded_rectangle([card_x1 + 36, off_y, card_x2 - 36, off_y + 260], radius=24, fill=(23, 23, 17), outline=(50, 50, 44))
            ss_draw.text((card_x1 + 70, off_y + 60), "✈️ Full Offline Access", fill=(231, 255, 87), anchor="lm")
            ss_draw.text((card_x1 + 70, off_y + 110), "Read saved articles, view notes, and save new items", fill=(220, 220, 215), anchor="lm")
            ss_draw.text((card_x1 + 70, off_y + 150), "even without an internet connection. Changes sync", fill=(220, 220, 215), anchor="lm")
            ss_draw.text((card_x1 + 70, off_y + 190), "automatically when you're back online.", fill=(220, 220, 215), anchor="lm")

        ss.save(os.path.join(output_dir, filename), "PNG")
        print(f"📱 Generated {filename} (1080x1920)")

    print("🎨 Generating 4 phone screenshots...")
    create_screenshot("screenshot_1_inbox.png", "Save Anything Now", "Articles, links, notes, and media organized in one place", "ALL-IN-ONE INBOX", "inbox")
    create_screenshot("screenshot_2_capture.png", "Instant Quick Capture", "Save with a single tap from any app or browser", "ONE-CLICK SAVE", "capture")
    create_screenshot("screenshot_3_reader.png", "Distraction-Free Reading", "Clean typography, dark mode, and customizable layouts", "CLEAN READER", "reader")
    create_screenshot("screenshot_4_sync.png", "Offline-First & Cloud Sync", "Access your library anywhere, sync seamlessly across devices", "REAL-TIME SYNC", "sync")

    print(f"✅ All Google Play assets generated in: {output_dir}")

if __name__ == "__main__":
    main()
