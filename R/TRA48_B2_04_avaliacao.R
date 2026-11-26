

##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 04: Avaliação do desempenho preditivo e escolha do modelo final (item 5 do relatório)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# 1. Compara os modelos ajustados no Script 03 na base de teste interna (data_test, 1.607 voos), com as três
#    métricas do enunciado (RMSE, MAE, MAPE — slide 36 da Aula 4) e o histograma de erros.
# 2. Mede a incerteza do RMSE por bootstrap (Aula 1).
# 3. Testa, por validação cruzada no treino, duas variações do pré-processamento para o modelo vencedor:
#    retirar os voos anômalos do treinamento (Script 02, Etapa 5) e acrescentar a feature "n_push30".
# 4. Escolhe o modelo final com uma regra fixada ANTES de olhar os números (Etapa 5).
#
# Saída: "escolha_final.Rda" (pasta da base), tabelas em "resultados/04_*" e figuras "figuras/04_*.png".

dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)

load("data_project_prep.Rda")
load("modelos.Rda")

library(tree)
library(caret)
library(e1071)
library(neuralnet)

cor_1 <- '#2a78d6'; cor_2 <- '#eb6834'; cor_3 <- '#1baf7a'; cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'; cor_texto2 <- '#52514e'; cor_grade <- '#e4e3df'; cor_fundo <- '#fcfcfb'
cores_runway <- c('10L'=cor_1, '28R'=cor_2)
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
larg <- 2000; alt <- 1250; reso <- 220

# Nomes dos modelos para tabelas e gráficos
rotulos <- c(M0_media='M0 baseline (média)', M0_cabeceira='M0 baseline (cabeceira)',
             M1_linear='M1 regressão linear', M1_log='M1 regressão linear (log)',
             M2_arvore='M2 árvore', M3_knn='M3 kNN', M4_svm='M4 SVM (extensão)', M5_rede='M5 rede neural')
modelos <- names(rotulos)
y <- data_test$taxitime


#######################################
# ETAPA 1: MÉTRICAS DE DESEMPENHO     #
#######################################


# Métricas de regressão (slide 36 da Aula 4), com o erro em segundos:
#   RMSE [s] = raiz( (1/n) soma (yhat - y)^2 )
#   MAE  [s] = (1/n) soma |yhat - y|
#   MAPE [%] = (100/n) soma |yhat - y| / y
# Unidades: no RMSE, raiz(s^2) = s; no MAPE, s/s é adimensional e x100 dá %. O menor taxitime da base é 434 s,
#então não há divisão por valores próximos de zero no MAPE.

metricas <- data.frame(modelo=modelos, rotulo=rotulos[modelos], RMSE=NA, MAE=NA, MAPE=NA, vies=NA)
for (m in modelos){
  yhat <- previsoes[[m]]
  if (all(is.na(yhat))) next                       # modelo sem previsão (rede que não convergiu)
  erro <- yhat - y
  metricas$RMSE[metricas$modelo == m] <- sqrt(mean(erro^2))
  metricas$MAE[metricas$modelo == m] <- mean(abs(erro))
  metricas$MAPE[metricas$modelo == m] <- mean(abs(erro)/y)*100
  metricas$vies[metricas$modelo == m] <- mean(erro)                     # erro médio (s): positivo = superestima
}
metricas <- metricas[order(metricas$RMSE), ]
metricas_tabela <- metricas
metricas_tabela[, c('RMSE', 'MAE', 'vies')] <- round(metricas_tabela[, c('RMSE', 'MAE', 'vies')], 1)
metricas_tabela$MAPE <- round(metricas_tabela$MAPE, 2)
print(metricas_tabela)
write.csv(metricas_tabela, paste0(dir_res, '04_metricas_teste.csv'), row.names=FALSE)

# Candidatos a modelo final: os cinco métodos de aprendizado (o baseline é só régua). Da regressão linear entra a
#versão escolhida por validação cruzada no Script 03 (não a de melhor desempenho no teste).
candidatos <- c(ifelse(versao_lm == 'linear', 'M1_linear', 'M1_log'), 'M2_arvore', 'M3_knn', 'M4_svm', 'M5_rede')
candidatos <- candidatos[!is.na(metricas$RMSE[match(candidatos, metricas$modelo)])]
ranking <- metricas[metricas$modelo %in% candidatos, ]
print(ranking[, c('rotulo', 'RMSE', 'MAE', 'MAPE')])


