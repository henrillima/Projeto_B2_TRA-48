

##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 03: Treinamento dos modelos de previsão do tempo de táxi (item 4 do relatório)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# Seis modelos, cada um no padrão do Lab em que o método foi visto:
#   M0  baseline: média do treino (e mediana por cabeceira)
#   M1  regressão linear (Aula 5), com e sem transformação logarítmica do output
#   M2  árvore de regressão (Lab4, Etapa 1; Lab6, Etapa 2)
#   M3  kNN de regressão (Lab4, Etapa 2)
#   M4  SVM de regressão (Lab5, Etapa 1; Lab6, Etapa 3) — EXTENSÃO: em aula o SVM foi visto só para classificação
#   M5  rede neural de regressão (Lab5, Etapa 2)
#
# Regra da validação: todos os hiperparâmetros são escolhidos por validação cruzada DENTRO de data_train.
#A base data_test só é usada no Script 04, para comparar os modelos já ajustados.
#
# Agregação dos erros entre os folds (média x mediana): o slide 9 da Aula 4 manda escolher o modelo de
#"smallest average validation error"; o código do kNN no Lab4 usa a mediana. Calculamos as duas e decidimos
#pela MÉDIA DO ERRO QUADRÁTICO dos folds. Motivo: a métrica do desafio é o RMSE sobre os 1.607 voos de teste,
#que é a raiz da média dos erros quadráticos de todos os voos. A média dos MSE dos folds estima exatamente essa
#quantidade; a mediana descarta a informação dos folds com erros grandes, que é justamente o que o RMSE penaliza.
#
# Saída: "modelos.Rda" (pasta da base) e figuras "figuras/03_*.png".

dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)

# Carregar a base processada no Script 02
load("data_project_prep.Rda")

# Pacotes (instalar UMA vez, no console): install.packages(c('tree', 'caret', 'e1071', 'neuralnet'))
library(tree)
library(caret)
library(e1071)
library(neuralnet)

# Paleta e estilo dos gráficos (mesmos dos Scripts 01 e 02)
cor_1 <- '#2a78d6'; cor_2 <- '#eb6834'; cor_3 <- '#1baf7a'; cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'; cor_texto2 <- '#52514e'; cor_grade <- '#e4e3df'; cor_fundo <- '#fcfcfb'
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
larg <- 2000; alt <- 1250; reso <- 220

# Tempo de execução de cada etapa, para o relatório
tempos <- c()


######################
# ETAPA 1: BASELINE  #
######################


# Sem uma régua não se sabe se um modelo é bom. O baseline mais simples prevê, para todo voo, a média do
#tempo de táxi do treino. O segundo baseline usa só a cabeceira, a variável categórica de maior efeito (Script 01).
yhat_base <- rep(mean(data_train$taxitime), nrow(data_test))
mediana_runway <- tapply(data_train$taxitime, data_train$runway, median)
yhat_base_runway <- as.numeric(mediana_runway[as.character(data_test$runway)])
print(mediana_runway)


################################
# ETAPA 2: REGRESSÃO LINEAR    #
################################


# Regressão linear por mínimos quadrados (slide "Linear Regression", Aula 5), com a função "lm" do pacote básico do R.
# A hora entra como faixa horária (fator), porque a relação entre hora e taxitime não é linear (Script 01).
formula_lm <- taxitime ~ nactive + faixa + dia_semana + runway + wtc + acft + airline + regiao + vento_ns + vento_lo + wx

