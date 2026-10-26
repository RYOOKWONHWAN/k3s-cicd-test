# 1단계 : 프론트 빌드
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# 2단계 : 실행 이미지 (빌드 결과와 서버 파일만 담는다)
FROM node:22-alpine
WORKDIR /app
ARG VERSION=dev
ARG COMMIT=local
ARG BUILD_TIME=unknown
ENV NODE_ENV=production \
    PORT=8080 \
    APP_VERSION=$VERSION \
    APP_COMMIT=$COMMIT \
    APP_BUILD_TIME=$BUILD_TIME
COPY package.json server.js ./
COPY --from=build /app/dist ./dist
USER node
EXPOSE 8080
CMD ["node", "server.js"]
