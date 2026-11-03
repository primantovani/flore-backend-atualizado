# Scripts do banco Oracle

O pipeline (`.github/workflows/ci-cd.yml`) roda todo `db/*.sql` em ordem alfabética,
num Oracle de verdade, a cada push e pull request. Um erro em qualquer script derruba o build.

| Arquivo | Conteúdo |
| --- | --- |
| `01_tabelas.sql` | Tabelas da Fase 6 (idempotente) |
| `02_rotinas_fase6.sql` | Functions e procedures da Fase 6 |
| `03_packages.sql` | Package `PKG_FLORE` (Fase 7) |
| `04_trigger_auditoria.sql` | Tabela `AUDITORIA_CLOSET_ITEMS` + trigger `TRG_AUDITORIA_CLOSET` (Fase 7) |
| `05_dynamic_sql.sql` | Procedure `PR_CONSULTAR_PEDIDOS_DINAMICO` (Fase 7) |

Para entrar no pipeline, um script novo só precisa seguir a numeração
(ex.: `06_...sql`) e poder rodar mais de uma vez: `CREATE OR REPLACE` para rotinas, packages e triggers, e o
padrão de `01_tabelas.sql` para tabelas.

`ci/oracle-smoke.sql` exercita as rotinas com dados de teste e desfaz tudo no final.

No SQL Developer, rode cada arquivo inteiro com **F5 (Executar Script)**. Ctrl+Enter
executa só a instrução sob o cursor e corta o package/procedure no primeiro `;`,
o que deixa o objeto INVALID com PLS-00103 ("end-of-file").
