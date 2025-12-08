FROM node:22-alpine
ENV PNPM_HOME=/root/.local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

# 使用 npmmirror 加速
RUN npm install -g pnpm@9.12.2 --registry https://registry.npmmirror.com

WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --registry https://registry.npmmirror.com

COPY . .

EXPOSE 5003
CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "5003"]
