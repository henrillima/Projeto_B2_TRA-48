

##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 01: Análise exploratória da base de dados (item 3 do relatório)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# Segue a estrutura do TRA48_Lab1.R: estatísticas descritivas, visualizações gráficas e PCA.
# Todas as figuras são salvas em PNG na pasta "figuras/" do repositório, com o prefixo "01_".

# Ir para o diretório onde a base "data_project.Rda" se encontra
# (a base fica fora do repositório: é material da disciplina e o repositório é público)
dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)

# Pastas do repositório para onde vão as figuras e as tabelas
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)

# Carregar a base
load("data_project.Rda")

# A base contém dois objetos:
#   data_train - 6.426 voos com o tempo de táxi (taxitime) conhecido
#   data_test  - 1.607 voos com o taxitime em branco, que devem ser previstos e submetidos
# Os dois vêm como "data.table". Convertemos para "data.frame", que é o formato usado nos Labs.
data <- as.data.frame(data_train)
data_final <- as.data.frame(data_test)

# Verificar o formato da base e listar as variáveis
class(data)
names(data)
dim(data)
dim(data_final)

# Variáveis (apêndice do enunciado):
#   id               identificador único do voo
#   adep, ades       aeroporto de origem (sempre SBGR) e de destino, código ICAO
#   cpush, crwy      horário de pushback e de decolagem, em UTC
#   airline          companhia aérea, código ICAO
#   acfttype, wtc    tipo de aeronave (ICAO) e categoria de esteira de turbulência
#   runway           cabeceira utilizada para decolagem (10L ou 28R)
#   taxitime         tempo de táxi, em segundos  <- VARIÁVEL DE OUTPUT
#   nactive          aeronaves taxiando no momento do pushback
#   wind_direction   direção do vento, em graus
#   wind_speed       velocidade do vento, em nós (kt)
#   wx               1 se havia chuva e/ou baixa visibilidade

# Pacotes (instalar UMA vez, no console, antes de rodar os scripts):
# install.packages(c('corrplot', 'pheatmap'))
library(corrplot)
library(pheatmap)

# Paleta e estilo dos gráficos.
# As três cores categóricas passaram no teste de separação para daltonismo (deuteranopia,
# protanopia e tritanopia) e entre si para visão normal. Elas sempre significam a mesma coisa:
#   azul = cabeceira 10L (ou série principal) · laranja = cabeceira 28R (ou destaque) · verde-água = terceira série
cor_1 <- '#2a78d6'
cor_2 <- '#eb6834'
cor_3 <- '#1baf7a'
cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'
cor_texto2 <- '#52514e'
cor_grade <- '#e4e3df'
cor_fundo <- '#fcfcfb'
cores_runway <- c('10L'=cor_1, '28R'=cor_2)
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
# Tamanho padrão das figuras (pixels e resolução)
larg <- 2000; alt <- 1250; reso <- 220


############################################################
# ETAPA 0: CONFERÊNCIA DO VAZAMENTO DA VARIÁVEL "crwy"     #
############################################################


# Antes de qualquer análise, conferimos a relação entre o tempo de táxi e os dois horários de
#movimentação em solo. Se taxitime = crwy - cpush, o horário de decolagem (crwy) contém a resposta
#e não pode ser usado como input: ele não existe no momento do pushback, que é quando a previsão é útil.

diferenca <- as.numeric(difftime(data$crwy, data$cpush, units='secs'))
print(max(abs(diferenca - data$taxitime)))   # diferença máxima entre (crwy - cpush) e taxitime, em segundos

# A base de teste também traz o crwy preenchido. Se a diferença crwy - cpush no teste tiver o mesmo resumo
#(summary, como no Lab1) e o mesmo histograma do taxitime do treino, o crwy do teste é o horário real de decolagem.
diferenca_final <- as.numeric(difftime(data_final$crwy, data_final$cpush, units='secs'))
sum(is.na(data_final$crwy))
summary(data$taxitime)
summary(diferenca_final)
# Mesmos quartis, mediana e média nas duas bases (comparar os dois summary acima e o histograma abaixo)

