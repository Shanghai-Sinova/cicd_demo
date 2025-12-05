FROM node:25-alpine AS base
ENV PNPM_HOME=/root/.local/share/pnpm \
    PATH="$PNPM_HOME:$PATH"
RUN corepack enable
RUN npm config set registry https://registry.npmmirror.com \\
    && pnpm config set registry https://registry.npmmirror.com
WORKDIR /app
COPY package.json tsconfig.json tanstack.config.ts .npmrc pnpm-lock.yaml* ./
COPY app ./app
RUN pnpm install --frozen-lockfile || pnpm install
RUN pnpm run build

FROM node:22-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
COPY --from=base /app/dist ./dist
EXPOSE 5003
CMD ["node", "dist/server.js"]
