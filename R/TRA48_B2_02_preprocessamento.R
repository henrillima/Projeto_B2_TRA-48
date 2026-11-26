

##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 02: Pré-processamento da base de dados (item 2 do relatório)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# Transforma a base original na base de modelagem: descarte de variáveis, construção de novas
#features, partição treino/teste (Etapa 1 do Lab6), detecção de anomalias (Aula 6, com o código
#dos Labs 2 e 3) e normalização das variáveis para o kNN e a rede neural.
#
# Saída: "data_project_prep.Rda", na pasta da base, lido pelos Scripts 03 a 05.

# Ir para o diretório onde a base "data_project.Rda" se encontra
dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)

# Carregar a base
load("data_project.Rda")
data <- as.data.frame(data_train)          # 6.426 voos com taxitime
data_final <- as.data.frame(data_test)     # 1.607 voos sem taxitime (submissão)

# Pacotes (instalar UMA vez, no console): install.packages(c('cluster', 'mclust'))
library(cluster)
library(mclust)

# Paleta e estilo dos gráficos (mesmos do Script 01)
cor_1 <- '#2a78d6'; cor_2 <- '#eb6834'; cor_3 <- '#1baf7a'; cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'; cor_texto2 <- '#52514e'; cor_grade <- '#e4e3df'; cor_fundo <- '#fcfcfb'
cores_runway <- c('10L'=cor_1, '28R'=cor_2)
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
larg <- 2000; alt <- 1250; reso <- 220


#############################################################
# ETAPA 1: JUNÇÃO DAS BASES PARA TRANSFORMAÇÃO IDÊNTICA     #
#############################################################


# Para que a base de treinamento e a base de submissão recebam exatamente as mesmas
#transformações (e os mesmos níveis de cada fator), empilhamos as duas, transformamos uma vez
#e separamos de novo no fim.
data$origem_base <- 'treino'
data_final$origem_base <- 'final'
all <- rbind(data, data_final)
dim(all)
table(all$origem_base)


#############################################################
# ETAPA 2: DESCARTE DE VARIÁVEIS                            #
#############################################################


# crwy (horário de decolagem): taxitime = crwy - cpush exatamente (ver Script 01, Etapa 0).
#   O crwy É a resposta e não existe no momento do pushback. Fica fora de todos os modelos.
# adep: sempre SBGR, não carrega informação.
# id: identificador. Fica guardado para montar a submissão, mas não entra em modelo.
# cpush: substituído pelas variáveis de calendário construídas na Etapa 3.
table(all$adep)
all$crwy <- NULL
all$adep <- NULL


#############################################################
# ETAPA 3: CONSTRUÇÃO DE NOVAS FEATURES                     #
#############################################################


# Todas as variáveis abaixo usam apenas informação disponível no momento do pushback.

# 3.1 Calendário. A base está em UTC; convertemos para a hora local de São Paulo.
hora_local <- as.POSIXlt(all$cpush, tz='America/Sao_Paulo')
all$hora <- hora_local$hour                                        # 0 a 23
all$dia_semana <- factor(hora_local$wday, levels=0:6,
                         labels=c('dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'))
# Faixa horária (fator), para a regressão linear: a relação entre hora e taxitime não é linear (Script 01)
all$faixa <- cut(all$hora, breaks=c(-1, 5, 9, 13, 17, 21, 23),
                 labels=c('h00_05', 'h06_09', 'h10_13', 'h14_17', 'h18_21', 'h22_23'))
table(all$faixa)

