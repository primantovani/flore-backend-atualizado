# Scripts do banco Oracle

O pipeline (`.github/workflows/ci-cd.yml`) roda todo `db/*.sql` em ordem alfabética,
num Oracle de verdade, a cada push e pull request. Um erro em qualquer script derruba o build.

| Arquivo | Conteúdo |
| --- | --- |
| `01_tabelas.sql` | Tabelas da Fase 6 (idempotente) |
| `02_rotinas_fase6.sql` | Functions e procedures da Fase 6 |

Para entrar no pipeline, um script novo só precisa seguir a numeração
(ex.: `03_packages.sql`, `04_trigger_auditoria.sql`, `05_dynamic_sql.sql`) e poder
rodar mais de uma vez: `CREATE OR REPLACE` para rotinas, packages e triggers, e o
padrão de `01_tabelas.sql` para tabelas.

`ci/oracle-smoke.sql` exercita as rotinas com dados de teste e desfaz tudo no final.