# O slide da Aula 5 sugere transformar as variáveis quando a relação não é linear. Como o taxitime tem cauda
#longa à direita (média acima da mediana; Script 01), testamos também o modelo para log(taxitime). Ao voltar para segundos com exp(),
#a previsão subestima a média (exp da média de log não é a média); a correção de "smearing" multiplica a previsão
#por mean(exp(resíduos)). Comparamos as três versões por validação cruzada 10-fold no treino:
#   (a) taxitime  ·  (b) log(taxitime), volta com exp  ·  (c) log(taxitime), volta com exp x smearing
set.seed(1)
idx <- createFolds(data_train$taxitime, k=10)
mse_lm <- matrix(nrow=3, ncol=10, dimnames=list(c('linear', 'log', 'log_smearing'), NULL))
for (fold in 1:10){
  treino <- data_train[-idx[[fold]],]
  validacao <- data_train[idx[[fold]],]
  m_lin <- lm(formula_lm, data=treino)
  m_log <- lm(update(formula_lm, log(.) ~ .), data=treino)
  smearing <- mean(exp(residuals(m_log)))
  yhat_lin <- predict(m_lin, validacao)
  yhat_log <- exp(predict(m_log, validacao))
  mse_lm['linear', fold] <- mean((yhat_lin - validacao$taxitime)^2)
  mse_lm['log', fold] <- mean((yhat_log - validacao$taxitime)^2)
  mse_lm['log_smearing', fold] <- mean((yhat_log*smearing - validacao$taxitime)^2)
}
crossvalidation_rmse_lm <- sqrt(apply(mse_lm, 1, mean))
print(round(crossvalidation_rmse_lm, 2))
versao_lm <- names(which.min(crossvalidation_rmse_lm))
print(versao_lm)

# Ajustar as três versões com o treino inteiro e prever a base de teste
lm_model <- lm(formula_lm, data=data_train)
summary(lm_model)
yhat_lm <- predict(lm_model, data_test)

lm_log_model <- lm(update(formula_lm, log(.) ~ .), data=data_train)
summary(lm_log_model)
smearing_lm <- mean(exp(residuals(lm_log_model)))
yhat_lmlog <- exp(predict(lm_log_model, data_test))*ifelse(versao_lm == 'log_smearing', smearing_lm, 1)

# Alguns coeficientes saem NA: são termos redundantes ("aliased"). Algumas companhias operam um único conjunto de
#tipos de aeronave (por exemplo, toda a frota de uma companhia está em poucos tipos), então a variável binária da
#companhia é combinação exata das variáveis de aeronave. O "lm" descarta o termo redundante; a previsão não muda.
termos_redundantes <- names(coef(lm_model))[is.na(coef(lm_model))]
print(termos_redundantes)

# Coeficientes da regressão linear (em segundos), para a interpretação no relatório
tabela_coef <- summary(lm_model)$coefficients
coeficientes_lm <- data.frame(termo=rownames(tabela_coef), coeficiente_s=round(tabela_coef[, 1], 1),
                              erro_padrao_s=round(tabela_coef[, 2], 1), p_valor=signif(tabela_coef[, 4], 3))
write.csv(coeficientes_lm, paste0(dir_res, '03_coeficientes_regressao_linear.csv'), row.names=FALSE)
writeLines(termos_redundantes, paste0(dir_res, '03_termos_redundantes_regressao_linear.txt'))


##############################################
# ETAPA 3: ÁRVORE DE DECISÃO (REGRESSÃO)     #
##############################################


# Mesmo procedimento do Lab4 (Etapa 1) e do Lab6 (Etapa 2). Como o output é numérico, a função "tree" constrói uma
#árvore de regressão: a impureza de cada nó passa a ser medida pelo erro quadrático (slide "Decision Tree", Aula 5),
#e a previsão de cada folha é a média do taxitime dos voos daquela folha.

inicio <- Sys.time()

# Gerar a árvore grande, para depois podar, como no Lab4. Diferença em relação ao Lab4: lá o controle é
#mindev=0, minsize=2, mincut=1 (crescer até folhas puras). Com output contínuo quase toda folha só fica pura
#com 1 voo, e a árvore passa de 30 níveis, o limite do pacote "tree" (erro "maximum depth reached").
#Mantemos mindev=0 (crescer até não haver mais divisão possível) e usamos o minsize=10 e o mincut=5 padrão
#do tree.control: nenhuma folha com menos de 5 voos. A árvore continua bem maior que a podada (centenas de
#folhas), então a poda por validação cruzada é que decide o tamanho, como no Lab.
tree_model <- tree(formula_modelo, data=data_train,
                   control=tree.control(nobs=nrow(data_train), mindev=0, minsize=10, mincut=5))
summary(tree_model)

