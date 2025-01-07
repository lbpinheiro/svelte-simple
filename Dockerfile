FROM node:18-alpine as builder

# Instalar curl (necessário para o healthcheck)
RUN apk add --no-cache curl

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application
COPY . .
RUN ls -l svelte.config.js

# Generate TypeScript config files first
RUN pnpm svelte-kit sync

# Verificar se o arquivo tsconfig.json foi gerado
RUN ls -l .svelte-kit/tsconfig.json

# Build the application
RUN pnpm run build

# Production stage
FROM node:18-alpine as production

WORKDIR /app

# Copy built assets from builder
COPY --from=builder /app/build build/
COPY --from=builder /app/package.json .
COPY --from=builder /app/node_modules node_modules/

EXPOSE 3000
CMD ["node", "build"]
