#!/usr/bin/env bash
# Roda scripts .sql no Oracle do container de servico, um por vez, parando no
# primeiro erro. Cada script deixa um log em ci-logs/sql/<nome>.log.
#
# Uso: ci/run-sql.sh <container-id> <usuario/senha@//host/servico> arquivo.sql...
set -euo pipefail

CONTAINER="$1"; shift
CONEXAO="$1"; shift
mkdir -p ci-logs/sql

for arquivo in "$@"; do
  nome="$(basename "$arquivo")"
  echo "::group::$nome"
  docker cp "$arquivo" "$CONTAINER:/tmp/$nome"
  # WHENEVER SQLERROR faz o sqlplus sair com erro em vez de seguir em frente.
  if ! printf 'WHENEVER SQLERROR EXIT SQL.SQLCODE\nSET SERVEROUTPUT ON\n@/tmp/%s\nEXIT\n' "$nome" \
      | docker exec -i "$CONTAINER" sqlplus -s "$CONEXAO" | tee "ci-logs/sql/$nome.log"; then
    echo "::error file=$arquivo::Falha ao executar $nome (ver ci-logs/sql/$nome.log)"
    exit 1
  fi
  # sqlplus -s pode sair 0 com erro de compilacao (Warning: ... created with compilation errors).
  # So linha que comeca com o codigo e erro; "OK ... (ORA-20001)" do smoke test e esperado.
  if grep -q -E 'compilation errors|^ERROR at line|^(ORA|SP2|PLS)-[0-9]+' "ci-logs/sql/$nome.log"; then
    echo "::error file=$arquivo::Erro no script $nome (ver ci-logs/sql/$nome.log)"
    exit 1
  fi
  echo "::endgroup::"
done