#######################################
# ETAPA 2: GRÁFICOS DE COMPARAÇÃO     #
#######################################


com_previsao <- metricas$modelo[!is.na(metricas$RMSE)]
primeiro <- ranking$modelo[1]

# Barras: as três métricas por modelo (o primeiro colocado entre os candidatos em laranja)
png(paste0(dir_fig, '04_01_metricas_por_modelo.png'), width=2600, height=1300, res=reso)
par(estilo); par(mfrow=c(1,3), mar=c(4.6,13,3.2,1.5))
for (metrica in c('RMSE', 'MAE', 'MAPE')){
  valores <- rev(metricas[[metrica]][!is.na(metricas$RMSE)])
  nomes <- rev(metricas$rotulo[!is.na(metricas$RMSE)])
  cores <- ifelse(rev(com_previsao) == primeiro, cor_2, ifelse(grepl('^M0', rev(com_previsao)), cor_neutra, cor_1))
  b <- barplot(valores, names.arg=nomes, horiz=TRUE, col=cores, border=NA, las=1, cex.names=0.85,
               xlab=ifelse(metrica == 'MAPE', 'MAPE (%)', paste0(metrica, ' (s)')), main=metrica,
               xlim=c(0, max(valores)*1.18))
  text(valores, b, labels=formatC(valores, format='f', digits=ifelse(metrica == 'MAPE', 1, 0)), pos=4, cex=0.8,
       col=cor_texto)
}
dev.off()

# Histogramas de erros — exigidos pelo enunciado. Mesma escala em todos os painéis, para comparação direta.
erros <- sapply(com_previsao, function(m) previsoes[[m]] - y)
limites <- quantile(erros, c(0.002, 0.998))
quebras <- seq(floor(limites[1]/50)*50 - 50, ceiling(limites[2]/50)*50 + 50, by=25)
n_paineis <- length(com_previsao)
png(paste0(dir_fig, '04_02_histogramas_de_erros.png'), width=2800, height=1500, res=reso)
par(estilo); par(mfrow=c(2, ceiling(n_paineis/2)), mar=c(4.4,4.6,3.6,1))
for (m in com_previsao){
  e <- pmin(pmax(erros[, m], min(quebras)), max(quebras))         # valores fora da escala vão para a última classe
  hist(e, breaks=quebras, col=ifelse(m == primeiro, cor_2, ifelse(grepl('^M0', m), cor_neutra, cor_1)), border=cor_fundo,
       xlab='Erro = previsto - real (s)', ylab='Número de voos', main=rotulos[m], cex.main=0.95)
  abline(v=0, col=cor_texto, lwd=1.5, lty=2)
  mtext(paste0('RMSE ', round(metricas$RMSE[metricas$modelo == m]), ' s · viés ', round(mean(erros[, m])), ' s'),
        side=3, line=0.2, cex=0.7, col=cor_texto2)
}
dev.off()

# Boxplot dos erros por modelo: viés (mediana fora de zero) e cauda
png(paste0(dir_fig, '04_03_boxplot_erros.png'), width=larg, height=alt, res=reso)
par(estilo); par(mar=c(9,5,3.2,1.2))
boxplot(erros[, com_previsao], names=rotulos[com_previsao], las=2, cex.axis=0.75, outpch=16, outcex=0.3,
        col=adjustcolor(ifelse(com_previsao == primeiro, cor_2, ifelse(grepl('^M0', com_previsao), cor_neutra, cor_1)), 0.35),
        border=ifelse(com_previsao == primeiro, cor_2, ifelse(grepl('^M0', com_previsao), cor_neutra, cor_1)),
        ylab='Erro = previsto - real (s)', main='Distribuição dos erros na base de teste')
abline(h=0, col=cor_texto, lty=2)
dev.off()

