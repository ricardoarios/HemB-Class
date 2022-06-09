#######################################################
# Main Code implemented to run all experiments using
# classification models
#######################################################
# This code is part of the HemB-Class framework
# Date: June, 2022
#
# Developers: Tiago Lopes, 
#		Ricardo Rios, 
#		Tatiane Nogueira
#
# GNU General Public License v3.0
# Permissions of this strong copyleft license are 
#	conditioned on making available complete 
#	source code of licensed works and 
#	modifications, which include larger works 
#	using a licensed work, under the same license. 
#	Copyright and license notices must be 
#	preserved. Contributors provide an express 
#	grant of patent rights.
#######################################################

###
# chose which dataset you'd like to analyze
###
rm(list=ls())
### default dataset
source("src/preprocessing/load-data-classif.R")

###
# loading machine learning methods
###
source("src/classification/dt.R")
source("src/classification/knn.R")
source("src/classification/dwnn.R")
source("src/classification/rf.R")
source("src/classification/svm.R")
source("src/classification/naive.R")
source("src/classification/xgboost.R")

###
# Select which methods you'd like to use
###
run.methods<-c("dt", "rf", "svrpol", "svrrad", "naive", "xgboost")
# other examples:
#run.methods<-c("dt", "knn", "dwnn", "rf", "svrpol", "svrrad", "naive", "xgboost")
#run.methods<-c("svrrad", "naive", "xgboost") # preparing ensemble
#run.methods<-c("dt")
               
###
# create matrices with results
###
result.mcc<-matrix(nrow=length(cv.10), ncol=length(run.methods))
result.acc<-matrix(nrow=length(cv.10), ncol=length(run.methods))
result.kappa<-matrix(nrow=length(cv.10), ncol=length(run.methods))
result.auc<-matrix(nrow=length(cv.10), ncol=length(run.methods))

for(i in 1:length(cv.10)){
  cat("*****\n*****Iteration ", i, "*****\n")
  final.prob<-c()
 
  # train task 
  train.tsk <- mlr::makeClassifTask(data = train[-unlist(cv.10[[i]]),], target = "Reported_Severity", positive = "Severe")
  # test task
  test.tsk <- mlr::makeClassifTask(data = train[unlist(cv.10[[i]]),], target = "Reported_Severity", positive = "Severe")

  final.prob<-cbind(final.prob, unlist(cv.10[[i]]))
  
  for(j in 1:length(run.methods)){
    cat("*****Running ", run.methods[j], "\n")
    switch (run.methods[j],
            dt = {
              eval<-dt.classif(train.task = train.tsk, test.task = test.tsk, 
                               measure = list(acc), 
                               save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                               threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            },
            knn = {
              eval<-knn.classif(train.task = mlr::makeClassifTask(data = train, target = "Reported_Severity"), 
                                test.task = unlist(cv.10[[i]]))
              
              if(((eval %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval, positive = "Severe", negative = "Others")
              }
            },
            dwnn = {
              eval<-dwnn.classif(train.task = mlr::makeClassifTask(data = train, target = "Reported_Severity"), 
                                 test.task = unlist(cv.10[[i]]))
              
              if(((eval %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval, positive = "Severe", negative = "Others")
              }
            },
            rf = {
              eval<-randomForest.classif(train.task = train.tsk, test.task = test.tsk, 
                                         measure = list(acc), 
                                         save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                                         threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            },
            svrpol = {
              eval<-svm.classif(train.task = train.tsk, test.task = test.tsk, 
                                measure = list(acc), 
                                save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                                pol=TRUE, threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            },
            svrrad = {
              eval<-svm.classif(train.task = train.tsk, test.task = test.tsk, 
                                measure = list(acc), 
                                save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                                pol=FALSE, threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            },
            naive = {
              eval<-naiveBayes.classif(train.task = train.tsk, test.task = test.tsk, 
                                       measure = list(acc), 
                                       save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                                       threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            },
            xgboost = {
              eval<-xgboost.classif(train.task = train.tsk, test.task = test.tsk, 
                                    measure = list(acc), 
                                    save.model=paste(sep="", "results/models/model-", run.methods[j], "-", i, ".mod"), 
                                    threshold = 0.5)
              
              if(((eval$data$response %>% table()) > 0) %>% all()){
                result.acc[i,j] <- measureACC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # mean((train[unlist(cv.10[[i]]),ncol(train)] - eval$data$response)^2)
                result.kappa[i,j] <- measureKAPPA(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response) # sqrt(mse[i])
                result.mcc[i,j] <- measureMCC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others") 
                result.auc[i,j] <- measureAUC(train[unlist(cv.10[[i]]),ncol(train)], eval$data$response, positive = "Severe", negative = "Others")
              }
              final.prob<-cbind(final.prob, eval$data$prob.Severe)
            }
    )
    
  }
  
  final.prob<-cbind(final.prob, 
                    train[unlist(cv.10[[i]]),ncol(train)]%>% as.character())
  colnames(final.prob)<-c("id", paste(sep="", "Severe.prob.", run.methods), "truth")
  write.csv(final.prob, 
            file=paste(sep="", "results/models/predictions-", i, ".csv"),
            row.names = F)
  
}

# just saving our results
rbind(
  apply(result.acc %>% na.omit(), 2, mean) %>% round(digits = 2),
  apply(result.kappa %>% na.omit(), 2, mean) %>% round(digits = 2),
  apply(result.mcc %>% na.omit(), 2, mean) %>% round(digits = 2),
  apply(result.auc %>% na.omit(), 2, mean) %>% round(digits = 2)
) %>% t() %>%  write.csv(file="results/metrics.csv")

