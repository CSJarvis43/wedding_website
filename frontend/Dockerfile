# Local development image. Source is bind-mounted by docker-compose.yml;
# node_modules stays in the container (an anonymous volume) so the host's never shadows it.
FROM node:24.22.0-slim

# Keep pnpm's store in the image, not in the bind-mounted source tree.
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    npm_config_store_dir=/pnpm-store
RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

EXPOSE 3000
# Re-install on start so dependency changes reach the persisted node_modules volume.
CMD ["sh", "-c", "pnpm install --frozen-lockfile --config.confirmModulesPurge=false && pnpm dev"]