# 3.2 Destino. O pacote "tree" aceita fatores com no máximo 32 níveis, e "ades" tem 96 destinos
#(um deles, SDSC, só aparece na base de teste). Agrupamos os destinos pelo indicador de localidade ICAO:
#   - doméstico: prefixos atribuídos ao Brasil (SB, SD, SI, SJ, SN, SS, SW — conferir no ICAO Doc 7910)
#   - internacional: pela primeira letra do indicador (região ICAO)
prefixo <- substr(as.character(all$ades), 1, 2)
letra <- substr(as.character(all$ades), 1, 1)
all$domestico <- as.numeric(prefixo %in% c('SB', 'SD', 'SI', 'SJ', 'SN', 'SS', 'SW'))
all$regiao <- 'outros'
all$regiao[all$domestico == 1] <- 'dom'
all$regiao[all$domestico == 0 & letra == 'S'] <- 'am_sul'
all$regiao[all$domestico == 0 & letra %in% c('K', 'C', 'M', 'T')] <- 'am_norte'   # EUA, Canadá, México, América Central e Caribe
all$regiao[all$domestico == 0 & letra %in% c('L', 'E')] <- 'europa'
all$regiao <- factor(all$regiao, levels=c('dom', 'am_sul', 'am_norte', 'europa', 'outros'))
table(all$regiao, all$origem_base)

# 3.3 Tipo de aeronave. Tipos raros quebram a previsão quando aparecem só no teste (o B763 tem 1 voo).
#Agrupamos os tipos com menos de 30 voos na base rotulada em "outros_H" ou "outros_M", pela categoria de esteira.
freq_acft <- table(all$acfttype[all$origem_base == 'treino'])
raros <- names(freq_acft[freq_acft < 30])
print(raros)
all$acft <- as.character(all$acfttype)
all$acft[all$acft %in% raros] <- paste0('outros_', all$wtc[all$acft %in% raros])
all$acft[!(all$acft %in% names(freq_acft))] <- paste0('outros_', all$wtc[!(all$acft %in% names(freq_acft))])  # tipo inédito no teste
all$acft <- factor(all$acft)
table(all$acft, all$origem_base)

# 3.4 Vento. O ângulo cru trata 350° e 10° como distantes, e o vento calmo vem registrado como
#direção 0 e velocidade 0. Usamos as componentes do vetor vento, em nós (kt):
#   vento_ns = velocidade x cos(direção)   (positivo = vento de norte)
#   vento_lo = velocidade x sen(direção)   (positivo = vento de leste)
# Unidades: kt x adimensional = kt. O vento calmo vira (0, 0) sem tratamento especial.
all$vento_ns <- all$wind_speed*cos(all$wind_direction*pi/180)
all$vento_lo <- all$wind_speed*sin(all$wind_direction*pi/180)

# 3.5 Pushbacks recentes (feature opcional, testada no Script 04): número de voos da base com pushback
#nos 30 minutos anteriores ao pushback do voo. Só olha para trás, então não vaza informação. Usa treino e
#teste juntos, porque todos são voos reais do mesmo mês; como a base é uma amostra das partidas de SBGR,
#a contagem é parcial.
t_push <- as.numeric(all$cpush)                    # segundos
ordem <- order(t_push)
t_ord <- t_push[ordem]
n_antes <- (seq_along(t_ord) - 1) - findInterval(t_ord - 30*60, t_ord, left.open=TRUE)
all$n_push30 <- NA
all$n_push30[ordem] <- n_antes
summary(all$n_push30)
cor(all$n_push30, all$nactive)

# 3.6 Fatores
all$runway <- factor(all$runway)
all$wtc <- factor(all$wtc)
all$airline <- factor(all$airline)

# 3.7 Separar de novo a base rotulada e a base de submissão
vars <- c('id', 'taxitime', 'nactive', 'hora', 'faixa', 'dia_semana', 'runway', 'wtc', 'acft', 'airline',
          'domestico', 'regiao', 'vento_ns', 'vento_lo', 'wx', 'n_push30')
data <- all[all$origem_base == 'treino', vars]
data_final <- all[all$origem_base == 'final', vars]
dim(data); dim(data_final)
sum(is.na(data[, -2])); sum(is.na(data_final[, c(-1, -2)]))   # nenhum NA fora do taxitime da submissão

