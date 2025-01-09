ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine AS builder

# Add build time arguments
ARG BUILD_ENV=production
ARG NPM_TOKEN

# Install essential build tools
RUN apk add --no-cache python3 make g++

# Enable pnpm with corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml* ./

# Install dependencies with frozen lockfile for reproducibility
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Generate TypeScript config files and build
RUN pnpm svelte-kit sync && \
    pnpm run build

# Production stage
FROM node:${NODE_VERSION}-alpine AS production

# Add runtime dependencies and security updates
RUN apk add --no-cache \
    curl \
    wget \
    tini \
    && apk upgrade --no-cache

# Create non-root user for security
RUN addgroup -g 1001 nodejs && \
    adduser -u 1001 -G nodejs -s /bin/sh -D nodejs

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder --chown=nodejs:nodejs /app/build build/
COPY --from=builder --chown=nodejs:nodejs /app/package.json .
COPY --from=builder --chown=nodejs:nodejs /app/node_modules node_modules/

# Configure environment
ENV NODE_ENV=production \
    PORT=3000

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3000

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["node", "build"]
