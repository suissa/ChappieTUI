import os
import re
import sys
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

sys.stdout.reconfigure(encoding='utf-8')

class TerminalRenderer:
    def __init__(self, font_path="C:/Windows/Fonts/consola.ttf", font_size=16):
        try:
            self.font = ImageFont.truetype(font_path, font_size)
            self.bold_font = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", font_size)
        except Exception:
            self.font = ImageFont.load_default()
            self.bold_font = self.font

        dummy = Image.new("RGB", (100, 100))
        d = ImageDraw.Draw(dummy)
        bbox = d.textbbox((0, 0), "M", font=self.font)
        self.char_w = max(bbox[2] - bbox[0], 9)
        self.char_h = max(bbox[3] - bbox[1] + 6, 20)

        self.palette = {
            30: (0, 0, 0),
            31: (205, 49, 49),
            32: (13, 188, 121),
            33: (229, 229, 16),
            34: (36, 114, 200),
            35: (188, 63, 188),
            36: (17, 168, 205),
            37: (229, 229, 229),
            90: (102, 102, 102),
            91: (241, 76, 76),
            92: (35, 209, 139),
            93: (245, 245, 67),
            94: (59, 142, 234),
            95: (214, 112, 214),
            96: (41, 184, 219),
            97: (255, 255, 255),
        }

    def parse_ansi(self, text):
        lines = text.split("\n")
        parsed_lines = []
        ansi_regex = re.compile(r"\x1b\[([0-9;]*)m")

        cur_fg = (220, 220, 220)
        cur_bg = None
        cur_bold = False

        for line in lines:
            pos = 0
            tokens = []
            while pos < len(line):
                m = ansi_regex.search(line, pos)
                if not m:
                    tokens.append({"text": line[pos:], "fg": cur_fg, "bg": cur_bg, "bold": cur_bold})
                    break

                if m.start() > pos:
                    tokens.append({"text": line[pos:m.start()], "fg": cur_fg, "bg": cur_bg, "bold": cur_bold})

                code_str = m.group(1)
                codes = [int(c) for c in code_str.split(";") if c.isdigit()] if code_str else [0]
                idx = 0
                while idx < len(codes):
                    c = codes[idx]
                    if c == 0:
                        cur_fg = (220, 220, 220)
                        cur_bg = None
                        cur_bold = False
                    elif c == 1:
                        cur_bold = True
                    elif c in self.palette:
                        cur_fg = self.palette[c]
                    elif c == 38 and idx + 4 < len(codes) and codes[idx + 1] == 2:
                        cur_fg = (codes[idx + 2], codes[idx + 3], codes[idx + 4])
                        idx += 4
                    elif c == 48 and idx + 4 < len(codes) and codes[idx + 1] == 2:
                        cur_bg = (codes[idx + 2], codes[idx + 3], codes[idx + 4])
                        idx += 4
                    idx += 1
                pos = m.end()

            parsed_lines.append(tokens)
        return parsed_lines

    def render(self, text, title="Terminal", cols=62, rows=5):
        parsed_lines = self.parse_ansi(text)

        padding_x = 24
        padding_top = 44
        padding_bottom = 20

        width = cols * self.char_w + padding_x * 2
        height = rows * self.char_h + padding_top + padding_bottom

        img = Image.new("RGB", (width, height), (24, 24, 37))
        draw = ImageDraw.Draw(img)

        # Title bar background
        draw.rectangle([0, 0, width, 34], fill=(30, 30, 46))
        draw.line([0, 34, width, 34], fill=(49, 50, 68), width=1)

        # macOS / modern buttons
        draw.ellipse([14, 11, 24, 21], fill=(243, 139, 168))  # Red
        draw.ellipse([32, 11, 42, 21], fill=(249, 226, 175))  # Yellow
        draw.ellipse([50, 11, 60, 21], fill=(166, 227, 161))  # Green

        # Centered title
        t_bbox = draw.textbbox((0, 0), title, font=self.font)
        t_w = t_bbox[2] - t_bbox[0]
        draw.text(((width - t_w) // 2, 8), title, fill=(186, 194, 222), font=self.font)

        # Render lines
        y = padding_top
        for pl in parsed_lines:
            x = padding_x
            for tok in pl:
                s = tok["text"]
                fg = tok["fg"]
                bg = tok["bg"]
                font = self.bold_font if tok["bold"] else self.font

                for char in s:
                    bbox = draw.textbbox((0, 0), char, font=font)
                    cw = max(bbox[2] - bbox[0], self.char_w)
                    if bg:
                        draw.rectangle([x, y, x + cw, y + self.char_h], fill=bg)
                    draw.text((x, y), char, fill=fg, font=font)
                    x += self.char_w
            y += self.char_h

        return img


def main():
    print("1. Running render-progress-frames.exe to get animation frames...")
    proc = subprocess.run(["zig-out/bin/render-progress-frames.exe"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    output = proc.stderr if proc.stderr else proc.stdout

    raw_frames = output.split("FRAME_START")
    frames_text = []
    for f in raw_frames:
        if "FRAME_END" in f:
            t = f.split("FRAME_END")[0].strip("\r\n")
            frames_text.append(t)

    print(f"Captured {len(frames_text)} frames.")

    renderer = TerminalRenderer()
    rendered_images = []

    print("2. Rendering frames to PIL images...")
    for idx, f_text in enumerate(frames_text):
        img = renderer.render(f_text, title="Chappie TUI - Gradient Progress Bar", cols=60, rows=5)
        rendered_images.append(img)

    os.makedirs("screenshots", exist_ok=True)
    gif_path = "screenshots/progress_animated.gif"
    webp_path = "screenshots/progress_animated.webp"

    print("3. Saving animated GIF and WebP...")
    # Quantize for high-quality palette GIF
    paletted_frames = []
    for img in rendered_images:
        # Quantize to 256 colors adaptive palette
        paletted_frames.append(img.quantize(colors=256, method=Image.Quantize.MEDIANCUT))

    paletted_frames[0].save(
        gif_path,
        save_all=True,
        append_images=paletted_frames[1:],
        duration=40,
        loop=0,
        optimize=True
    )
    print(f"  [OK] Saved GIF: {gif_path} ({os.path.getsize(gif_path) / 1024:.1f} KB)")

    # WebP (supports 24-bit TrueColor animation natively)
    rendered_images[0].save(
        webp_path,
        format="WEBP",
        save_all=True,
        append_images=rendered_images[1:],
        duration=40,
        loop=0,
        quality=95
    )
    print(f"  [OK] Saved WebP: {webp_path} ({os.path.getsize(webp_path) / 1024:.1f} KB)")

    # Copy to artifact directory
    artifact_dir = r"C:\Users\Jean Carlo\.gemini\antigravity\brain\2a4713f0-805e-441e-9dfc-a6546f55b4ba"
    shutil.copy(gif_path, os.path.join(artifact_dir, "progress_animated.gif"))
    shutil.copy(webp_path, os.path.join(artifact_dir, "progress_animated.webp"))
    print(f"  [OK] Copied to artifact directory: {artifact_dir}")

    # Upload to litterbox
    print("4. Uploading to public host (litterbox)...")
    for filepath in [gif_path, webp_path]:
        try:
            cmd = [
                "curl", "-s",
                "-F", "reqtype=fileupload",
                "-F", "time=72h",
                "-F", f"fileToUpload=@{filepath}",
                "https://litterbox.catbox.moe/resources/internals/api.php"
            ]
            res = subprocess.run(cmd, capture_output=True, text=True)
            url = res.stdout.strip()
            print(f"  Uploaded {os.path.basename(filepath)} -> {url}")
        except Exception as e:
            print(f"  Upload failed for {filepath}: {e}")

if __name__ == "__main__":
    main()