png(paste0(dir_fig, '02_01_taxitime_por_regiao.png'), width=larg, height=alt, res=reso)
par(estilo)
boxplot(taxitime ~ regiao, data=data, col=adjustcolor(cor_1, 0.35), border=cor_1, xlab='Região do destino',
        ylab='Tempo de táxi (s)', main='Tempo de táxi por região do destino', outpch=16, outcex=0.4,
        names=paste0(levels(data$regiao), '\n(n=', table(data$regiao), ')'))
dev.off()


######################################################
# ETAPA 4: PREPARAÇÃO DAS BASES DE TREINAMENTO/TESTE #
######################################################


# Exatamente como na Etapa 1 do Lab6: partição 75%/25% da base rotulada.
set.seed(1)
idxtrain <- sample(1:nrow(data), 0.75*nrow(data))
data_train <- data[idxtrain,]
data_test <- data[-idxtrain,]
dim(data_train); dim(data_test)   # 4.819 e 1.607 voos — a base de teste interna tem o mesmo tamanho da base da professora

# A base "data_test" NUNCA é usada para escolher hiperparâmetros. Ela só serve, no Script 04, para comparar
#os modelos já ajustados (slide 7 da Aula 4: avaliação final, não enviesada, do modelo escolhido).

# Conferir que a partição preserva a distribuição do output
summary(data_train$taxitime); summary(data_test$taxitime)


#############################################################
# ETAPA 5: DETECÇÃO DE ANOMALIAS (AULA 6)                   #
#############################################################


# Objetivo: identificar voos com tempo de táxi muito diferente do esperado para o nível de congestionamento.
# Usamos só a base de treinamento. A base de teste da professora também tem voos assim, então DETECTAR não
#significa REMOVER: o efeito de retirá-los do treinamento é um experimento, decidido no Script 04.

# 5.1 Abordagem estatística (Aula 1 e Aula 6): regra do boxplot, por cabeceira
q1 <- tapply(data_train$taxitime, data_train$runway, quantile, 0.25)
q3 <- tapply(data_train$taxitime, data_train$runway, quantile, 0.75)
limite <- q3 + 1.5*(q3 - q1)
anomalo_iqr <- as.numeric(data_train$taxitime > limite[as.character(data_train$runway)])
sum(anomalo_iqr)

# 5.2 Abordagem por clusterização (Aula 6, k-means, com o código do Lab2)
# Clusterizamos os voos no plano (nactive, taxitime) normalizado.
z <- scale(data_train[, c('nactive', 'taxitime')])

# Número de clusters: cotovelo (Lab2) e silhouette (Lab2, Etapa 3).
# A silhouette usa a matriz de distâncias de 4.819 voos (~11,6 milhões de pares, ~90 MB).
d_z <- dist(z)
var_total <- numeric(8)
sil_media <- numeric(8)
for (k in 1:8){
  set.seed(1)
  kmeans_out <- kmeans(z, k, nstart=20)
  var_total[k] <- kmeans_out$tot.withinss
  if (k > 1) sil_media[k] <- mean(silhouette(kmeans_out$cluster, d_z)[, 'sil_width'])
}
k_anom <- which.max(sil_media)
print(round(sil_media, 3)); print(k_anom)

set.seed(1)
kmeans_out <- kmeans(z, k_anom, nstart=20)
clusterid <- kmeans_out$cluster
centroids <- kmeans_out$centers

# Para cada voo i: r_i = distância ao centróide do seu cluster / distância média dos voos do mesmo
#cluster ao centróide (slide "Clustering Approach — K-means", Aula 6). r_i alto = voo isolado.
dist_centroide <- sqrt(rowSums((z - centroids[clusterid,])^2))
dist_media <- ave(dist_centroide, clusterid)
r_kmeans <- dist_centroide/dist_media
limiar_r <- 3            # r_i > 3: o voo está a mais de 3 vezes a distância típica do seu cluster
anomalo_kmeans <- as.numeric(r_kmeans > limiar_r)
sum(anomalo_kmeans)

