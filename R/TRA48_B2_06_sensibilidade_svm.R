##############
# INTRODUÇÃO #
##############


# PROJETO B2 — Script 06: Sensibilidade do SVM aos hiperparâmetros (complemento do item 5 do relatório)
# TRA-48 · Henri Leonardo, Antonio Garcia e Gilberto Patri
#
# Por que este script existe: no Script 03, o refinamento do SVM escolheu cost = 1 e gamma = 4 x padrão, com
#epsilon no valor padrão da função (0,1). Ficaram duas lacunas:
#   1. cost = 1 foi o MENOR valor testado no refinamento (grade 1, 10, 100): não sabemos se custos menores, com
#      esse gamma, seriam melhores;
#   2. epsilon, a largura da faixa do SVM de regressão, não foi ajustado.
# Aqui fazemos uma única validação cruzada 10-fold (função "tune", como nos Labs 5 e 6) numa grade CONJUNTA de
#cost, gamma e epsilon. Gamma abaixo de 2 x padrão fica de fora porque o Script 03 já mostrou que é pior.
# Histórico da grade: a primeira versão usava cost = 0,1 / 0,3 / 1 / 3. O custo 0,1 foi o pior em todas as
#combinações e o ótimo caiu em cost = 3, na borda superior; por isso a grade final vai de 0,3 a 10.
#
# Este script NÃO altera a submissão de 18/11: o modelo submetido é o do Script 05. O resultado entra no
#relatório como análise de sensibilidade (o quanto o erro muda se os hiperparâmetros mudam).
#
# Obs. sobre epsilon: a função "svm" padroniza o output internamente (scale=TRUE vale para x e y). Assim,
#epsilon está em desvios padrão do taxitime: epsilon x dp(taxitime) dá a meia-largura da faixa em segundos.
#
# Saídas: "svm_sensibilidade.Rda" (pasta da base), "resultados/06_*" e "figuras/06_*.png".

dir_dados <- '~/Library/CloudStorage/OneDrive-Personal/Documentos/ITA/08-semestre/TRA-48/projetos/b2-data-challenge/'
setwd(dir_dados)
dir_repo <- '~/dev/ita/Projeto_B2_TRA-48/'
dir_fig <- paste0(dir_repo, 'figuras/')
dir_res <- paste0(dir_repo, 'resultados/')
dir.create(dir_fig, showWarnings=FALSE, recursive=TRUE)
dir.create(dir_res, showWarnings=FALSE, recursive=TRUE)

# Carregar a base processada (Script 02) e os modelos do Script 03
load("data_project_prep.Rda")
load("modelos.Rda")

# Pacotes
library(e1071)

# Paleta e estilo dos gráficos (mesmos dos outros scripts). Para gamma, que é uma grandeza ordenada, usamos
#tons de um mesmo azul, do mais claro (menor gamma) ao mais escuro (maior gamma).
cor_1 <- '#2a78d6'; cor_2 <- '#eb6834'; cor_3 <- '#1baf7a'; cor_neutra <- '#a3a29c'
cor_texto <- '#0b0b0b'; cor_texto2 <- '#52514e'; cor_grade <- '#e4e3df'; cor_fundo <- '#fcfcfb'
azuis <- c('#8db6ea', '#2a78d6', '#164a8c')
estilo <- list(bg=cor_fundo, fg=cor_texto2, col.axis=cor_texto2, col.lab=cor_texto, col.main=cor_texto,
               family='sans', las=1, mar=c(4.6,5,3.2,1.2), mgp=c(3.2,0.7,0), tcl=-0.3, bty='l',
               cex.main=1.1, font.main=2, cex.lab=1, cex.axis=0.9)
reso <- 220


#############################################
# ETAPA 1: GRADE CONJUNTA COST-GAMMA-EPSILON #
#############################################


# Configuração escolhida no Script 03 (fica dentro da grade, para comparar nos mesmos folds)
print(parametros_svm)
gamma_padrao <- 1/ncol(X_train_s)
dp_y <- sd(data_train$taxitime)

