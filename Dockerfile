FROM node:18-alpine as builder

# Instalar curl (necessário para o healthcheck)
RUN apk add --no-cache curl

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy the rest of the application
COPY . .

# Copy package files
#COPY svelte.config.js package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Generate TypeScript config files first
RUN pnpm svelte-kit sync

# Verificar se o arquivo tsconfig.json foi gerado
#RUN ls -l .svelte-kit/tsconfig.json

# Build the application
RUN pnpm run build
RUN ls -la .svelte-kit/ && ls -la build/  # Adicionando comando aqui

# Production stage
FROM node:18-alpine as production
RUN apk add --no-cache wget  # Adicionando wget
WORKDIR /app


COPY --from=builder /app/.svelte-kit/output /app/.svelte-kit/output
COPY --from=builder /app/build /app/build
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/node_modules /app/node_modules
EXPOSE 3000
CMD ["node", "build/index.js"]
