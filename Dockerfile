# 使用 Node.js 24 的 slim 版本作为基础(官方要求22+)
FROM node:24.2.0-slim

# 定义 OpenClaw 版本 (构建时传入)
ARG OPENCLAW_VERSION=2026.4.1

# 环境基础准备 (换源、装工具、设镜像)
# 这一步只要不变，Docker 永远使用缓存，极快
RUN set -x && \
    # --- 换源 --- \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true && \
    # --- 安装基础依赖 --- \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    # --- 设置 NPM 镜像 --- \
    npm config set registry https://registry.npmmirror.com && \
    # --- 清理 apt 缓存 (这层只清理 apt，不清理 npm，因为 npm 可能会被下一层用到，但通常全局安装后也可以清) --- \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# 安装 OpenClaw (独立层)
# 当 ARG OPENCLAW_VERSION 变化时，重新执行此层；否则命中缓存
RUN set -x && \
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | \
    bash -s -- --no-prompt --no-onboard -v ${OPENCLAW_VERSION} && \
    # 安装完清理 npm 缓存，减小最终镜像体积
    rm -rf /root/.npm

EXPOSE 18789
VOLUME /root/.openclaw

CMD ["openclaw", "gateway"]