cost_range <- c(0.3, 1, 3, 10)
gamma_range <- gamma_padrao*c(2, 4, 8)
epsilon_range <- c(0.05, 0.1, 0.2, 0.4, 0.6, 0.8)
print(round(epsilon_range*dp_y, 1))      # meia-largura da faixa em segundos

inicio <- Sys.time()
set.seed(1)
cv_results_sens <- tune(svm, formula_modelo, data=data_train, kernel='radial',
                        ranges=list(cost=cost_range, gamma=gamma_range, epsilon=epsilon_range))
tempo_sens <- as.numeric(difftime(Sys.time(), inicio, units='mins'))
summary(cv_results_sens)

# "error" do tune = MSE médio dos 10 folds (s^2); a raiz dá o RMSE de validação cruzada
desempenho_sens <- cv_results_sens$performances
desempenho_sens$rmse <- sqrt(desempenho_sens$error)
desempenho_sens$gamma_x_padrao <- round(desempenho_sens$gamma/gamma_padrao, 2)
desempenho_sens$faixa_s <- round(desempenho_sens$epsilon*dp_y, 1)
desempenho_sens <- desempenho_sens[order(desempenho_sens$rmse), ]
print(head(desempenho_sens, 10))

melhor_sens <- cv_results_sens$best.parameters
print(melhor_sens)

# Configuração do Script 03 dentro desta grade (mesmos folds)
linha_03 <- which(abs(desempenho_sens$cost - as.numeric(parametros_svm['cost'])) < 1e-9 &
                  abs(desempenho_sens$gamma - as.numeric(parametros_svm['gamma'])) < 1e-9 &
                  abs(desempenho_sens$epsilon - as.numeric(parametros_svm['epsilon'])) < 1e-9)
rmse_cv_03 <- desempenho_sens$rmse[linha_03]
rmse_cv_novo <- sqrt(cv_results_sens$best.performance)
print(c(rmse_cv_script03=rmse_cv_03, rmse_cv_melhor_da_grade=rmse_cv_novo, diferenca=rmse_cv_03 - rmse_cv_novo))

# Ótimo na borda da grade? Se sim, o verdadeiro ótimo pode estar fora dela
na_borda <- c(cost=melhor_sens$cost %in% range(cost_range),
              gamma=melhor_sens$gamma %in% range(gamma_range),
              epsilon=melhor_sens$epsilon %in% range(epsilon_range))
print(na_borda)


###############################################################
# ETAPA 2: O MELHOR DA GRADE NA BASE DE TESTE INTERNA (1.607) #
###############################################################


# A escolha já foi feita pela validação cruzada; o teste interno só mede a diferença em relação ao SVM do
#Script 03, com o mesmo bootstrap pareado do Script 04 (Aula 1).
best_svm_sens <- cv_results_sens$best.model
yhat_svm_sens <- predict(best_svm_sens, data_test)
y <- data_test$taxitime

erro_03 <- previsoes$M4_svm - y
erro_novo <- yhat_svm_sens - y
rmse_teste_03 <- sqrt(mean(erro_03^2))
rmse_teste_novo <- sqrt(mean(erro_novo^2))
mae_teste_03 <- mean(abs(erro_03))
mae_teste_novo <- mean(abs(erro_novo))

B <- 2000
set.seed(1)
dif_boot <- numeric(B)
for (b in 1:B){
  i <- sample(1:length(y), length(y), replace=TRUE)
  dif_boot[b] <- sqrt(mean(erro_03[i]^2)) - sqrt(mean(erro_novo[i]^2))      # > 0: o novo erra menos
}
ic_dif <- quantile(dif_boot, c(0.025, 0.975))

