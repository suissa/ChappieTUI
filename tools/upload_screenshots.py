import os
import subprocess
import json

images = [
    ("comparison_lipgloss_gallery.png", "Lipgloss Gallery (Bordas, Cores, Lista)"),
    ("comparison_lipgloss_table.png", "Lipgloss Tabela de Microserviços"),
    ("comparison_lipgloss_tree.png", "Lipgloss Árvore de Diretórios"),
    ("comparison_lipgloss_layout.png", "Lipgloss Dashboard Multi-coluna"),
    ("comparison_tabs.png", "Tabs Component"),
    ("comparison_table.png", "Top Cities Table Component"),
    ("comparison_basics_initial.png", "Grocery List (Inicial)"),
    ("comparison_basics_selected.png", "Grocery List (Selecionado)"),
    ("comparison_commands.png", "HTTP Status Checker (Commands)"),
    ("dashboard.png", "Dashboard Completo Zig 0.16"),
    ("zig_textinput.png", "Text Input Interativo"),
    ("zig_spinner.png", "Spinner Animado"),
    ("zig_mouse.png", "Mouse Motion & Click Tracking"),
    ("zig_fullscreen.png", "Fullscreen AltScreen"),
    ("comparison_progress_gradients.png", "Gradient Progress Bars (Go vs Zig 0.16)"),
    ("zig_progress_gradients.png", "Gradient Progress Bars Zig 0.16"),
]

uploaded = {}

for filename, desc in images:
    path = os.path.join("screenshots", filename)
    if not os.path.exists(path):
        continue
    cmd = [
        "curl", "-s",
        "-F", "reqtype=fileupload",
        "-F", "time=72h",
        "-F", f"fileToUpload=@{path}",
        "https://litterbox.catbox.moe/resources/internals/api.php"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    url = res.stdout.strip()
    if url.startswith("http"):
        uploaded[filename] = {"url": url, "desc": desc}
        print(f"[OK] {filename} -> {url}")
    else:
        print(f"[FAIL] {filename}: {url} {res.stderr}")

with open("screenshots/uploaded_urls.json", "w", encoding="utf-8") as f:
    json.dump(uploaded, f, indent=2, ensure_ascii=False)
