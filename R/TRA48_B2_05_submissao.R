

##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 05: Modelo final e arquivo de submissão (entrega de 18/11, 9:00)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# Retreina o modelo escolhido no Script 04 com os 6.426 voos rotulados (treino + teste interno), aplica-o aos
#1.607 voos da base de teste da professora e grava o arquivo "data_project_test_<grupo>.Rda", com a coluna
#"taxitime" preenchida, na pasta "entrega/" ao lado da base.
#
# Hiperparâmetros: a árvore (tamanho) e o kNN (k) são escolhidos de novo por validação cruzada com a base completa,
#que é barato. A regressão linear não tem hiperparâmetro. SVM e rede neural mantêm os valores escolhidos no Script 03.

# Nome do grupo no arquivo de submissão (a tarefa pede "data_project_test_groupname.Rda")
nome_grupo <- 'HenriAntonioGilberto'

dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir_entrega <- paste0(dir_dados, 'entrega/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_entrega, showWarnings=FALSE, recursive=TRUE)

load("data_project_prep.Rda")
load("modelos.Rda")
load("escolha_final.Rda")

library(tree)
library(caret)
library(e1071)
library(neuralnet)
library(cluster)
library(mclust)

cor_1 <- '#2a78d6'; cor_2 <- '#eb6834'; cor_3 <- '#1baf7a'; cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'; cor_texto2 <- '#52514e'; cor_grade <- '#e4e3df'; cor_fundo <- '#fcfcfb'
cores_runway <- c('10L'=cor_1, '28R'=cor_2)
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
larg <- 2000; alt <- 1250; reso <- 220

print(resumo_escolha)


##############################################################
# ETAPA 1: BASE DE TREINAMENTO FINAL (OS 6.426 VOOS)         #
##############################################################


data_full <- data
f_mod <- if (usar_npush) update(formula_modelo, . ~ . + n_push30) else formula_modelo
f_lm <- if (usar_npush) update(formula_lm, . ~ . + n_push30) else formula_lm
f_x <- if (usar_npush) update(formula_x, ~ . + n_push30) else formula_x

# Se o Script 04 adotou a retirada dos voos anômalos, refazemos a detecção (mesmos 4 critérios e mesmos limiares
#do Script 02, Etapa 5) agora com a base completa, e retiramos os voos marcados por pelo menos 2 critérios.
if (usar_sem_anomalos){
  q1 <- tapply(data_full$taxitime, data_full$runway, quantile, 0.25)
  q3 <- tapply(data_full$taxitime, data_full$runway, quantile, 0.75)
  anomalo_iqr <- as.numeric(data_full$taxitime > (q3 + 1.5*(q3 - q1))[as.character(data_full$runway)])
  z <- scale(data_full[, c('nactive', 'taxitime')])
  d_z <- dist(z)
  sil_media <- numeric(8)
  for (k in 2:8){
    set.seed(1)
    kmeans_out <- kmeans(z, k, nstart=20)
    sil_media[k] <- mean(silhouette(kmeans_out$cluster, d_z)[, 'sil_width'])
  }
  set.seed(1)
  kmeans_out <- kmeans(z, which.max(sil_media), nstart=20)
  dist_centroide <- sqrt(rowSums((z - kmeans_out$centers[kmeans_out$cluster,])^2))
  anomalo_kmeans <- as.numeric(dist_centroide/ave(dist_centroide, kmeans_out$cluster) > 3)
  gmm_out <- Mclust(z)
  densidade <- dens(data=z, modelName=gmm_out$modelName, parameters=gmm_out$parameters)
  anomalo_gmm <- as.numeric(densidade < quantile(densidade, 0.025))
  clusterid_hc <- cutree(hclust(d_z, method='average'), k=20)
  tamanho <- table(clusterid_hc)
  anomalo_hc <- as.numeric(clusterid_hc %in% as.numeric(names(tamanho[tamanho < 0.01*nrow(z)])))
  data_full$anomalo <- as.numeric(anomalo_iqr + anomalo_kmeans + anomalo_gmm + anomalo_hc >= 2)
  print(sum(data_full$anomalo))
  data_full <- data_full[data_full$anomalo == 0, ]
}
dim(data_full)


##############################################################
# ETAPA 2: RETREINAR O MODELO FINAL E PREVER A BASE DE TESTE #
##############################################################


# A base de submissão tem o taxitime em branco (NA). Retiramos a coluna antes de prever: a função "predict" do SVM
#aplica "na.omit" à base inteira e, com a coluna de NA, descartaria todos os voos.
data_final_x <- data_final
data_final_x$taxitime <- NULL


if (modelo_final == 'M1_linear'){
  final_model <- lm(f_lm, data=data_full)
  yhat_final <- predict(final_model, data_final_x)
}

if (modelo_final == 'M1_log'){
  final_model <- lm(update(f_lm, log(.) ~ .), data=data_full)
  yhat_final <- exp(predict(final_model, data_final_x))*ifelse(versao_lm == 'log_smearing', mean(exp(residuals(final_model))), 1)
}

if (modelo_final == 'M2_arvore'){
  # Árvore completa, poda por validação cruzada 10-fold, como no Script 03 e no Lab4
  tree_model <- tree(f_mod, data=data_full, control=tree.control(nobs=nrow(data_full), mindev=0, minsize=10, mincut=5))
  set.seed(1)
  # Mesma validação cruzada do Script 03 (createFolds com o mesmo controle; a cv.tree recresce os folds com o
  #controle padrão e não distingue árvores grandes)
  idx <- createFolds(data_full$taxitime, k=10)
  mse_tree <- matrix(nrow=length(size_range), ncol=10)
  for (fold in 1:10){
    tree_fold <- tree(f_mod, data=data_full[-idx[[fold]], ],
                      control=tree.control(nobs=nrow(data_full) - length(idx[[fold]]), mindev=0, minsize=10, mincut=5))
    for (i in 1:length(size_range)){
      yhat <- predict(prune.tree(tree_fold, best=size_range[i]), data_full[idx[[fold]], ])
      mse_tree[i, fold] <- mean((yhat - data_full$taxitime[idx[[fold]]])^2)
    }
  }
  optimal_tree_size <- size_range[which.min(apply(mse_tree, 1, mean))]
  print(optimal_tree_size)
  final_model <- prune.tree(tree_model, best=optimal_tree_size)
  yhat_final <- predict(final_model, data_final_x)
}

if (modelo_final %in% c('M3_knn', 'M5_rede')){
  # Normalização com a média e o desvio padrão da base completa, aplicados à base de submissão
  X_full <- model.matrix(f_x, data_full)[, -1]
  X_final <- model.matrix(f_x, data_final_x)[, -1]
  centro_full <- apply(X_full, 2, mean)
  escala_full <- apply(X_full, 2, sd)
  escala_full[escala_full == 0] <- 1
  X_full_s <- scale(X_full, center=centro_full, scale=escala_full)
  X_final_s <- scale(X_final, center=centro_full, scale=escala_full)
  colnames(X_full_s) <- make.names(colnames(X_full_s))
  colnames(X_final_s) <- make.names(colnames(X_full_s))
}

if (modelo_final == 'M3_knn'){
  # k escolhido de novo por validação cruzada 5-fold, com a base completa (média dos MSE dos folds)
  set.seed(1)
  idx <- createFolds(data_full$taxitime, k=5)
  mse_knn <- matrix(nrow=length(k_range), ncol=5)
  for (i in 1:length(k_range)){
    for (fold in 1:5){
      Xa <- X_full[-idx[[fold]], ]
      Xv <- X_full[idx[[fold]], ]
      centro_f <- apply(Xa, 2, mean)
      escala_f <- apply(Xa, 2, sd)
      escala_f[escala_f == 0] <- 1
      knn_model <- knnreg(scale(Xa, center=centro_f, scale=escala_f), data_full$taxitime[-idx[[fold]]], k=k_range[i])
      yhat <- predict(knn_model, scale(Xv, center=centro_f, scale=escala_f))
      mse_knn[i, fold] <- mean((yhat - data_full$taxitime[idx[[fold]]])^2)
    }
  }
  optimal_k <- k_range[which.min(apply(mse_knn, 1, mean))]
  print(optimal_k)
  final_model <- knnreg(X_full_s, data_full$taxitime, k=optimal_k)
  yhat_final <- predict(final_model, X_final_s)
}

if (modelo_final == 'M4_svm'){
  final_model <- svm(f_mod, data=data_full, kernel=parametros_svm[['kernel']], cost=as.numeric(parametros_svm[['cost']]),
                     gamma=as.numeric(parametros_svm[['gamma']]), epsilon=as.numeric(parametros_svm[['epsilon']]))
  yhat_final <- predict(final_model, data_final_x)
}

if (modelo_final == 'M5_rede'){
  media_full <- mean(data_full$taxitime)
  dp_full <- sd(data_full$taxitime)
  f_nn <- as.formula(paste('y ~', paste(colnames(X_full_s), collapse=' + ')))
  set.seed(1)
  final_model <- neuralnet(f_nn, data=data.frame(X_full_s, y=(data_full$taxitime - media_full)/dp_full),
                           hidden=optimal_hidden, act.fct='logistic', linear.output=TRUE,
                           threshold=limiar_nn, stepmax=passos_nn)
  if (is.null(final_model$weights)) stop('A rede final não convergiu: aumentar passos_nn ou escolher o 2º modelo do ranking.')
  yhat_final <- as.numeric(predict(final_model, data.frame(X_final_s)))*dp_full + media_full
}

yhat_final <- as.numeric(yhat_final)
summary(yhat_final)


##############################################################
# ETAPA 3: MONTAR O ARQUIVO DE SUBMISSÃO                     #
##############################################################


# Recarregamos a base original para devolver o "data_test" com o mesmo formato, as mesmas colunas e a mesma ordem
#de linhas que a professora entregou. Só a coluna "taxitime" muda.
load("data_project.Rda")
data_test$taxitime <- yhat_final[match(data_test$id, data_final$id)]
arquivo_submissao <- paste0(dir_entrega, 'data_project_test_', nome_grupo, '.Rda')
save(data_test, file=arquivo_submissao)


##############################################################
# ETAPA 4: CONFERÊNCIAS ANTES DE ENVIAR                      #
##############################################################


# Recarregar o arquivo salvo, numa área limpa, e conferir
conferencia <- new.env()
load(arquivo_submissao, envir=conferencia)
sub <- conferencia$data_test
load("data_project.Rda", envir=conferencia)     # sobrescreve com o original, para comparar
original <- conferencia$data_test
load(arquivo_submissao, envir=conferencia)      # volta a submissão para o ambiente de conferência

checagens <- c(
  objeto_chama_data_test = exists('data_test', envir=conferencia),
  linhas_1607 = nrow(sub) == 1607,
  mesmas_colunas = identical(names(sub), names(original)),
  mesma_ordem_de_id = identical(as.character(sub$id), as.character(original$id)),
  nenhum_NA = sum(is.na(sub$taxitime)) == 0,
  todos_positivos = all(sub$taxitime > 0),
  faixa_plausivel = all(sub$taxitime > 0.5*min(data$taxitime) & sub$taxitime < 1.5*max(data$taxitime)),
  outras_colunas_intactas = identical(as.data.frame(sub)[, names(sub) != 'taxitime'],
                                      as.data.frame(original)[, names(original) != 'taxitime'])
)
print(checagens)
if (!isTRUE(all(checagens))) stop('ALGUMA CONFERÊNCIA FALHOU — não enviar o arquivo antes de corrigir.')

resumo_submissao <- rbind(treino_real=summary(data$taxitime), submissao_prevista=summary(sub$taxitime))
print(round(resumo_submissao, 1))
write.csv(round(resumo_submissao, 1), paste0(dir_res, '05_resumo_previsoes_submissao.csv'))
writeLines(c(paste0('arquivo = ', basename(arquivo_submissao)), paste0('modelo_final = ', modelo_final),
             paste0('voos_no_treinamento_final = ', nrow(data_full)),
             paste(names(checagens), checagens, sep=' = ')),
           paste0(dir_res, '05_conferencias_submissao.txt'))

# Figuras de conferência: a distribuição prevista deve ser parecida com a real, só mais concentrada
png(paste0(dir_fig, '05_01_previsoes_submissao.png'), width=larg, height=alt, res=reso)
par(estilo); par(mfrow=c(1,2))
hist(data$taxitime, breaks=40, freq=FALSE, col=adjustcolor(cor_neutra, 0.5), border=cor_fundo,
     xlab='Tempo de táxi (s)', ylab='Densidade', main='Real (treino) x previsto (submissão)',
     ylim=c(0, max(density(sub$taxitime)$y, density(data$taxitime)$y)*1.1))
lines(density(sub$taxitime), col=cor_2, lwd=2.5)
legend('topright', legend=c('real, 6.426 voos', 'previsto, 1.607 voos'), fill=c(adjustcolor(cor_neutra, 0.5), NA),
       border=c(cor_fundo, NA), lwd=c(NA, 2.5), col=c(NA, cor_2), bty='n', text.col=cor_texto2, cex=0.85)
boxplot(sub$taxitime ~ sub$runway, col=adjustcolor(cores_runway, 0.35), border=cores_runway, xlab='Cabeceira',
        ylab='Tempo de táxi previsto (s)', main='Previsões por cabeceira', outpch=16, outcex=0.4)
dev.off()

save(final_model, modelo_final, yhat_final, nome_grupo, file=paste0(dir_dados, 'modelo_final.Rda'))
cat('\nArquivo de submissão gravado em:', arquivo_submissao, '\n')

# Fim do Script 05.
