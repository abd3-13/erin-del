# 1- Build Caddy modules
FROM caddy:2.9.1-builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/replace-response

# 2 - Buidl Go backend for the delete
FROM golang:alpine AS gobuild

WORKDIR /app

COPY erin-del.go ./

RUN GOOS=linux GOARCH=amd64 go build -o erin-del-vid erin-del.go

# 3 - Build fronted erin
FROM node:alpine AS erinbuild

WORKDIR /app

# Copy all app source files 
COPY ./src ./src
COPY ./public ./public
COPY package.json yarn.lock ./

#build erin
RUN yarn install && yarn build

# 4 - Set up Caddy and the frontend built beforehand
FROM caddy:2.9.1-alpine

# Add curl for health checks
RUN apk add --no-cache curl

# Install the modules
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY --from=gobuild /app/erin-del-vid /usr/bin/

# Set Caddy configuration
COPY docker/Caddyfile /etc/caddy/
COPY docker/entrypoint.sh /

# Install the React App
COPY --from=erinbuild /app/build /srv

# Entrypoint shell script will run both
ENTRYPOINT ["sh", "/entrypoint.sh"]
