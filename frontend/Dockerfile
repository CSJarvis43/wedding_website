# Local development image. Source is bind-mounted by docker-compose.yml;
# node_modules stays in the container (an anonymous volume) so the host's never shadows it.
FROM node:24-slim

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

EXPOSE 3000
CMD ["pnpm", "dev"]