png(paste0(dir_fig, '01_00_vazamento_crwy.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
plot(diferenca, data$taxitime, pch=16, cex=0.4, col=adjustcolor(cor_1, 0.4),
     xlab='crwy - cpush (s)', ylab='taxitime (s)', main='Treino: taxitime = crwy - cpush',
     panel.first=grid(col=cor_grade, lty=1))
abline(0, 1, col=cor_2, lwd=2)
hist(data$taxitime, breaks=40, freq=FALSE, col=adjustcolor(cor_1, 0.5), border=cor_fundo,
     xlab='Tempo (s)', ylab='Densidade', main='taxitime (treino) x crwy - cpush (teste)')
lines(density(diferenca_final), col=cor_2, lwd=2)
legend('topright', legend=c('taxitime, treino', 'crwy - cpush, teste'), fill=c(adjustcolor(cor_1, 0.5), NA),
       border=c(cor_fundo, NA), lwd=c(NA, 2), col=c(NA, cor_2), bty='n', text.col=cor_texto2)
dev.off()

# Conclusão: o crwy é excluído de todos os modelos (ver Script 02).


################################################
# ETAPA 1: GERAÇÃO DE ESTATÍSTICAS DESCRITIVAS #
################################################


# Computar as estatísticas (mínimo, 1o quartil, mediana, média, 3o quartil, máximo) para cada variável
summary(data)

# Separar as variáveis numéricas, como no Lab1
x <- data[, c('taxitime', 'nactive', 'wind_direction', 'wind_speed', 'wx')]
apply(x, 2, mean)  # média de cada variável
apply(x, 2, var)   # variância de cada variável
apply(x, 2, sd)    # desvio padrão de cada variável

# Hora local do pushback (a base está em UTC; São Paulo é UTC-3)
data$hora <- as.POSIXlt(data$cpush, tz='America/Sao_Paulo')$hour

# Mediana do tempo de táxi por categoria
aggregate(taxitime ~ runway, data=data, FUN=median)
aggregate(taxitime ~ wtc, data=data, FUN=median)
aggregate(taxitime ~ wx, data=data, FUN=median)
aggregate(taxitime ~ airline, data=data, FUN=median)
aggregate(taxitime ~ hora, data=data, FUN=median)

# Número de níveis das variáveis categóricas (importante: o pacote "tree" aceita no máximo 32 níveis)
lengths(lapply(data[, c('airline', 'ades', 'acfttype', 'wtc', 'runway')], unique))
setdiff(unique(as.character(data_final$ades)), unique(as.character(data$ades)))         # destinos que só aparecem no teste
setdiff(unique(as.character(data_final$acfttype)), unique(as.character(data$acfttype))) # aeronaves que só aparecem no teste
sort(table(data$acfttype))

# Tabela descritiva do taxitime para o relatório: geral e por cabeceira
grupos <- list(Geral=data$taxitime, '10L'=data$taxitime[data$runway=='10L'], '28R'=data$taxitime[data$runway=='28R'])
tabela_descritiva <- data.frame(grupo=names(grupos),
                                n=sapply(grupos, length),
                                media=sapply(grupos, mean),
                                mediana=sapply(grupos, median),
                                desvio_padrao=sapply(grupos, sd),
                                minimo=sapply(grupos, min),
                                q1=sapply(grupos, quantile, 0.25),
                                q3=sapply(grupos, quantile, 0.75),
                                maximo=sapply(grupos, max))
tabela_descritiva[, -1] <- round(tabela_descritiva[, -1], 1)
print(tabela_descritiva)
write.csv(tabela_descritiva, paste0(dir_res, '01_tabela_descritiva_taxitime.csv'), row.names=FALSE)

# Cauda longa à direita: a média fica acima da mediana e o boxplot marca muitos voos acima de Q3 + 1,5 IQR
#(regra do boxplot, Aula 1, slide 27). Por isso testamos também a regressão linear em log(taxitime), como
#sugere a Aula 5, slide 52 (transformar as variáveis para que um modelo linear se torne aplicável).
print(c(media=mean(data$taxitime), mediana=median(data$taxitime)))


# Observações acima de Q3 + 1,5 IQR (regra do boxplot)
limite_superior <- quantile(data$taxitime, 0.75) + 1.5*IQR(data$taxitime)
sum(data$taxitime > limite_superior)


##############################################
# ETAPA 2: GERAÇÃO DE VISUALIZAÇÕES GRÁFICAS #
##############################################


# HISTOGRAM — distribuição do tempo de táxi, em escala original e logarítmica
png(paste0(dir_fig, '01_01_histograma_taxitime.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
hist(data$taxitime, breaks=40, col=cor_1, border=cor_fundo, xlab='Tempo de táxi (s)', ylab='Número de voos',
     main='Tempo de táxi')
abline(v=median(data$taxitime), col=cor_2, lwd=2, lty=2)
legend('topright', legend=paste0('mediana = ', round(median(data$taxitime)), ' s'), col=cor_2, lwd=2, lty=2,
       bty='n', text.col=cor_texto2)
hist(log(data$taxitime), breaks=40, col=cor_1, border=cor_fundo, xlab='log(tempo de táxi)', ylab='Número de voos',
     main='log(tempo de táxi)')
dev.off()


# BOXPLOT — visão compacta da distribuição e das observações extremas
png(paste0(dir_fig, '01_02_boxplot_taxitime.png'), width=1200, height=alt, res=reso)
par(estilo)
boxplot(data$taxitime, col=adjustcolor(cor_1, 0.35), border=cor_1, ylab='Tempo de táxi (s)',
        main='Tempo de táxi', outcol=adjustcolor(cor_2, 0.6), outpch=16, outcex=0.5)
mtext(paste0(sum(data$taxitime > limite_superior), ' voos acima de Q3 + 1,5 IQR'), side=3, line=0.2,
      cex=0.8, col=cor_texto2)
dev.off()


# BARPLOT — como a amostra se distribui entre as categorias
png(paste0(dir_fig, '01_03_barplots_amostra.png'), width=larg, height=1600, res=reso)
par(estilo); par(mfrow=c(2,2))
counts <- sort(table(data$airline), decreasing=TRUE)
barplot(counts, col=cor_1, border=NA, ylab='Número de voos', main='Voos por companhia', cex.names=0.75, las=2)
counts <- table(data$runway)
barplot(counts, col=cores_runway[names(counts)], border=NA, ylab='Número de voos', main='Voos por cabeceira')
counts <- table(data$wtc)
barplot(counts, col=cor_1, border=NA, ylab='Número de voos', main='Voos por categoria de esteira',
        names.arg=c('H (pesada)', 'M (média)')[match(names(counts), c('H', 'M'))])
counts <- table(factor(data$hora, levels=0:23))
barplot(counts, col=cor_1, border=NA, ylab='Número de voos', xlab='Hora local do pushback',
        main='Voos por hora do dia', cex.names=0.7)
dev.off()


# BOXPLOT por categoria — o que muda o tempo de táxi?
# Cabeceira
png(paste0(dir_fig, '01_04_boxplot_runway.png'), width=1400, height=alt, res=reso)
par(estilo)
boxplot(taxitime ~ runway, data=data, col=adjustcolor(cores_runway, 0.35), border=cores_runway,
        xlab='Cabeceira', ylab='Tempo de táxi (s)', main='Tempo de táxi por cabeceira',
        outpch=16, outcex=0.4)
values <- aggregate(taxitime ~ runway, data=data, FUN=median)
text(1:2, values$taxitime, labels=paste0(round(values$taxitime), ' s'), pos=3, cex=0.8, col=cor_texto)
dev.off()

# Categoria de esteira e meteorologia
png(paste0(dir_fig, '01_05_boxplot_wtc_wx.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
boxplot(taxitime ~ wtc, data=data, col=adjustcolor(cor_1, 0.35), border=cor_1, xlab='Categoria de esteira',
        ylab='Tempo de táxi (s)', main='Por categoria de esteira', outpch=16, outcex=0.4,
        names=c('H (pesada)', 'M (média)'))
boxplot(taxitime ~ wx, data=data, col=adjustcolor(cor_1, 0.35), border=cor_1,
        xlab='Fenômeno meteorológico (wx)', ylab='Tempo de táxi (s)', main='Com e sem chuva/baixa visibilidade',
        outpch=16, outcex=0.4, names=c('0 (não)', '1 (sim)'))
dev.off()

# Companhia aérea, ordenada pela mediana
ordem <- names(sort(tapply(data$taxitime, data$airline, median)))
png(paste0(dir_fig, '01_06_boxplot_airline.png'), width=larg, height=alt, res=reso)
par(estilo)
boxplot(taxitime ~ factor(airline, levels=ordem), data=data, col=adjustcolor(cor_1, 0.35), border=cor_1,
        xlab='Companhia (ordenada pela mediana)', ylab='Tempo de táxi (s)', main='Tempo de táxi por companhia',
        outpch=16, outcex=0.4)
dev.off()

# Hora local do pushback
png(paste0(dir_fig, '01_07_boxplot_hora.png'), width=larg, height=alt, res=reso)
par(estilo)
boxplot(taxitime ~ factor(hora, levels=0:23), data=data, col=adjustcolor(cor_1, 0.35), border=cor_1,
        xlab='Hora local do pushback', ylab='Tempo de táxi (s)', main='Tempo de táxi ao longo do dia',
        outpch=16, outcex=0.3, cex.axis=0.8)
dev.off()


# SCATTERPLOT — congestionamento (nactive) x tempo de táxi, por cabeceira
png(paste0(dir_fig, '01_08_scatter_nactive.png'), width=larg, height=alt, res=reso)
par(estilo)
plot(jitter(data$nactive, 0.6), data$taxitime, pch=16, cex=0.45, col=adjustcolor(cores_runway[as.character(data$runway)], 0.35),
     xlab='Aeronaves taxiando no pushback (nactive)', ylab='Tempo de táxi (s)',
     main='Congestionamento x tempo de táxi', panel.first=grid(col=cor_grade, lty=1))
for (r in c('10L', '28R')){
  sel <- data$runway == r
  lines(lowess(data$nactive[sel], data$taxitime[sel]), col=cores_runway[r], lwd=3)
}
legend('topleft', legend=c('10L', '28R'), col=cores_runway, pch=16, lwd=3, bty='n', title='Cabeceira',
       text.col=cor_texto2, title.col=cor_texto)
mtext(paste0('correlação = ', round(cor(data$nactive, data$taxitime), 2)), side=3, line=0.2, cex=0.8, col=cor_texto2)
dev.off()


# SCATTERPLOT ARRAY — relações entre pares de variáveis numéricas
png(paste0(dir_fig, '01_09_pairs.png'), width=1800, height=1800, res=reso)
par(estilo)
pairs(~ taxitime + nactive + hora + wind_speed + wind_direction, data=data, pch=16, cex=0.3,
      col=adjustcolor(cores_runway[as.character(data$runway)], 0.3), main='Relações entre pares (cor = cabeceira)')
dev.off()


# CORRELOGRAM — correlação entre as variáveis numéricas
correlation_matrix <- cor(data[, c('taxitime', 'nactive', 'hora', 'wind_direction', 'wind_speed', 'wx')])
print(round(correlation_matrix, 2))
divergente <- colorRampPalette(c('#e34948', '#f0efec', cor_1))(200)
png(paste0(dir_fig, '01_10_correlograma.png'), width=1600, height=1600, res=reso)
par(bg=cor_fundo)
corrplot(correlation_matrix, method='color', col=divergente, addCoef.col=cor_texto, number.cex=0.8,
         tl.col=cor_texto, tl.srt=45, cl.cex=0.8, mar=c(0,0,2,0), title='Correlação entre as variáveis numéricas')
dev.off()

# HEATMAP — a mesma matriz, como no Lab1
png(paste0(dir_fig, '01_11_heatmap_correlacao.png'), width=1600, height=1400, res=reso)
pheatmap(correlation_matrix,
         color=colorRampPalette(c('#e34948', '#f0efec', cor_1))(100),
         breaks=seq(-1, 1, length.out=101),
         cluster_rows=FALSE, cluster_cols=FALSE, display_numbers=TRUE, number_color=cor_texto,
         main='Matriz de correlação')
dev.off()


# Direção do vento x cabeceira — a cabeceira é escolhida pelo vento, então as duas variáveis andam juntas
png(paste0(dir_fig, '01_12_vento_runway.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
boxplot(wind_direction ~ runway, data=data[data$wind_speed > 0, ], col=adjustcolor(cores_runway, 0.35),
        border=cores_runway, xlab='Cabeceira', ylab='Direção do vento (graus)', main='Direção do vento por cabeceira',
        outpch=16, outcex=0.4)
boxplot(wind_speed ~ runway, data=data, col=adjustcolor(cores_runway, 0.35), border=cores_runway,
        xlab='Cabeceira', ylab='Velocidade do vento (kt)', main='Velocidade do vento por cabeceira',
        outpch=16, outcex=0.4)
dev.off()
# Vento calmo é registrado como direção 0 e velocidade 0:
table(data$wind_direction[data$wind_speed == 0])


####################################################
# ETAPA 3: ANÁLISE DE COMPONENTES PRINCIPAIS (PCA) #
####################################################


# Como no Lab1, realizamos a PCA nas variáveis numéricas de input (o taxitime fica de fora, por ser o output).
# Com poucas variáveis numéricas, a PCA aqui é sobretudo exploratória.
x <- data[, c('nactive', 'hora', 'wind_direction', 'wind_speed', 'wx')]
pca_out <- prcomp(x, scale=TRUE)
# scale=TRUE: cada variável é centrada e dividida pelo desvio padrão antes da PCA (ver Lab1)
print(pca_out$rotation)

# Proporção da variância explicada por cada componente principal
var_explained_pc <- pca_out$sdev^2
pve <- var_explained_pc/sum(var_explained_pc)
print(round(pve, 3))

png(paste0(dir_fig, '01_13_pca.png'), width=2400, height=alt, res=reso)
par(estilo); par(mfrow=c(1,3))
plot(pve, xlab='Componente principal', ylab='Proporção da variância explicada', ylim=c(0,1), type='b',
     pch=16, col=cor_1, lwd=2, main='Variância explicada', panel.first=grid(col=cor_grade, lty=1))
plot(cumsum(pve), xlab='Componente principal', ylab='Proporção acumulada', ylim=c(0,1), type='b',
     pch=16, col=cor_1, lwd=2, main='Variância explicada acumulada', panel.first=grid(col=cor_grade, lty=1))
plot(pca_out$x[,1], pca_out$x[,2], pch=16, cex=0.4, col=adjustcolor(cores_runway[as.character(data$runway)], 0.35),
     xlab='PC1', ylab='PC2', main='Voos no plano PC1 x PC2 (cor = cabeceira)', panel.first=grid(col=cor_grade, lty=1))
dev.off()

# Fim do Script 01. Figuras em "figuras/01_*.png" e tabela em "resultados/01_tabela_descritiva_taxitime.csv".