# Validação cruzada 10-fold com a função do Lab4, "cv.tree"
set.seed(1)
cv_results <- cv.tree(tree_model, FUN=prune.tree, K=10)
# Obs: para árvore de regressão, "dev" é a soma dos erros quadráticos de validação nos 10 folds. Dividindo pelo
#número de voos e tirando a raiz, obtemos o RMSE de validação cruzada (a mesma métrica dos outros métodos).
cv_rmse_cvtree <- sqrt(cv_results$dev/nrow(data_train))
print(table(round(cv_rmse_cvtree, 1)))
# Obs: na primeira execução, o RMSE da "cv.tree" ficou exatamente igual (155,9 s) para todos os tamanhos de 9 a
#756 folhas. Motivo: dentro de cada fold a "cv.tree" cresce a árvore de novo com o tree.control padrão
#(mindev=0.01), e não com o controle que usamos acima. As árvores dos folds ficam pequenas e não há como
#avaliar árvores maiores; o "which.min" cai no primeiro elemento do empate, que é a árvore inteira (756 folhas).
#Por isso a escolha do tamanho é feita com a validação cruzada do kNN do Lab4 (createFolds): em cada fold a
#árvore é crescida com o mesmo controle, podada em cada tamanho e avaliada no fold de validação.
set.seed(1)
idx <- createFolds(data_train$taxitime, k=10)
size_range <- c(2:20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 100, 125, 150, 200, 250, 300, 400, 500)
mse_tree <- matrix(nrow=length(size_range), ncol=10)
for (fold in 1:10){
  tree_fold <- tree(formula_modelo, data=data_train[-idx[[fold]], ],
                    control=tree.control(nobs=nrow(data_train) - length(idx[[fold]]), mindev=0, minsize=10, mincut=5))
  for (i in 1:length(size_range)){
    pruned_fold <- prune.tree(tree_fold, best=size_range[i])
    yhat <- predict(pruned_fold, data_train[idx[[fold]], ])
    mse_tree[i, fold] <- mean((yhat - data_train$taxitime[idx[[fold]]])^2)
  }
}
cv_rmse_tree <- sqrt(apply(mse_tree, 1, mean))           # média dos MSE dos folds (critério adotado)
cv_rmse_tree_mediana <- sqrt(apply(mse_tree, 1, median))
print(round(cbind(folhas=size_range, media=cv_rmse_tree, mediana=cv_rmse_tree_mediana), 2))

# Índice e tamanho (número de folhas) da árvore de menor erro
min_idx <- which.min(cv_rmse_tree)
optimal_tree_size <- size_range[min_idx]
print(optimal_tree_size)

# Podar a árvore com o tamanho ótimo
best_pruned_tree_model <- prune.tree(tree_model, best=optimal_tree_size)

# Prever a base de teste
yhat_tree <- predict(best_pruned_tree_model, data_test)

tempos['arvore'] <- as.numeric(difftime(Sys.time(), inicio, units='secs'))

# Figuras: curva de validação cruzada e árvore podada
png(paste0(dir_fig, '03_01_arvore_validacao_cruzada.png'), width=larg, height=alt, res=reso)
par(estilo)
ordem_cv <- order(cv_results$size)
plot(size_range, cv_rmse_tree, type='b', pch=16, cex=0.8, col=cor_1, lwd=2, log='x',
     ylim=range(c(cv_rmse_tree, cv_rmse_cvtree)),
     xlab='Tamanho da árvore (número de folhas, escala log)', ylab='RMSE de validação cruzada (s)',
     main='Árvore de regressão: poda por validação cruzada 10-fold', panel.first=grid(col=cor_grade, lty=1))
lines(cv_results$size[ordem_cv], cv_rmse_cvtree[ordem_cv], col=cor_neutra, lwd=2, lty=2)
points(optimal_tree_size, cv_rmse_tree[min_idx], pch=21, cex=2.2, col=cor_2, lwd=2)
legend('topright', legend=c('createFolds, mesmo controle (critério adotado)', 'cv.tree (árvores dos folds com controle padrão)',
                            paste0('ótimo: ', optimal_tree_size, ' folhas')),
       col=c(cor_1, cor_neutra, cor_2), lty=c(1, 2, NA), pch=c(16, NA, 21), lwd=2, pt.cex=c(0.8, 1, 1.6), bty='n',
       text.col=cor_texto2)
dev.off()

