#!/usr/bin/env bash
# TriPick — 의존성 설치 및 빌드 스크립트
#
# 사전 요구 사항
#   - Node.js 20 (.nvmrc 참고)
#   - Docker / Docker Compose (PostgreSQL · Redis · MinIO · Mailpit)
#
# 실행 후 `pnpm start` 로 인프라 기동 + web · API dev 서버를 함께 띄운다.

set -euo pipefail
cd "$(dirname "$0")"

echo '==> 1. Node.js 확인'
node --version

echo '==> 2. pnpm 활성화 (corepack)'
corepack enable
corepack prepare pnpm@9 --activate

echo '==> 3. 의존성 설치'
pnpm install --frozen-lockfile

echo '==> 4. 환경변수 파일 준비'
[ -f apps/api/.env ] || cp apps/api/.env.example apps/api/.env
[ -f apps/web/.env ] || cp apps/web/.env.example apps/web/.env
echo '    apps/api/.env · apps/web/.env 준비됨 (외부 API 키는 직접 채워야 전체 기능 동작)'

echo '==> 5. 빌드'
pnpm build

echo
echo '설치 및 빌드 완료.'
echo '  개발 실행 : pnpm start      (Docker 인프라 + web/API dev, http://localhost:3000)'
echo '  인프라만  : pnpm db:up / pnpm db:down'
echo '  테스트    : pnpm test'
