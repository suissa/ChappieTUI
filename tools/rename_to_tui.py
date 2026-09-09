import os

# 1. Update build.zig.zon
with open('build.zig.zon', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('.name = .chappie_tui,', '.name = .tui_zig,')
with open('build.zig.zon', 'w', encoding='utf-8') as f:
    f.write(c)

# 2. Update build.zig
with open('build.zig', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('addModule("chappie"', 'addModule("tui"')
c = c.replace('.name = "chappie"', '.name = "tui"')
c = c.replace('addImport("chappie"', 'addImport("tui"')
c = c.replace('examples_zig/', 'examples/')
c = c.replace('examples/dashboard.zig', 'examples/dashboard/main.zig')
with open('build.zig', 'w', encoding='utf-8') as f:
    f.write(c)

# 3. Update all .zig files in project
count = 0
for root, dirs, files in os.walk('.'):
    if '.git' in root or '.zig-cache' in root or 'zig-out' in root:
        continue
    for file in files:
        if file.endswith('.zig'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content.replace('@import("chappie")', '@import("tui")')
            new_content = new_content.replace('chappie.', 'tui.')
            new_content = new_content.replace('const chappie =', 'const tui =')
            new_content = new_content.replace('CHAPPIE', 'TUI.zig')
            new_content = new_content.replace('Chappie', 'TUI.zig')
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1

print(f"Updated {count} Zig files.")