# Para a figura do relatório, uma árvore legível: a poda ótima pode ter dezenas de folhas. Se tiver mais de 12,
#desenhamos também a versão podada em 12 folhas, só para interpretação (a previsão usa a árvore ótima).
png(paste0(dir_fig, '03_02_arvore_podada.png'), width=2400, height=1500, res=reso)
par(estilo); par(mar=c(1,1,3,1))
arvore_figura <- if (optimal_tree_size > 12) prune.tree(tree_model, best=12) else best_pruned_tree_model
plot(arvore_figura, col=cor_texto2)
text(arvore_figura, cex=0.6, col=cor_texto, pretty=0, digits=4)
title(main=paste0('Árvore de regressão', ifelse(optimal_tree_size > 12, ' (primeiras 12 folhas, para leitura)', '')))
dev.off()


######################################
# ETAPA 4: K-NEAREST NEIGHBORS (KNN) #
######################################


# Mesmo procedimento do Lab4 (Etapa 2), com a função "knnreg", a versão de regressão da "knn3" no pacote "caret".
#Na regressão, a previsão é a média do taxitime dos k vizinhos mais próximos (slide "K-Nearest Neighbors", Aula 5).
# O kNN mede distâncias, então usamos as matrizes normalizadas do Script 02. Dentro da validação cruzada, a
#normalização é refeita a cada fold, com a média e o desvio padrão só dos folds de treino.

inicio <- Sys.time()

# Validação cruzada 5-fold para determinar o valor ótimo de k (Lab4)
set.seed(1)
idx <- createFolds(data_train$taxitime, k=5)
k_range <- c(1, 3, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100)
mse_knn <- matrix(nrow=length(k_range), ncol=5)
for (i in 1:length(k_range)){
  for (fold in 1:5){
    Xa <- X_train[-idx[[fold]], manter]
    Xv <- X_train[idx[[fold]], manter]
    centro_f <- apply(Xa, 2, mean)
    escala_f <- apply(Xa, 2, sd)
    escala_f[escala_f == 0] <- 1
    Xa <- scale(Xa, center=centro_f, scale=escala_f)
    Xv <- scale(Xv, center=centro_f, scale=escala_f)
    knn_model <- knnreg(Xa, data_train$taxitime[-idx[[fold]]], k=k_range[i])
    yhat <- predict(knn_model, Xv)
    mse_knn[i, fold] <- mean((yhat - data_train$taxitime[idx[[fold]]])^2)
  }
}
crossvalidation_rmse_media <- sqrt(apply(mse_knn, 1, mean))       # média dos MSE dos folds (critério adotado)
crossvalidation_rmse_mediana <- sqrt(apply(mse_knn, 1, median))   # mediana, como no código do Lab4
print(round(cbind(k=k_range, media=crossvalidation_rmse_media, mediana=crossvalidation_rmse_mediana), 2))

optimal_k <- k_range[which.min(crossvalidation_rmse_media)]
optimal_k_mediana <- k_range[which.min(crossvalidation_rmse_mediana)]
print(c(k_otimo_media=optimal_k, k_otimo_mediana=optimal_k_mediana))

# Aprender o modelo kNN com o valor ótimo de k, usando a base de treinamento inteira
best_knn_model <- knnreg(X_train_s, data_train$taxitime, k=optimal_k)
yhat_knn <- predict(best_knn_model, X_test_s)

tempos['knn'] <- as.numeric(difftime(Sys.time(), inicio, units='secs'))

png(paste0(dir_fig, '03_03_knn_validacao_cruzada.png'), width=larg, height=alt, res=reso)
par(estilo)
plot(k_range, crossvalidation_rmse_media, type='b', pch=16, col=cor_1, lwd=2,
     ylim=range(c(crossvalidation_rmse_media, crossvalidation_rmse_mediana)),
     xlab='k (número de vizinhos)', ylab='RMSE de validação cruzada (s)', main='kNN: escolha de k por validação cruzada 5-fold',
     panel.first=grid(col=cor_grade, lty=1))
