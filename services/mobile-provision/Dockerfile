FROM node:20-alpine

# git + ssh for repo operations; bash for create_business.sh; curl for health checks
RUN apk add --no-cache git openssh-client bash curl

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY src/ ./src/

# Default volume mount points (override via docker-compose / env)
RUN mkdir -p /opt/quantix/tenants /opt/quantix/state

EXPOSE 3400

# Run as non-root
USER node

CMD ["node", "src/index.js"]