# 5.3 Abordagem estatística por GMM (Aula 3 e Aula 6): voos em região de baixa densidade
gmm_out <- Mclust(z)                     # sem G: o Mclust escolhe o número de componentes e o modelo pelo BIC
print(gmm_out$modelName); print(gmm_out$G)
densidade <- dens(data=z, modelName=gmm_out$modelName, parameters=gmm_out$parameters)
limiar_dens <- quantile(densidade, 0.025)   # os 2,5% de menor densidade
anomalo_gmm <- as.numeric(densidade < limiar_dens)
sum(anomalo_gmm)

# 5.4 Abordagem por clusterização hierárquica (Aula 6): voos em clusters muito pequenos
hc_average_out <- hclust(d_z, method='average')
clusterid_hc <- cutree(hc_average_out, k=20)
tamanho <- table(clusterid_hc)
pequenos <- as.numeric(names(tamanho[tamanho < 0.01*nrow(z)]))     # clusters com menos de 1% dos voos
anomalo_hc <- as.numeric(clusterid_hc %in% pequenos)
sum(anomalo_hc)

# 5.5 Consenso: anômalo se marcado por pelo menos 2 dos 4 critérios
votos <- anomalo_iqr + anomalo_kmeans + anomalo_gmm + anomalo_hc
data_train$anomalo <- as.numeric(votos >= 2)
table(votos)
sum(data_train$anomalo)
# Concordância entre os critérios
print(cor(cbind(iqr=anomalo_iqr, kmeans=anomalo_kmeans, gmm=anomalo_gmm, hc=anomalo_hc)))

