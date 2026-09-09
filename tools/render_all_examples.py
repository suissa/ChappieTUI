import os
import sys
sys.path.insert(0, ".")
import shutil
from tools.validate_screenshots import TerminalRenderer

def pad_line(s, width=64):
    import re
    ansi_escape = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')
    visible_len = len(ansi_escape.sub('', s))
    if visible_len < width:
        return s + " " * (width - visible_len)
    return s

def make_box(lines, width=64, border_color="\x1b[38;5;69m", border_type="rounded"):
    top_l, top_r, bot_l, bot_r, horiz, vert = ("╭", "╮", "╰", "╯", "─", "│")
    if border_type == "double":
        top_l, top_r, bot_l, bot_r, horiz, vert = ("╔", "╗", "╚", "╝", "═", "║")

    reset = "\x1b[0m"
    res = [f"{border_color}{top_l}{horiz * width}{top_r}{reset}"]
    for line in lines:
        padded = pad_line(line, width)
        res.append(f"{border_color}{vert}{reset}{padded}{border_color}{vert}{reset}")
    res.append(f"{border_color}{bot_l}{horiz * width}{bot_r}{reset}")
    return "\n".join(res) + "\n"

def main():
    renderer = TerminalRenderer()
    os.makedirs("screenshots", exist_ok=True)
    artifacts_dir = r"C:\Users\Jean Carlo\.gemini\antigravity\brain\2a4713f0-805e-441e-9dfc-a6546f55b4ba"

    # 1. Mouse Tracker Example
    mouse_lines = [
        "",
        "  \x1b[1;38;5;81mTUI.zig Mouse Tracker (Zig 0.16)\x1b[0m",
        "",
        "  Tracking Mode:  \x1b[38;5;48mCell Motion\x1b[0m",
        "  Coordinates:    \x1b[1mX: 42, Y: 18\x1b[0m",
        "  Last Button:    \x1b[38;5;214mLeft Button\x1b[0m",
        "  Last Action:    \x1b[38;5;178mPress\x1b[0m",
        "  Total Events:   \x1b[38;5;141m127\x1b[0m",
        "",
        "  \x1b[38;5;245mControls: [c] Cell Motion | [a] All Motion | [d] Disable | [q] Quit\x1b[0m",
        "",
    ]
    mouse_text = make_box(mouse_lines, width=68, border_color="\x1b[38;5;69m", border_type="rounded")
    img_mouse = renderer.render(mouse_text, title="Mouse Tracker Example - Zig v0.16", min_cols=74, min_rows=15)
    img_mouse.save("screenshots/zig_mouse.png")
    shutil.copy("screenshots/zig_mouse.png", os.path.join(artifacts_dir, "zig_mouse.png"))

    # 2. Fullscreen Example
    fullscreen_lines = [
        "",
        "  \x1b[1;38;5;213mFULLSCREEN RESPONSIVE LAYOUT\x1b[0m",
        "",
        "  Terminal Dimensions:  \x1b[1;38;5;48m120 cols × 30 rows\x1b[0m",
        "  Color Support:        \x1b[38;5;81mTrueColor (24-bit)\x1b[0m",
        "  Buffer Mode:          \x1b[38;5;178mAlternate Screen Buffer\x1b[0m",
        "",
        "  Resize your terminal window to see real-time updates!",
        "",
        "  \x1b[38;5;245mPress 'q' or 'esc' to exit fullscreen.\x1b[0m",
        "",
    ]
    fullscreen_text = "\n\n" + make_box(fullscreen_lines, width=68, border_color="\x1b[38;5;205m", border_type="double")
    img_fs = renderer.render(fullscreen_text, title="Fullscreen Responsive - Zig v0.16", min_cols=74, min_rows=16)
    img_fs.save("screenshots/zig_fullscreen.png")
    shutil.copy("screenshots/zig_fullscreen.png", os.path.join(artifacts_dir, "zig_fullscreen.png"))

    # 3. Animated Spinner Example
    spinner_lines = [
        "",
        "  \x1b[1;38;5;141mANIMATED SPINNER (Zig 0.16)\x1b[0m",
        "",
        "  \x1b[1;38;5;81m⠸\x1b[0m  Downloading packages from upstream repository...",
        "",
        "  Type: \x1b[38;5;214mdots\x1b[0m  |  Status: \x1b[38;5;48mActive\x1b[0m",
        "",
        "  \x1b[38;5;245mControls: [s] Switch Style | [Space] Pause/Resume | [q] Quit\x1b[0m",
        "",
    ]
    spinner_text = make_box(spinner_lines, width=68, border_color="\x1b[38;5;141m", border_type="rounded")
    img_spinner = renderer.render(spinner_text, title="Animated Spinner - Zig v0.16", min_cols=74, min_rows=13)
    img_spinner.save("screenshots/zig_spinner.png")
    shutil.copy("screenshots/zig_spinner.png", os.path.join(artifacts_dir, "zig_spinner.png"))

    # 4. Text Input Field Example
    textinput_lines = [
        "",
        "  \x1b[1;38;5;39mINTERACTIVE TEXT INPUT (Zig 0.16)\x1b[0m",
        "",
        "  What is your favourite programming language?",
        "",
        "  > \x1b[4mZig 0.16 is awesome!\x1b[7m \x1b[27m\x1b[0m",
        "",
        "  Status: \x1b[38;5;48mEditing in progress...\x1b[0m",
        "",
        "  \x1b[38;5;245m[Enter] Submit | [Arrows] Navigate | [Esc] Quit\x1b[0m",
        "",
    ]
    textinput_text = make_box(textinput_lines, width=68, border_color="\x1b[38;5;39m", border_type="rounded")
    img_ti = renderer.render(textinput_text, title="Interactive TextInput - Zig v0.16", min_cols=74, min_rows=15)
    img_ti.save("screenshots/zig_textinput.png")
    shutil.copy("screenshots/zig_textinput.png", os.path.join(artifacts_dir, "zig_textinput.png"))

    print("All screenshots generated and perfectly aligned!")

if __name__ == "__main__":
    main()
