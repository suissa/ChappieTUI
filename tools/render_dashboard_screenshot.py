import os
import sys
sys.path.insert(0, ".")
from tools.validate_screenshots import TerminalRenderer

def main():
    renderer = TerminalRenderer()

    # The exact string from examples/dashboard.zig:
    text = (
        "\x1b[38;5;69m╭──────────────────────────────────────────────────────────────────────────╮\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;81mCHAPPIE SYSTEM DASHBOARD (Zig v0.16)\x1b[0m       \x1b[38;5;245mUptime: 02m 22s | Multi-OS\x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m├────────────────────────┬────────────────────────┬────────────────────────┤\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[1mCPU CORE\x1b[0m               \x1b[38;5;69m│\x1b[0m \x1b[1mRAM MEMORY\x1b[0m             \x1b[38;5;69m│\x1b[0m \x1b[1mNETWORK TRAFFIC\x1b[0m        \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m [####------] \x1b[38;5;48m42%\x1b[0m        \x1b[38;5;69m│\x1b[0m [#####-----] \x1b[38;5;178m58%\x1b[0m        \x1b[38;5;69m│\x1b[0m IN   18.2 MB/s        \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[38;5;245mLoad: 1.45 1.62 1.80\x1b[0m   \x1b[38;5;69m│\x1b[0m \x1b[38;5;245m19.8 GB / 32.0 GB\x1b[0m      \x1b[38;5;69m│\x1b[0m OUT   4.1 MB/s        \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m├────────────────────────┴────────────────────────┴────────────────────────┤\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;250mSTATUS   SERVICE             PORT    LATENCY   UPTIME    ACTIONS         \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m├──────────────────────────────────────────────────────────────────────────┤\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[7;38;5;69m> Active  API Gateway        8080       4ms     99.98%   [Toggle:s] \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m   Active  Postgres DB        5432       1ms     99.99%   [Toggle:s]  \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m   Active  Redis Cache        6379       1ms     100.0%   [Toggle:s]  \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m   Active  Auth Service       4000      14ms     99.85%   [Toggle:s]  \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m   Paused  Worker Pool        9000       0ms     98.20%   [Toggle:s]  \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m   Active  Storage S3         9002      28ms     99.95%   [Toggle:s]  \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m├──────────────────────────────────────────────────────────────────────────┤\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[1;38;5;250mLIVE EVENT LOGS                                                          \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[38;5;244m[09:25:01]\x1b[0m \x1b[38;5;69m[INFO]\x1b[0m \x1b[38;5;253mGateway health check OK: all 6 endpoints responsive   \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[38;5;244m[09:25:04]\x1b[0m \x1b[38;5;214m[WARN]\x1b[0m \x1b[38;5;253mWorker pool scaled down: 2 idle executors evicted     \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[38;5;244m[09:25:08]\x1b[0m \x1b[38;5;82m[OK  ]\x1b[0m \x1b[38;5;253mPostgres auto-vacuum completed: 1,420 rows cleaned    \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m│\x1b[0m \x1b[38;5;244m[09:25:12]\x1b[0m \x1b[38;5;69m[INFO]\x1b[0m \x1b[38;5;253mRedis hit-ratio 99.4% in 15m monitoring window        \x1b[0m \x1b[38;5;69m│\x1b[0m\n"
        "\x1b[38;5;69m╰──────────────────────────────────────────────────────────────────────────╯\x1b[0m\n"
        "  \x1b[1;38;5;245mUP/DOWN/j/k:\x1b[0m Move   \x1b[1;38;5;245mSpace/s:\x1b[0m Toggle Service   \x1b[1;38;5;245mr:\x1b[0m Reset   \x1b[1;38;5;245mq:\x1b[0m Quit\n"
    )

    img = renderer.render(text, title="Chappie System Dashboard - Zig v0.16", min_cols=78, min_rows=24)
    img.save("screenshots/dashboard.png")
    print("Dashboard screenshot updated in screenshots/dashboard.png")

if __name__ == "__main__":
    main()
