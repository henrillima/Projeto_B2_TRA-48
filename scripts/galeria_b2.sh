#!/usr/bin/env bash
# Monta duas páginas com todas as figuras dos scripts 01 a 06, agrupadas por script,
# com as tabelas de resultados/ logo abaixo de cada grupo. Só usa bash, awk e base64 (vêm no macOS).
#   figuras/index.html                  leve; as imagens são lidas da pasta figuras/
#   figuras/galeria_b2_completa.html    autocontida: as imagens vão dentro do arquivo (~11 MB),
#                                       então abre sozinha em qualquer lugar (WhatsApp, e-mail, celular)
# Uso: bash scripts/galeria_b2.sh          (gera e abre)
#      bash scripts/galeria_b2.sh --nao-abrir
cd "$(dirname "$0")/.." || exit 1
mkdir -p figuras

csv_para_tabela() {
  # CSV do write.csv (aspas duplas, vírgula) -> <table>; respeita vírgula dentro de aspas
  awk 'BEGIN { print "<div class=\"tab\"><table>" }
  {
    n = 0; campo = ""; dentro = 0
    for (i = 1; i <= length($0); i++) {
      c = substr($0, i, 1)
      if (c == "\"") { dentro = !dentro; continue }
      if (c == "," && !dentro) { n++; f[n] = campo; campo = ""; continue }
      campo = campo c
    }
    n++; f[n] = campo
    tag = (NR == 1) ? "th" : "td"
    printf "<tr>"
    for (j = 1; j <= n; j++) {
      g = f[j]; gsub(/&/, "\\&amp;", g); gsub(/</, "\\&lt;", g)
      printf "<%s>%s</%s>", tag, g, tag
    }
    print "</tr>"
  }
  END { print "</table></div>" }' "$1"
}

titulo_de() {
  case "$1" in
    01) echo "01 · Exploração" ;;
    02) echo "02 · Pré-processamento e anomalias" ;;
    03) echo "03 · Modelos e validação cruzada" ;;
    04) echo "04 · Avaliação e escolha do modelo" ;;
    05) echo "05 · Submissão" ;;
    06) echo "06 · Sensibilidade do SVM" ;;
  esac
}