lines(k_range, crossvalidation_rmse_mediana, type='b', pch=17, col=cor_2, lwd=2, lty=2)
points(optimal_k, min(crossvalidation_rmse_media), pch=21, cex=2.2, col=cor_texto, lwd=2)
legend('topright', legend=c(paste0('média dos folds (adotado): k = ', optimal_k),
                            paste0('mediana dos folds: k = ', optimal_k_mediana)),
       col=c(cor_1, cor_2), pch=c(16, 17), lty=c(1, 2), lwd=2, bty='n', text.col=cor_texto2)
dev.off()


##########################################
# ETAPA 5: SUPPORT VECTOR MACHINES (SVM) #
##########################################


# Mesmo procedimento do Lab5 (Etapa 1) e do Lab6 (Etapa 3). Com o output numérico, a função "svm" do pacote
#"e1071" faz regressão (epsilon-regression): ajusta uma função que fica a menos de epsilon da maioria dos pontos,
#penalizando com o custo os pontos fora dessa faixa. É uma EXTENSÃO do que foi visto em aula (SVM para
#classificação): o hiperplano de margem máxima vira uma "faixa" de largura epsilon em torno da curva de regressão.
# A função "svm" normaliza as variáveis internamente (scale=TRUE), dentro de cada fold.

inicio <- Sys.time()

# Validação cruzada 10-fold (padrão da função "tune", como nos Labs) para escolher kernel e custo
set.seed(1)
cv_results_svm <- tune(svm, formula_modelo, data=data_train,
                       ranges=list(cost=c(0.1, 1, 10, 100), kernel=c('linear', 'radial')))
summary(cv_results_svm)
# Para regressão, o "error" do tune é o MSE médio dos 10 folds (s^2): a raiz dá o RMSE de validação cruzada.
desempenho_svm <- cv_results_svm$performances
desempenho_svm$rmse <- sqrt(desempenho_svm$error)
print(desempenho_svm)

# Refinamento (só se o kernel radial vencer): o kernel radial tem um segundo hiperparâmetro, gamma, que o Lab
#deixou no valor padrão (1/número de colunas), e o SVM de regressão tem um terceiro, epsilon, a meia-largura da
#faixa em que o erro não é penalizado (padrão 0,1). Fazemos uma validação cruzada 10-fold numa grade CONJUNTA de
#custo, gamma e epsilon (ajustar um de cada vez pode deixar passar combinações melhores).
# Como a função "svm" padroniza o output internamente, epsilon está em desvios padrão do taxitime:
#epsilon x dp(taxitime) dá a meia-largura da faixa em segundos (0,1 -> ~27 s; 0,4 -> ~108 s).
# Histórico (ver Script 06): a primeira versão refinava só custo (1, 10, 100) e gamma, com epsilon = 0,1, e o custo
#escolhido caiu na borda da grade. A grade abaixo tem o ótimo no interior em todas as dimensões.
melhor_svm <- cv_results_svm$best.parameters
gamma_padrao <- 1/ncol(X_train_s)
cost_range_svm <- c(0.3, 1, 3, 10)
gamma_range_svm <- gamma_padrao*c(1, 2, 4, 8)
epsilon_range_svm <- c(0.05, 0.1, 0.2, 0.4, 0.6, 0.8)
desempenho_svm_gamma <- NULL
if (melhor_svm$kernel == 'radial'){
  set.seed(1)
  cv_results_gamma <- tune(svm, formula_modelo, data=data_train, kernel='radial',
                           ranges=list(cost=cost_range_svm, gamma=gamma_range_svm, epsilon=epsilon_range_svm))
  desempenho_svm_gamma <- cv_results_gamma$performances
  desempenho_svm_gamma$rmse <- sqrt(desempenho_svm_gamma$error)
  print(head(desempenho_svm_gamma[order(desempenho_svm_gamma$rmse), ], 10))
  print(cv_results_gamma$best.parameters)
  # Se o ótimo cair na borda da grade, o verdadeiro ótimo pode estar fora dela: avisar para ampliar a grade
  if (cv_results_gamma$best.parameters$cost %in% range(cost_range_svm) |
      cv_results_gamma$best.parameters$gamma %in% range(gamma_range_svm) |
      cv_results_gamma$best.parameters$epsilon %in% range(epsilon_range_svm)){
    warning('O ótimo do SVM ficou na borda da grade (custo, gamma ou epsilon): considerar ampliar a grade.')
  }
  if (cv_results_gamma$best.performance < cv_results_svm$best.performance){
    best_svm_model <- cv_results_gamma$best.model
  } else {
    best_svm_model <- cv_results_svm$best.model
  }
} else {
  best_svm_model <- cv_results_svm$best.model
}
summary(best_svm_model)
parametros_svm <- c(kernel=c('linear', 'polynomial', 'radial', 'sigmoid')[best_svm_model$kernel + 1],
                    cost=best_svm_model$cost, gamma=best_svm_model$gamma, epsilon=best_svm_model$epsilon)
