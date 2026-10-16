<p align="center">
  <img width="1672" height="941" alt="image" src="https://github.com/user-attachments/assets/3f96d29c-05dd-4467-a8aa-1fbed168e003" />

</p>

**ChappieTUI** é uma biblioteca/framework moderna, rápida e expressiva para desenvolvimento de interfaces de terminal (TUI) em **Zig 0.16**, baseada nos paradigmas funcionais e reativos da **The Elm Architecture** (inspirado no Charm Bubble Tea e Lipgloss).

Inclui o submódulo integrado **Lipgloss** para estilização com TrueColor (RGB 24-bit), gradientes, tabelas, árvores de renderização e layouts responsivos.

---

## ⚡ Destaques

- 🚀 **100% Zig 0.16 Nativo**: Sem dependências externas ou C-runtime exigidas.
- 🎨 **Lipgloss Submodule**: Gradientes RGB (`#5A56E0` ➔ `#EE6FF8`), bordas decorativas, padding, margin e alinhamento.
- 🧩 **Arquitetura Elm (MVU)**: `Model`, `init()`, `update(Msg) Cmd` e `view() View`.
- 📊 **Componentes Inclusos**:
  - `lipgloss.Progress`: Barras de progresso com gradiente e blocos fracionários suaves (`▏▎▍▌▋▊▉█`).
  - `lipgloss.Table`: Tabelas estilizadas com cabeçalhos e zebrados.
  - `lipgloss.Tree`: Árvores estruturadas.
  - `lipgloss.JoinHorizontal` / `JoinVertical`: Compositor de layout.
  - `TextInput`, `Spinner`, `Tabs`, `Mouse`, `Fullscreen`.
- 🖥️ **Multi-Plataforma**: Compatível com Windows (ConPTY / Win32 console API), Linux e macOS.

---

## 📦 Como Usar

### 1. Adicionar ao `build.zig.zon`

```zig
.{
    .name = .meu_projeto,
    .version = "0.1.0",
    .dependencies = .{
        .tui = .{
            .url = "https://github.com/suissadev/ChappieTUI/archive/main.tar.gz",
            // .hash = "...",
        },
    },
}
```

### 2. Importar no `build.zig`

```zig
const tui_dep = b.dependency("tui", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("tui", tui_dep.module("tui"));
exe.root_module.addImport("lipgloss", tui_dep.module("lipgloss"));
```

---

## 💡 Exemplo Rápido

```zig
const std = @import("std");
const tui = @import("tui");
const lipgloss = @import("lipgloss");

const Model = struct {
    ticks: usize = 0,

    pub fn init(self: Model) tui.Cmd {
        _ = self;
        return tui.none();
    }

    pub fn update(self: *Model, msg: tui.Msg) tui.Cmd {
        switch (msg) {
            .key => |k| {
                if (k.code == .char and k.char == 'q') {
                    return tui.quit();
                }
            },
            else => {},
        }
        return tui.none();
    }

    pub fn view(self: Model, allocator: std.mem.Allocator) !tui.View {
        var buf = tui.Buffer.init(allocator);

        const style = lipgloss.newStyle()
            .bold(true)
            .foreground(lipgloss.Color.hex("#FAFAFA"))
            .background(lipgloss.Color.hex("#7D56F4"))
            .padding(1, 2, 1, 2);

        const banner = try style.render(allocator, "Olá, ChappieTUI!");
        defer allocator.free(banner);

        try buf.writeAll(banner);
        try buf.writeAll("\n\nPressione 'q' para sair.\n");

        return tui.View.init(try buf.toOwnedSlice());
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var p = tui.Program(Model).init(allocator, Model{});
    defer p.deinit();

    _ = try p.run();
}
```

---

## 🛠️ Executando os Exemplos

Você pode compilar e executar todos os exemplos nativos usando a CLI do **Zig 0.16**:

```bash
# Compilar todo o projeto
zig build

# Rodar os testes unitários
zig build test

# Exemplos interativos
zig build run-dashboard          # System Dashboard completo com métricas
zig build run-progress-animated  # Barra de progresso animada com gradiente\nzig build run-gradient-button    # Botão com FadeIn/FadeOut por gradiente e controle via scroll
zig build run-lipgloss-gallery   # Galeria de estilos Lipgloss
zig build run-lipgloss-table     # Tabelas estilizadas
zig build run-lipgloss-tree      # Árvores hierárquicas
zig build run-lipgloss-layout    # Compositor de layout horizontal/vertical
zig build run-spinner            # Spinners e indicadores de carregamento
zig build run-textinput          # Campo de texto interativo
zig build run-mouse              # Captura e rastreamento de eventos de mouse
zig build run-fullscreen         # Aplicação em tela cheia (AltScreen)
```


## Botão com FadeIn/FadeOut por gradiente

Execute `zig build run-gradient-button` para abrir um exemplo interativo de botão. O fundo começa usando a cor padrão do terminal; no FadeIn, o preenchimento colorido nasce no centro e se expande para as duas laterais. O FadeOut recolhe o gradiente das bordas em direção ao centro.

- `i` ou seta para cima: FadeIn animado.
- `o` ou seta para baixo: FadeOut animado.
- Roda do mouse para cima/baixo: controla diretamente o progresso da animação (scrubbing).
- Clique do mouse: ativa o botão quando totalmente revelado ou inicia o FadeIn.
- `q` ou `Ctrl+C`: sair.

A animação usa frames da arquitetura de mensagens da ChappieTUI e sequências ANSI TrueColor; não depende de um timer externo nem de um renderer de navegador.

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações.
