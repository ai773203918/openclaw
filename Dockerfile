# 使用 Node.js 24 的 slim 版本作为基础(官方要求22+)
FROM node:24.2.0-slim

# 定义 OpenClaw 版本 (构建时传入)
ARG OPENCLAW_VERSION=2026.4.1

# 环境基础准备 (换源、装工具、设镜像)
RUN set -x && \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    npm config set registry https://registry.npmmirror.com && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# 安装 OpenClaw (独立层)
RUN set -x && \
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | \
    bash -s -- --no-prompt --no-onboard -v ${OPENCLAW_VERSION} && \
    openclaw doctor --fix && \
    rm -rf /root/.npm

EXPOSE 18789
VOLUME /root/.openclaw

# ==========================================
# 创建一个启动脚本
# ==========================================
RUN echo '#!/bin/sh\n\
while true; do\n\
  echo "[$(date)] Starting OpenClaw Gateway..."\n\
  # 启动 gateway，允许无配置启动\n\
  openclaw gateway --allow-unconfigured\n\
  # 如果退出了，等待 5 秒后重启（防止错误死循环）\n\
  echo "[$(date)] OpenClaw Gateway exited. Restarting in 5s..."\n\
  sleep 5\n\
done' > /entrypoint.sh && chmod +x /entrypoint.sh

# 使用脚本作为主进程，保证容器不退出
CMD ["/entrypoint.sh"]