print(parametros_svm)

# Prever a base de teste com o melhor modelo SVM
yhat_svm <- predict(best_svm_model, data_test)

tempos['svm'] <- as.numeric(difftime(Sys.time(), inicio, units='secs'))

png(paste0(dir_fig, '03_04_svm_validacao_cruzada.png'), width=larg, height=alt, res=reso)
par(estilo)
d_lin <- desempenho_svm[desempenho_svm$kernel == 'linear', ]
d_rad <- desempenho_svm[desempenho_svm$kernel == 'radial', ]
plot(d_lin$cost, d_lin$rmse, type='b', pch=16, col=cor_1, lwd=2, log='x', ylim=range(desempenho_svm$rmse),
     xlab='Custo (escala log)', ylab='RMSE de validação cruzada (s)', main='SVM: kernel e custo por validação cruzada 10-fold',
     panel.first=grid(col=cor_grade, lty=1))
lines(d_rad$cost, d_rad$rmse, type='b', pch=17, col=cor_2, lwd=2)
legend('topright', legend=c('kernel linear', 'kernel radial'), col=c(cor_1, cor_2), pch=c(16, 17), lwd=2, bty='n',
       text.col=cor_texto2)
dev.off()

# Refinamento: RMSE de validação cruzada x epsilon, uma linha por custo, no gamma escolhido
if (!is.null(desempenho_svm_gamma)){
  png(paste0(dir_fig, '03_04b_svm_refinamento.png'), width=larg, height=alt, res=reso)
  par(estilo)
  g_otimo <- cv_results_gamma$best.parameters$gamma
  d_g <- desempenho_svm_gamma[abs(desempenho_svm_gamma$gamma - g_otimo) < 1e-12, ]
  azuis <- c('#bcd4f3', '#8db6ea', '#2a78d6', '#164a8c')
  plot(NA, xlim=range(epsilon_range_svm), ylim=c(min(d_g$rmse), max(d_g$rmse) + 0.3*diff(range(d_g$rmse))), xaxt='n',
       xlab=paste0('epsilon (em desvios padrão do taxitime; 0,1 = ±', round(0.1*sd(data_train$taxitime)), ' s)'),
       ylab='RMSE de validação cruzada (s)',
       main=paste0('SVM radial: custo e epsilon com gamma = ', round(g_otimo/gamma_padrao), ' x padrão'),
       panel.first=grid(col=cor_grade, lty=1))
  axis(1, at=epsilon_range_svm, labels=epsilon_range_svm)
  for (j in 1:length(cost_range_svm)){
    d_c <- d_g[abs(d_g$cost - cost_range_svm[j]) < 1e-12, ]
    d_c <- d_c[order(d_c$epsilon), ]
    lines(d_c$epsilon, d_c$rmse, type='b', pch=16, col=azuis[j], lwd=2)
  }
  points(cv_results_gamma$best.parameters$epsilon, sqrt(cv_results_gamma$best.performance), pch=21, cex=2.4, col=cor_2, lwd=2.5)
  n_c <- length(cost_range_svm)
  legend('top', legend=c(paste0('custo = ', cost_range_svm), 'ótimo'), col=c(azuis[1:n_c], cor_2), lty=c(rep(1, n_c), NA),
         pch=c(rep(16, n_c), 21), lwd=2, pt.cex=c(rep(1, n_c), 1.6), ncol=n_c + 1, bty='n', text.col=cor_texto2, cex=0.85)
  dev.off()
}


##########################
# ETAPA 6: REDES NEURAIS #
##########################


