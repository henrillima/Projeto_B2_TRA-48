# app/data/raw/

**Esta pasta está inteiramente fora do git.** Só este arquivo é versionado.

A base do Data Challenge é material da disciplina, de uso exclusivo dos alunos matriculados em
TRA-48 2026 e protegida por direito autoral (slide 8 do planejamento do 2º bimestre). Este
repositório é público. A base não entra, e nenhuma amostra dela entra.

## O que vai aqui

| Arquivo | Origem | Quando |
| --- | --- | --- |
| *(a definir)* | Classroom da disciplina | liberada em **28/10** |

Assim que a base for liberada, `tarefa:T11` registra aqui o dicionário de dados — colunas,
tipos, unidades, granularidade, período coberto e completude por coluna — e abre um nó `fonte`
no grafo com `origem`, `formato`, `cobertura` e `limitacoes`. `pendencia:P02` fecha nesse
momento.

## Até 28/10

O pipeline roda sobre a base **sintética** gerada por `app/R/dados_sinteticos.R`
(`decisao:D03`). Ela não é dado: é uma verdade de laboratório, com relação conhecida entre
features e resposta, que existe para que os testes possam verificar o pipeline. Nenhum número
dela vai para o relatório.