resumo_sens <- c(cost_script03=parametros_svm['cost'], gamma_script03=parametros_svm['gamma'],
                 epsilon_script03=parametros_svm['epsilon'],
                 cost_melhor=melhor_sens$cost, gamma_melhor=round(melhor_sens$gamma, 4),
                 gamma_melhor_x_padrao=round(melhor_sens$gamma/gamma_padrao, 2), epsilon_melhor=melhor_sens$epsilon,
                 faixa_melhor_s=round(melhor_sens$epsilon*dp_y, 1),
                 rmse_cv_script03=round(rmse_cv_03, 2), rmse_cv_melhor=round(rmse_cv_novo, 2),
                 rmse_teste_script03=round(rmse_teste_03, 1), rmse_teste_melhor=round(rmse_teste_novo, 1),
                 mae_teste_script03=round(mae_teste_03, 1), mae_teste_melhor=round(mae_teste_novo, 1),
                 reducao_rmse_teste=round(rmse_teste_03 - rmse_teste_novo, 2),
                 ic95_inferior=round(ic_dif[1], 2), ic95_superior=round(ic_dif[2], 2),
                 otimo_na_borda=paste(names(na_borda)[na_borda], collapse=', '),
                 tempo_min=round(tempo_sens, 1))
names(resumo_sens) <- sub('\\..*$', '', names(resumo_sens))
print(resumo_sens)

write.csv(desempenho_sens[, c('cost', 'gamma_x_padrao', 'epsilon', 'faixa_s', 'rmse', 'dispersion')],
          paste0(dir_res, '06_svm_grade_validacao_cruzada.csv'), row.names=FALSE)
writeLines(paste(names(resumo_sens), resumo_sens, sep=' = '), paste0(dir_res, '06_svm_sensibilidade_resumo.txt'))


##################################
# ETAPA 3: FIGURA DA SENSIBILIDADE #
##################################


# Um painel por epsilon; em cada painel, RMSE de validação cruzada x custo, uma linha por gamma.
#Círculo cinza: configuração do Script 03. Círculo laranja: melhor da grade.
png(paste0(dir_fig, '06_01_svm_sensibilidade.png'), width=3000, height=1800, res=reso)
par(estilo); par(mfrow=c(2, 3), oma=c(0, 0, 2.4, 0))
faixa_y <- range(desempenho_sens$rmse)
for (e in epsilon_range){
  plot(NA, xlim=range(cost_range), ylim=faixa_y, log='x', xaxt='n',
       xlab='Custo (escala log)', ylab='RMSE de validação cruzada (s)',
       main=paste0('epsilon = ', e, '  (faixa de ±', round(e*dp_y), ' s)'), panel.first=grid(col=cor_grade, lty=1))
  axis(1, at=cost_range, labels=cost_range)
  for (g in 1:length(gamma_range)){
    sel <- abs(desempenho_sens$epsilon - e) < 1e-9 & abs(desempenho_sens$gamma - gamma_range[g]) < 1e-9
    o <- order(desempenho_sens$cost[sel])
    lines(desempenho_sens$cost[sel][o], desempenho_sens$rmse[sel][o], type='b', pch=16, col=azuis[g], lwd=2)
  }
  if (abs(e - as.numeric(parametros_svm['epsilon'])) < 1e-9){
    points(as.numeric(parametros_svm['cost']), rmse_cv_03, pch=21, cex=2.4, col=cor_neutra, lwd=2.5)
  }
  if (abs(e - melhor_sens$epsilon) < 1e-9){
    points(melhor_sens$cost, rmse_cv_novo, pch=21, cex=2.4, col=cor_2, lwd=2.5)
  }
  if (e == epsilon_range[1]){
    legend('topright', legend=c(paste0('gamma = ', c(2, 4, 8), ' x padrão'), 'escolhido no Script 03', 'melhor da grade'),
           col=c(azuis, cor_neutra, cor_2), lty=c(1, 1, 1, NA, NA), pch=c(16, 16, 16, 21, 21), lwd=2,
           pt.cex=c(1, 1, 1, 1.6, 1.6), bty='n', text.col=cor_texto2, cex=0.85)
  }
}
mtext('SVM de regressão: sensibilidade a custo, gamma e epsilon (validação cruzada 10-fold)', outer=TRUE,
      cex=1.1, font=2, col=cor_texto)
dev.off()

save(cv_results_sens, desempenho_sens, melhor_sens, best_svm_sens, yhat_svm_sens, resumo_sens, dif_boot,
     file='svm_sensibilidade.Rda')