# Mesmo procedimento do Lab5 (Etapa 2), com uma mudança: linear.output=TRUE, porque o output é contínuo
#(slide "Neural Network" de regressão, Aula 5: camada de saída com um neurônio e saída linear).
# A rede recebe as matrizes normalizadas e o output também normalizado (z = (y - média)/desvio padrão), para
#convergir; a previsão volta para segundos multiplicando pelo desvio padrão e somando a média.
# Como pede a observação do Lab5 ("deve-se sempre fazer um processo de validação cruzada para definir o desenho
#ótimo da rede"), escolhemos o número de camadas e de neurônios por validação cruzada 5-fold.

inicio <- Sys.time()

formula_nn <- as.formula(paste('y ~', paste(colnames(X_train_s), collapse=' + ')))
hidden_range <- list(c(2), c(3), c(5), c(5, 3))
nomes_hidden <- sapply(hidden_range, paste, collapse='-')
limiar_nn <- 0.1        # critério de parada: derivada parcial máxima do erro (padrão da função: 0.01)
passos_nn <- 2e5        # número máximo de passos do treinamento

set.seed(1)
idx <- createFolds(data_train$taxitime, k=5)
mse_nn <- matrix(nrow=length(hidden_range), ncol=5)
for (i in 1:length(hidden_range)){
  for (fold in 1:5){
    Xa <- X_train[-idx[[fold]], manter]
    Xv <- X_train[idx[[fold]], manter]
    centro_f <- apply(Xa, 2, mean)
    escala_f <- apply(Xa, 2, sd)
    escala_f[escala_f == 0] <- 1
    Xa <- scale(Xa, center=centro_f, scale=escala_f)
    Xv <- scale(Xv, center=centro_f, scale=escala_f)
    colnames(Xa) <- colnames(X_train_s)
    colnames(Xv) <- colnames(X_train_s)
    ya <- data_train$taxitime[-idx[[fold]]]
    media_f <- mean(ya)
    dp_f <- sd(ya)
    data_nn <- data.frame(Xa, y=(ya - media_f)/dp_f)
    set.seed(1)
    nn_model <- neuralnet(formula_nn, data=data_nn, hidden=hidden_range[[i]], act.fct='logistic',
                          linear.output=TRUE, threshold=limiar_nn, stepmax=passos_nn)
    # Se a rede não convergir dentro de "stepmax", ela não tem pesos: registramos NA e seguimos
    if (is.null(nn_model$weights)){
      mse_nn[i, fold] <- NA
    } else {
      yhat <- as.numeric(predict(nn_model, data.frame(Xv)))*dp_f + media_f
      mse_nn[i, fold] <- mean((yhat - data_train$taxitime[idx[[fold]]])^2)
    }
    cat('rede', nomes_hidden[i], 'fold', fold, 'concluído\n')
  }
}
crossvalidation_rmse_nn_media <- sqrt(apply(mse_nn, 1, mean))
crossvalidation_rmse_nn_mediana <- sqrt(apply(mse_nn, 1, median))
print(data.frame(hidden=nomes_hidden, media=round(crossvalidation_rmse_nn_media, 2),
                 mediana=round(crossvalidation_rmse_nn_mediana, 2), folds_sem_convergir=rowSums(is.na(mse_nn))))
# Desenho com algum fold sem convergir fica com RMSE NA e não é escolhido
optimal_hidden <- hidden_range[[which.min(crossvalidation_rmse_nn_media)]]
optimal_hidden_mediana <- hidden_range[[which.min(crossvalidation_rmse_nn_mediana)]]
print(list(otimo_media=optimal_hidden, otimo_mediana=optimal_hidden_mediana))

# Treinar a rede ótima com a base de treinamento inteira
media_y <- mean(data_train$taxitime)
dp_y <- sd(data_train$taxitime)
data_nn <- data.frame(X_train_s, y=(data_train$taxitime - media_y)/dp_y)
set.seed(1)
nn_model <- neuralnet(formula_nn, data=data_nn, hidden=optimal_hidden, act.fct='logistic',
                      linear.output=TRUE, threshold=limiar_nn, stepmax=passos_nn)
