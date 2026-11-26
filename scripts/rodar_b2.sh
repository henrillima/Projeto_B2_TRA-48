#!/usr/bin/env bash
# Roda os scripts R do Projeto B2 em ordem, salva o console de cada um em resultados/logs/
# e no fim monta e abre a galeria de figuras (figuras/index.html).
# Uso: bash scripts/rodar_b2.sh            (01 a 05)
#      bash scripts/rodar_b2.sh 03 04 05   (só os escolhidos, na ordem dada)
#      bash scripts/rodar_b2.sh 06         (sensibilidade do SVM; não entra no padrão porque não muda a submissão)
# Para no primeiro script que der erro; o log dele mostra onde.
cd "$(dirname "$0")/.." || exit 1
mkdir -p resultados/logs figuras
etapas="${*:-01 02 03 04 05}"
inicio=$(date +%s)

for n in $etapas; do
  s=$(ls R/TRA48_B2_${n}_*.R 2>/dev/null | head -1)
  if [ -z "$s" ]; then echo "Script $n não encontrado em R/"; exit 1; fi
  log="resultados/logs/$(basename "$s" .R).txt"
  echo; echo "=== $(date +%H:%M:%S) · $s"
  t0=$(date +%s)
  Rscript "$s" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  echo "=== $s · $(( $(date +%s) - t0 )) s · código de saída $status"
  if [ "$status" -ne 0 ]; then
    echo "Parou no $s. Log completo em $log"
    exit "$status"
  fi
done

echo; echo "Tudo pronto em $(( ($(date +%s) - inicio) / 60 )) min."
bash scripts/galeria_b2.sh