# Figuras
png(paste0(dir_fig, '02_02_anomalias_cotovelo_silhouette.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
plot(1:8, var_total, type='b', pch=16, col=cor_1, lwd=2, xlab='k', ylab='Within Cluster Sum of Squares',
     main='k-means: cotovelo', panel.first=grid(col=cor_grade, lty=1))
plot(2:8, sil_media[2:8], type='b', pch=16, col=cor_1, lwd=2, xlab='k', ylab='Silhouette média',
     main='k-means: silhouette', panel.first=grid(col=cor_grade, lty=1))
points(k_anom, sil_media[k_anom], pch=21, cex=2.2, col=cor_2, lwd=2)
dev.off()

png(paste0(dir_fig, '02_03_anomalias_criterios.png'), width=2200, height=1800, res=reso)
par(estilo); par(mfrow=c(2,2))
criterios <- list(anomalo_iqr, anomalo_kmeans, anomalo_gmm, anomalo_hc)
names(criterios) <- c('Regra do boxplot (IQR, por cabeceira)', paste0('k-means: r_i > ', limiar_r),
                      'GMM: 2,5% de menor densidade', 'Hierárquica: clusters < 1% dos voos')
for (nome in names(criterios)){
  marca <- criterios[[nome]] == 1
  plot(jitter(data_train$nactive, 0.6), data_train$taxitime, pch=16, cex=0.4,
       col=ifelse(marca, cor_2, adjustcolor(cor_neutra, 0.35)), xlab='nactive', ylab='Tempo de táxi (s)',
       main=nome, panel.first=grid(col=cor_grade, lty=1))
  mtext(paste0(sum(marca), ' voos marcados'), side=3, line=0.2, cex=0.75, col=cor_texto2)
}
dev.off()

png(paste0(dir_fig, '02_04_anomalias_consenso.png'), width=larg, height=alt, res=reso)
par(estilo)
plot(jitter(data_train$nactive, 0.6), data_train$taxitime, pch=16, cex=0.45,
     col=ifelse(data_train$anomalo == 1, cor_2, adjustcolor(cor_1, 0.3)), xlab='Aeronaves taxiando no pushback (nactive)',
     ylab='Tempo de táxi (s)', main='Voos anômalos: marcados por pelo menos 2 dos 4 critérios',
     panel.first=grid(col=cor_grade, lty=1))
legend('topleft', legend=c(paste0('anômalo (', sum(data_train$anomalo), ')'), 'normal'), col=c(cor_2, cor_1),
       pch=16, bty='n', text.col=cor_texto2)
dev.off()

# Silhouette plot da solução k-means, como no Lab2
s_index <- silhouette(clusterid, d_z)
png(paste0(dir_fig, '02_05_anomalias_silhouette_plot.png'), width=1600, height=alt, res=reso)
par(estilo)
plot(s_index, col=c(cor_1, cor_2, cor_3, cor_neutra)[1:k_anom], border=NA, main='Silhouette — k-means (nactive, taxitime)')
dev.off()


#############################################################
# ETAPA 6: MATRIZES NUMÉRICAS NORMALIZADAS (kNN E REDE)     #
#############################################################


# O kNN mede distância, então as variáveis precisam estar na mesma escala (slide 16 da Aula 4), e a rede
#neural precisa de inputs numéricos. Transformamos os fatores em variáveis binárias (model.matrix) e
#normalizamos cada coluna: z = (x - média)/desvio padrão.
# A média e o desvio padrão vêm SÓ da base de treinamento e são aplicados também à base de teste.
# (Dentro da validação cruzada do Script 03 a normalização é refeita a cada fold, só com os folds de treino,
#para que o fold de validação não influencie a escala.)
# (A variável "domestico" fica de fora das fórmulas: ela é o nível "dom" da "regiao". Repeti-la dobraria o peso
#dessa informação na distância do kNN e deixaria a regressão linear com coeficiente redundante.)
formula_x <- ~ nactive + hora + dia_semana + runway + wtc + acft + airline + regiao + vento_ns + vento_lo + wx
X_train <- model.matrix(formula_x, data_train)[,-1]
X_test <- model.matrix(formula_x, data_test)[,-1]
centro <- apply(X_train, 2, mean)
escala <- apply(X_train, 2, sd)
manter <- escala > 0                                   # coluna constante no treino não pode ser normalizada
X_train_s <- scale(X_train[, manter], center=centro[manter], scale=escala[manter])
X_test_s <- scale(X_test[, manter], center=centro[manter], scale=escala[manter])
colnames(X_train_s) <- make.names(colnames(X_train_s))
colnames(X_test_s) <- make.names(colnames(X_test_s))
dim(X_train_s); dim(X_test_s)

# Fórmula comum dos métodos que trabalham com fórmula (lm, tree, svm)
formula_modelo <- taxitime ~ nactive + hora + dia_semana + runway + wtc + acft + airline + regiao + vento_ns + vento_lo + wx


#############################################################
# ETAPA 7: SALVAR A BASE PROCESSADA                         #
#############################################################


save(data, data_final, data_train, data_test, idxtrain, X_train, X_test, X_train_s, X_test_s, centro, escala, manter,
     formula_x, formula_modelo, file='data_project_prep.Rda')

# Resumo do pré-processamento para o relatório
resumo <- data.frame(item=c('voos rotulados', 'voos de treino', 'voos de teste interno', 'voos da submissão',
                            'colunas de input após model.matrix', 'anômalos (IQR)', 'anômalos (k-means)',
                            'anômalos (GMM)', 'anômalos (hierárquica)', 'anômalos (consenso >= 2)'),
                     valor=c(nrow(data), nrow(data_train), nrow(data_test), nrow(data_final), ncol(X_train_s),
                             sum(anomalo_iqr), sum(anomalo_kmeans), sum(anomalo_gmm), sum(anomalo_hc),
                             sum(data_train$anomalo)))
print(resumo)
write.csv(resumo, paste0(dir_res, '02_resumo_preprocessamento.csv'), row.names=FALSE)

# Fim do Script 02.
