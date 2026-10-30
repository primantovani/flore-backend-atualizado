#!/usr/bin/env bash
# Teste de fumaça da API rodando contra o Oracle: cadastro, login, criação de
# peça e listagem pública do marketplace. Saída em ci-logs/smoke-api.log.
#
# Uso: ci/smoke-api.sh http://localhost:8080
set -euo pipefail

BASE="${1:-http://localhost:8080}"
EMAIL="ci.$(date +%s)@flore.test"
mkdir -p ci-logs
exec > >(tee ci-logs/smoke-api.log) 2>&1

passo() { echo "OK  $1"; }
falha() { echo "::error::FALHOU: $1"; exit 1; }

resp=$(curl -s -w '\n%{http_code}' -X POST "$BASE/api/auth/signup" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"CI Florê\",\"email\":\"$EMAIL\",\"password\":\"senha123\"}")
[ "$(tail -n1 <<<"$resp")" = "201" ] || falha "signup devolveu $(tail -n1 <<<"$resp"): $(head -n -1 <<<"$resp")"
passo "POST /api/auth/signup -> 201"

token=$(curl -sf -X POST "$BASE/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"senha123\"}" | jq -r '.token')
[ -n "$token" ] && [ "$token" != "null" ] || falha "login nao devolveu token"
passo "POST /api/auth/login -> token JWT"

codigo=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/api/closet" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Sem token","category":"teste","price":1}')
[ "$codigo" = "401" ] || [ "$codigo" = "403" ] || falha "POST /api/closet sem token devolveu $codigo"
passo "POST /api/closet sem token -> $codigo (bloqueado)"

item_id=$(curl -sf -X POST "$BASE/api/closet" \
  -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
  -d '{"name":"Vestido floral","category":"vestido","price":120.5,"size":"M"}' | jq -r '.id')
[ -n "$item_id" ] && [ "$item_id" != "null" ] || falha "criacao de peca nao devolveu id"
passo "POST /api/closet -> peca $item_id criada"

curl -sf "$BASE/api/closet" | jq -e --argjson id "$item_id" 'map(.id) | index($id) != null' >/dev/null \
  || falha "peca $item_id nao aparece no marketplace"
passo "GET /api/closet -> peca $item_id no marketplace"

echo "$EMAIL" > ci-logs/smoke-email.txt
echo "Smoke test da API concluido."