# Real x previsto, para os dois melhores candidatos
png(paste0(dir_fig, '04_04_real_x_previsto.png'), width=larg, height=1100, res=reso)
par(estilo); par(mfrow=c(1,2))
for (m in ranking$modelo[1:min(2, nrow(ranking))]){
  plot(y, previsoes[[m]], pch=16, cex=0.4, col=adjustcolor(cores_runway[as.character(data_test$runway)], 0.4),
       xlab='Tempo de táxi real (s)', ylab='Tempo de táxi previsto (s)', main=rotulos[m], asp=1,
       xlim=range(y), ylim=range(y), panel.first=grid(col=cor_grade, lty=1))
  abline(0, 1, col=cor_texto, lwd=1.5)
  legend('topleft', legend=c('10L', '28R', 'previsto = real'), col=c(cor_1, cor_2, cor_texto), pch=c(16, 16, NA),
         lty=c(NA, NA, 1), bty='n', text.col=cor_texto2, cex=0.85)
}
dev.off()

# Erro do melhor candidato por situação operacional
e1 <- previsoes[[primeiro]] - y
png(paste0(dir_fig, '04_05_erro_por_situacao.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
boxplot(e1 ~ data_test$runway, col=adjustcolor(cores_runway, 0.35), border=cores_runway, xlab='Cabeceira',
        ylab='Erro (s)', main=paste0(rotulos[primeiro], ': erro por cabeceira'), outpch=16, outcex=0.4, cex.main=0.95)
abline(h=0, col=cor_texto, lty=2)
faixa_nactive <- cut(data_test$nactive, breaks=c(-1, 2, 5, 8, 11, 30), labels=c('0-2', '3-5', '6-8', '9-11', '12+'))
boxplot(e1 ~ faixa_nactive, col=adjustcolor(cor_1, 0.35), border=cor_1, xlab='Aeronaves taxiando no pushback',
        ylab='Erro (s)', main='Erro por nível de congestionamento', outpch=16, outcex=0.4, cex.main=0.95)
abline(h=0, col=cor_texto, lty=2)
dev.off()


#######################################
# ETAPA 3: INCERTEZA DO RMSE (BOOTSTRAP) #
#######################################


# Bootstrap (Aula 1): reamostramos, com reposição, os 1.607 voos de teste e recalculamos o RMSE. Repetindo 2.000
#vezes, os percentis 2,5% e 97,5% dão um intervalo de 95% para o RMSE de cada modelo.
# Para comparar dois modelos, reamostramos OS MESMOS voos para os dois (bootstrap pareado) e olhamos a diferença:
#se o intervalo da diferença contém o zero, o teste não distingue os dois modelos.
B <- 2000
set.seed(1)
amostras <- matrix(sample(1:length(y), length(y)*B, replace=TRUE), ncol=B)
rmse_boot <- sapply(com_previsao, function(m) apply(amostras, 2, function(i) sqrt(mean(erros[i, m]^2))))
ic_rmse <- t(apply(rmse_boot, 2, quantile, c(0.025, 0.975)))
print(round(ic_rmse, 1))

# Diferença pareada entre o 1º colocado e cada um dos outros candidatos
comparacao <- data.frame(modelo=ranking$modelo[-1], dif_rmse=NA, ic_inferior=NA, ic_superior=NA)
for (m in comparacao$modelo){
  dif <- rmse_boot[, m] - rmse_boot[, primeiro]                    # > 0: o outro modelo é pior
  comparacao[comparacao$modelo == m, c('dif_rmse', 'ic_inferior', 'ic_superior')] <-
    c(metricas$RMSE[metricas$modelo == m] - metricas$RMSE[metricas$modelo == primeiro], quantile(dif, c(0.025, 0.975)))
}
comparacao$empata_com_o_primeiro <- comparacao$ic_inferior <= 0
comparacao[, 2:4] <- round(comparacao[, 2:4], 1)
print(comparacao)
write.csv(data.frame(modelo=com_previsao, rotulo=rotulos[com_previsao], RMSE=round(metricas$RMSE[match(com_previsao, metricas$modelo)], 1),
                     ic95_inferior=round(ic_rmse[, 1], 1), ic95_superior=round(ic_rmse[, 2], 1)),
          paste0(dir_res, '04_bootstrap_ic_rmse.csv'), row.names=FALSE)
write.csv(comparacao, paste0(dir_res, '04_bootstrap_comparacao_pareada.csv'), row.names=FALSE)

png(paste0(dir_fig, '04_06_bootstrap_rmse.png'), width=larg, height=alt, res=reso)
par(estilo); par(mar=c(4.6,13,3.2,1.5))
ordem_b <- rev(com_previsao)
plot(metricas$RMSE[match(ordem_b, metricas$modelo)], 1:length(ordem_b), xlim=range(ic_rmse), pch=16, cex=1.3,
     col=ifelse(ordem_b == primeiro, cor_2, ifelse(grepl('^M0', ordem_b), cor_neutra, cor_1)), yaxt='n', ylab='',
     xlab='RMSE na base de teste (s), com intervalo de 95% por bootstrap', main='Incerteza do RMSE',
     panel.first=grid(ny=NA, col=cor_grade, lty=1))
segments(ic_rmse[ordem_b, 1], 1:length(ordem_b), ic_rmse[ordem_b, 2], 1:length(ordem_b), lwd=3,
         col=ifelse(ordem_b == primeiro, cor_2, ifelse(grepl('^M0', ordem_b), cor_neutra, cor_1)))
axis(2, at=1:length(ordem_b), labels=rotulos[ordem_b], las=1, cex.axis=0.85)
dev.off()


##############################################
# ETAPA 4: INTERPRETAÇÃO DOS MODELOS         #
##############################################


# Variáveis usadas pela árvore podada (as primeiras divisões são as mais importantes)
print(summary(best_pruned_tree_model)$used)

# Efeitos estimados pela regressão linear (em segundos), com intervalo de +/- 2 erros padrão
tabela_coef <- summary(lm_model)$coefficients[-1, ]
tabela_coef <- tabela_coef[order(abs(tabela_coef[, 1])), ]
png(paste0(dir_fig, '04_07_efeitos_regressao_linear.png'), width=larg, height=2200, res=reso)
par(estilo); par(mar=c(4.6,10,3.2,1.5))
cor_coef <- ifelse(tabela_coef[, 4] < 0.05, cor_1, cor_neutra)
plot(tabela_coef[, 1], 1:nrow(tabela_coef), pch=16, col=cor_coef, yaxt='n', ylab='',
     xlim=range(c(tabela_coef[, 1] - 2*tabela_coef[, 2], tabela_coef[, 1] + 2*tabela_coef[, 2])),
     xlab='Efeito sobre o tempo de táxi (s)', main='Regressão linear: efeito de cada variável',
     panel.first=grid(ny=NA, col=cor_grade, lty=1))
segments(tabela_coef[, 1] - 2*tabela_coef[, 2], 1:nrow(tabela_coef), tabela_coef[, 1] + 2*tabela_coef[, 2],
         1:nrow(tabela_coef), col=cor_coef, lwd=2)
abline(v=0, col=cor_texto, lty=2)
axis(2, at=1:nrow(tabela_coef), labels=rownames(tabela_coef), las=1, cex.axis=0.65)
legend('bottomright', legend=c('p < 0,05', 'p >= 0,05'), col=c(cor_1, cor_neutra), pch=16, bty='n', text.col=cor_texto2)
dev.off()


#####################################################################
# ETAPA 5: EXPERIMENTOS DE PRÉ-PROCESSAMENTO COM O MODELO VENCEDOR  #
#####################################################################


# Duas perguntas deixadas em aberto pelo Script 02, testadas com o modelo que ficou em 1º lugar:
#   (a) retirar do treinamento os voos marcados como anômalos melhora a previsão?
#   (b) a feature "n_push30" (pushbacks nos 30 minutos anteriores) melhora a previsão?
# Para não escolher nada olhando a base de teste, a comparação é feita por validação cruzada 5-fold DENTRO de
#data_train, com os hiperparâmetros já escolhidos no Script 03. Na variante (a), os anômalos saem só dos folds de
#treino: o fold de validação continua com eles, porque a base da professora também terá voos assim.
# Regra de adoção: a variante só é adotada se o intervalo de 95% (bootstrap pareado sobre as previsões fora do
#fold) da redução do RMSE ficar inteiro acima de zero. Na dúvida, fica o pré-processamento mais simples.

modelo_vencedor <- primeiro
variantes <- c('base', 'sem_anomalos', 'com_npush')
formula_x_npush <- update(formula_x, ~ . + n_push30)
formula_modelo_npush <- update(formula_modelo, . ~ . + n_push30)
formula_lm_npush <- update(formula_lm, . ~ . + n_push30)
previsao_oof <- matrix(NA, nrow=nrow(data_train), ncol=length(variantes), dimnames=list(NULL, variantes))

set.seed(1)
idx <- createFolds(data_train$taxitime, k=5)
inicio <- Sys.time()
for (v in variantes){
  for (fold in 1:5){
    treino <- data_train[-idx[[fold]],]
    validacao <- data_train[idx[[fold]],]
    if (v == 'sem_anomalos') treino <- treino[treino$anomalo == 0, ]
    f_mod <- if (v == 'com_npush') formula_modelo_npush else formula_modelo
    f_lm <- if (v == 'com_npush') formula_lm_npush else formula_lm
    f_x <- if (v == 'com_npush') formula_x_npush else formula_x

    if (modelo_vencedor %in% c('M1_linear', 'M1_log')){
      if (modelo_vencedor == 'M1_linear'){
        m <- lm(f_lm, data=treino)
        yhat <- predict(m, validacao)
      } else {
        m <- lm(update(f_lm, log(.) ~ .), data=treino)
        yhat <- exp(predict(m, validacao))*ifelse(versao_lm == 'log_smearing', mean(exp(residuals(m))), 1)
      }
    }
    if (modelo_vencedor == 'M2_arvore'){
      m <- tree(f_mod, data=treino, control=tree.control(nobs=nrow(treino), mindev=0, minsize=10, mincut=5))
      m <- prune.tree(m, best=optimal_tree_size)
      yhat <- predict(m, validacao)
    }
    if (modelo_vencedor %in% c('M3_knn', 'M5_rede')){
      Xa <- model.matrix(f_x, treino)[, -1]
      Xv <- model.matrix(f_x, validacao)[, -1]
      centro_f <- apply(Xa, 2, mean)
      escala_f <- apply(Xa, 2, sd)
      escala_f[escala_f == 0] <- 1
      Xa <- scale(Xa, center=centro_f, scale=escala_f)
      Xv <- scale(Xv, center=centro_f, scale=escala_f)
      colnames(Xa) <- make.names(colnames(Xa))
      colnames(Xv) <- make.names(colnames(Xv))
      if (modelo_vencedor == 'M3_knn'){
        m <- knnreg(Xa, treino$taxitime, k=optimal_k)
        yhat <- predict(m, Xv)
      } else {
        media_f <- mean(treino$taxitime)
        dp_f <- sd(treino$taxitime)
        f_nn <- as.formula(paste('y ~', paste(colnames(Xa), collapse=' + ')))
        set.seed(1)
        m <- neuralnet(f_nn, data=data.frame(Xa, y=(treino$taxitime - media_f)/dp_f), hidden=optimal_hidden,
                       act.fct='logistic', linear.output=TRUE, threshold=limiar_nn, stepmax=passos_nn)
        yhat <- if (is.null(m$weights)) rep(NA, nrow(validacao)) else as.numeric(predict(m, data.frame(Xv)))*dp_f + media_f
      }
    }
    if (modelo_vencedor == 'M4_svm'){
      m <- svm(f_mod, data=treino, kernel=parametros_svm[['kernel']], cost=as.numeric(parametros_svm[['cost']]),
               gamma=as.numeric(parametros_svm[['gamma']]), epsilon=as.numeric(parametros_svm[['epsilon']]))
      yhat <- predict(m, validacao)
    }
    previsao_oof[idx[[fold]], v] <- as.numeric(yhat)
  }
  cat('variante', v, 'concluída\n')
}
tempo_experimentos <- as.numeric(difftime(Sys.time(), inicio, units='secs'))

# RMSE de validação cruzada de cada variante e intervalo da redução em relação à base (bootstrap pareado)
erro_oof <- previsao_oof - data_train$taxitime
rmse_oof <- sqrt(colMeans(erro_oof^2))
set.seed(1)
amostras_oof <- matrix(sample(1:nrow(data_train), nrow(data_train)*B, replace=TRUE), ncol=B)
experimentos <- data.frame(variante=variantes, rmse_cv=round(rmse_oof, 2), reducao_rmse=NA, ic_inferior=NA,
                           ic_superior=NA, adotar=FALSE)
for (v in variantes[-1]){
  reducao <- apply(amostras_oof, 2, function(i) sqrt(mean(erro_oof[i, 'base']^2)) - sqrt(mean(erro_oof[i, v]^2)))
  ic <- quantile(reducao, c(0.025, 0.975), na.rm=TRUE)
  experimentos[experimentos$variante == v, c('reducao_rmse', 'ic_inferior', 'ic_superior')] <-
    round(c(rmse_oof['base'] - rmse_oof[v], ic), 2)
  experimentos$adotar[experimentos$variante == v] <- !is.na(ic[1]) && ic[1] > 0
}
print(experimentos)
write.csv(experimentos, paste0(dir_res, '04_experimentos_preprocessamento.csv'), row.names=FALSE)

usar_sem_anomalos <- experimentos$adotar[experimentos$variante == 'sem_anomalos']
usar_npush <- experimentos$adotar[experimentos$variante == 'com_npush']


#######################################
# ETAPA 6: ESCOLHA DO MODELO FINAL    #
#######################################


# Regra (fixada antes de rodar):
#   1. menor RMSE na base de teste interna, que é a métrica do desafio;
#   2. se o bootstrap pareado não distinguir o 1º colocado de outro candidato (intervalo da diferença contém zero),
#      desempata o menor MAE;
#   3. persistindo o empate, o modelo mais simples de explicar, na ordem: regressão linear, árvore, kNN, SVM, rede.
empatados <- c(primeiro, comparacao$modelo[comparacao$empata_com_o_primeiro])
if (length(empatados) > 1){
  mae_empatados <- metricas$MAE[match(empatados, metricas$modelo)]
  # MAE dentro de 1 s é considerado empate também
  finalistas <- empatados[mae_empatados <= min(mae_empatados) + 1]
  ordem_simplicidade <- c('M1_linear', 'M1_log', 'M2_arvore', 'M3_knn', 'M4_svm', 'M5_rede')
  modelo_final <- ordem_simplicidade[ordem_simplicidade %in% finalistas][1]
} else {
  modelo_final <- primeiro
}
cat('\nMODELO FINAL:', rotulos[modelo_final], '\n')
cat('Retirar anômalos do treinamento:', usar_sem_anomalos, '\n')
cat('Usar a feature n_push30:', usar_npush, '\n')

# Se o modelo final não for o vencedor do experimento, os experimentos valem só como indicação: mantemos o
#pré-processamento base, que é o mesmo com que todos os modelos foram comparados.
if (modelo_final != modelo_vencedor){
  usar_sem_anomalos <- FALSE
  usar_npush <- FALSE
}

resumo_escolha <- c(modelo_final=modelo_final, rotulo=rotulos[[modelo_final]],
                    rmse_teste=round(metricas$RMSE[metricas$modelo == modelo_final], 1),
                    mae_teste=round(metricas$MAE[metricas$modelo == modelo_final], 1),
                    mape_teste=round(metricas$MAPE[metricas$modelo == modelo_final], 2),
                    empatados_no_bootstrap=paste(empatados, collapse=', '),
                    usar_sem_anomalos=usar_sem_anomalos, usar_npush=usar_npush,
                    tempo_experimentos_s=round(tempo_experimentos))
print(resumo_escolha)
writeLines(paste(names(resumo_escolha), resumo_escolha, sep=' = '), paste0(dir_res, '04_escolha_modelo_final.txt'))

save(modelo_final, usar_sem_anomalos, usar_npush, metricas, ranking, comparacao, experimentos, resumo_escolha,
     file='escolha_final.Rda')

# Fim do Script 04.
