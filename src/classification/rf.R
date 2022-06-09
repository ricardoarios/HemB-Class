#######################################################
# Code implemented to model the dataset using Random
#	Forest
#
#######################################################
# This code is part of the Hema-Class framework
# Date: January, 2021
#
# Developers: Tiago Lopes, 
#		Ricardo Rios, 
#		Tatiane Nogueira, 
#		Rodrigo Mello
#
#
# GNU General Public License v3.0
#
# Permissions of this strong copyleft license are 
#	conditioned on making available complete 
#	source code of licensed works and 
#	modifications, which include larger works 
#	using a licensed work, under the same license. 
#	Copyright and license notices must be 
#	preserved. Contributors provide an express 
#	grant of patent rights.
#######################################################

#' This method runs a grid search to look for the best
#' Random Forest models
#' 
#' @param train.task - train dataset
#' @param test.task  - test dataset
#' @param measure    - list of measures used to seek the best parametrization
#' @param save.model - file name to save all random forest model and configuration
#' @param threshold  - cutoff point to decide based on probability values
#' @return predicted values

randomForest.classif<-function(train.task, test.task=NULL, measure = list(acc), save.model=NULL, threshold = 0.5){
  ####
  learn.method <- makeLearner("classif.randomForest", predict.type = "prob", 
                              predict.threshold = threshold)
  learn.method$par.vals <- list(importance = TRUE)
  
  class.learner_param = makeParamSet(
    makeIntegerParam("ntree",lower = 1, upper = 20),#makeIntegerParam("ntree",lower = 10, upper = 500),
    makeIntegerParam("mtry", lower = 1, upper = 7),  
    makeIntegerParam("nodesize", lower = 1, upper = 15)#makeIntegerParam("nodesize", lower = 1, upper = 20)
  )
  ####
  
  #rancontrol <- mlr::makeTuneControlRandom(maxit = 10L)
  rancontrol <- mlr::makeTuneControlGrid()
  
  set_cv <- mlr::makeResampleDesc("CV",iters = 10L)
  
  #parallelStart(mode="multicore", cpu=detectCores(), level="mlr.tuneParams")
  parallelStart(mode="socket", cpu=detectCores(), level="mlr.tuneParams")
  start<-Sys.time()
  model_tune <- mlr::tuneParams(learner = learn.method, resampling = set_cv, 
                                task = train.task, par.set = class.learner_param, 
                                control = rancontrol, measures = measure,
                                show.info = T)
  
  print(Sys.time()-start)
  parallelStop()
  
  best.model <- mlr::setHyperPars(learn.method, par.vals = model_tune$x)
  model <- mlr::train(best.model, train.task)
  
  if(!is.null(save.model)){
    save(model, file=save.model) 
    save(model_tune, file=paste(sep="", save.model, ".tune"))
    bmr = benchmark(list(best.model), tasks = train.task, resampling = set_cv, 
                    measures = measure, show.info = FALSE)
    save(bmr, file=paste(sep="", save.model, ".bmr"))
    #save(sfeats, file=paste(sep="", save.model, ".feat"))
  }
  
  if(!is.null(test.task)){
    output<-predict(model, test.task)
    invisible(output)
  }
}  