if (is.null(nn_model$weights)){
  # A rede final não convergiu: o modelo M5 fica sem previsão e é excluído da comparação no Script 04
  warning('A rede neural final não convergiu dentro de stepmax; M5 fica sem previsão.')
  yhat_nn <- rep(NA, nrow(data_test))
} else {
  yhat_nn <- as.numeric(predict(nn_model, data.frame(X_test_s)))*dp_y + media_y
}

tempos['rede_neural'] <- as.numeric(difftime(Sys.time(), inicio, units='secs'))

png(paste0(dir_fig, '03_05_rede_validacao_cruzada.png'), width=larg, height=alt, res=reso)
par(estilo)
faixa_y <- range(c(crossvalidation_rmse_nn_media, crossvalidation_rmse_nn_mediana), na.rm=TRUE)
plot(1:length(hidden_range), crossvalidation_rmse_nn_media, type='b', pch=16, col=cor_1, lwd=2, xaxt='n', ylim=faixa_y,
     xlab='Desenho da rede (neurônios por camada escondida)', ylab='RMSE de validação cruzada (s)',
     main='Rede neural: desenho por validação cruzada 5-fold', panel.first=grid(col=cor_grade, lty=1))
axis(1, at=1:length(hidden_range), labels=nomes_hidden)
lines(1:length(hidden_range), crossvalidation_rmse_nn_mediana, type='b', pch=17, col=cor_2, lwd=2, lty=2)
legend('topright', legend=c('média dos folds (adotado)', 'mediana dos folds'), col=c(cor_1, cor_2), pch=c(16, 17),
       lty=c(1, 2), lwd=2, bty='n', text.col=cor_texto2)
dev.off()

if (!is.null(nn_model$weights)){
  png(paste0(dir_fig, '03_06_rede_neural.png'), width=2400, height=1600, res=reso)
  plot(nn_model, rep='best', show.weights=FALSE, information=FALSE, col.hidden=cor_1, col.out=cor_2,
       col.entry=cor_texto2, fontsize=7)
  dev.off()
}


##############################################
# ETAPA 7: SALVAR MODELOS E PREVISÕES        #
##############################################


previsoes <- data.frame(id=data_test$id, taxitime=data_test$taxitime,
                        M0_media=yhat_base, M0_cabeceira=yhat_base_runway,
                        M1_linear=yhat_lm, M1_log=yhat_lmlog,
                        M2_arvore=as.numeric(yhat_tree), M3_knn=as.numeric(yhat_knn),
                        M4_svm=as.numeric(yhat_svm), M5_rede=yhat_nn)

hiperparametros <- c(regressao_linear=versao_lm,
                     arvore_folhas=optimal_tree_size,
                     knn_k=optimal_k, knn_k_pela_mediana=optimal_k_mediana,
                     svm_kernel=parametros_svm[['kernel']], svm_cost=parametros_svm[['cost']],
                     svm_gamma=parametros_svm[['gamma']], svm_epsilon=parametros_svm[['epsilon']],
                     rede_hidden=paste(optimal_hidden, collapse='-'),
                     rede_hidden_pela_mediana=paste(optimal_hidden_mediana, collapse='-'))
print(hiperparametros)
writeLines(paste(names(hiperparametros), hiperparametros, sep=' = '), paste0(dir_res, '03_hiperparametros.txt'))
print(round(tempos, 1))
writeLines(paste(names(tempos), round(tempos, 1), sep=' = '), paste0(dir_res, '03_tempos_execucao_s.txt'))

save(previsoes, hiperparametros, versao_lm, smearing_lm, lm_model, lm_log_model, mediana_runway,
     tree_model, best_pruned_tree_model, optimal_tree_size, cv_results, cv_rmse_tree, cv_rmse_cvtree, size_range, mse_tree,
     optimal_k, crossvalidation_rmse_media, crossvalidation_rmse_mediana, k_range,
     best_svm_model, parametros_svm, desempenho_svm, desempenho_svm_gamma,
     nn_model, optimal_hidden, hidden_range, crossvalidation_rmse_nn_media, crossvalidation_rmse_nn_mediana,
     media_y, dp_y, formula_lm, formula_nn, limiar_nn, passos_nn, crossvalidation_rmse_lm,
     file='modelos.Rda')

# Fim do Script 03.