montar() {
modo="$1"   # local ou completa
cat <<'HTML'
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Projeto B2 · figuras e resultados</title>
<style>
  :root { --fundo:#fcfcfb; --cartao:#ffffff; --texto:#0b0b0b; --suave:#52514e; --grade:#e4e3df; --azul:#2a78d6; }
  * { box-sizing:border-box }
  body { margin:0; background:var(--fundo); color:var(--texto); font:15px/1.5 -apple-system, "Helvetica Neue", Arial, sans-serif }
  header { padding:28px 32px 12px }
  header h1 { margin:0 0 4px; font-size:22px }
  header p { margin:0; color:var(--suave) }
  nav { position:sticky; top:0; z-index:2; background:var(--fundo); border-bottom:1px solid var(--grade); padding:10px 32px; display:flex; gap:18px; flex-wrap:wrap }
  nav a { color:var(--suave); text-decoration:none; font-weight:600 }
  nav a:hover { color:var(--azul) }
  section { padding:8px 32px 28px }
  h2 { font-size:18px; margin:24px 0 12px; padding-top:8px }
  h3 { font-size:14px; color:var(--suave); margin:22px 0 8px; font-weight:600 }
  .grade { display:grid; grid-template-columns:repeat(auto-fill, minmax(420px, 1fr)); gap:16px }
  figure { margin:0; background:var(--cartao); border:1px solid var(--grade); border-radius:8px; overflow:hidden }
  figure img { width:100%; display:block; cursor:zoom-in }
  #zoom { display:none; position:fixed; inset:0; z-index:10; background:rgba(11,11,11,.88); cursor:zoom-out; align-items:center; justify-content:center; padding:16px }
  #zoom.aberto { display:flex }
  #zoom img { max-width:100%; max-height:100%; background:#fff; border-radius:6px }
  figcaption { padding:8px 12px; font-size:13px; color:var(--suave); border-top:1px solid var(--grade) }
  .tab { overflow-x:auto; background:var(--cartao); border:1px solid var(--grade); border-radius:8px; margin-bottom:12px }
  table { border-collapse:collapse; font-size:13px; font-variant-numeric:tabular-nums; width:100% }
  th, td { padding:5px 10px; border-bottom:1px solid var(--grade); text-align:left; white-space:nowrap }
  th { background:#f3f2ef; position:sticky; top:0 }
  pre { background:var(--cartao); border:1px solid var(--grade); border-radius:8px; padding:10px 12px; font-size:12.5px; overflow-x:auto }
  @media (max-width:520px) { .grade { grid-template-columns:1fr } section, header, nav { padding-left:16px; padding-right:16px } nav { position:static; gap:6px 14px; font-size:14px } }
</style></head><body>
HTML
echo "<header><h1>Projeto B2 · tempo de táxi na partida em SBGR</h1>"
echo "<p>TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri · gerado em $(date '+%d/%m/%Y %H:%M') · clique numa figura para ampliar</p></header>"
echo "<nav>"
for n in 01 02 03 04 05 06; do
  ls figuras/${n}_*.png resultados/${n}_* >/dev/null 2>&1 && echo "<a href=\"#s$n\">$(titulo_de $n)</a>"
done
[ "$modo" = local ] && [ -d resultados/logs ] && echo "<a href=\"#logs\">Logs</a>"
echo "</nav>"

for n in 01 02 03 04 05 06; do
  ls figuras/${n}_*.png resultados/${n}_* >/dev/null 2>&1 || continue
  echo "<section id=\"s$n\"><h2>$(titulo_de $n)</h2>"
  if ls figuras/${n}_*.png >/dev/null 2>&1; then
    echo "<div class=\"grade\">"
    for f in figuras/${n}_*.png; do
      b=$(basename "$f" .png)
      leg=$(echo "${b#??_??_}" | tr '_' ' ')
      if [ "$modo" = completa ]; then
        src="data:image/png;base64,$(base64 < "$f" | tr -d '\n')"
      else
        src="$(basename "$f")"
      fi
      echo "<figure><img loading=\"lazy\" src=\"$src\" alt=\"$leg\"><figcaption><b>${b%%_[a-z]*}</b> · $leg</figcaption></figure>"
    done
    echo "</div>"
  fi
  for t in resultados/${n}_*.csv; do
    [ -e "$t" ] || continue
    echo "<h3>$(basename "$t")</h3>"; csv_para_tabela "$t"
  done
  for t in resultados/${n}_*.txt; do
    [ -e "$t" ] || continue
    echo "<h3>$(basename "$t")</h3><pre>"; sed 's/&/\&amp;/g; s/</\&lt;/g' "$t"; echo "</pre>"
  done
  echo "</section>"
done

if [ "$modo" = local ] && [ -d resultados/logs ]; then
  echo "<section id=\"logs\"><h2>Logs do console</h2>"
  for l in resultados/logs/*.txt; do
    [ -e "$l" ] || continue
    echo "<h3><a href=\"../$l\" target=\"_blank\">$(basename "$l")</a> · $(wc -l < "$l" | tr -d ' ') linhas</h3>"
  done
  echo "</section>"
fi
cat <<'HTML'
<div id="zoom"><img alt=""></div>
<script>
  var z = document.getElementById('zoom'), zi = z.querySelector('img');
  document.querySelectorAll('figure img').forEach(function (im) {
    im.addEventListener('click', function () { zi.src = im.src; z.classList.add('aberto'); });
  });
  z.addEventListener('click', function () { z.classList.remove('aberto'); zi.src = ''; });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') z.click(); });
</script>
</body></html>
HTML
}

montar local > figuras/index.html
montar completa > figuras/galeria_b2_completa.html

echo "Galeria: figuras/index.html ($(ls figuras/*.png 2>/dev/null | wc -l | tr -d ' ') figuras)"
echo "Versão para compartilhar: figuras/galeria_b2_completa.html ($(du -h figuras/galeria_b2_completa.html | cut -f1))"
[ "$1" = "--nao-abrir" ] || { command -v open >/dev/null && open figuras/index.html; }
