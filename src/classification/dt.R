#######################################################
# Code implemented to model the dataset using Decision 
#	tree (DT)
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
#' DT models
#' 
#' @param train.task - train dataset
#' @param test.task  - test dataset
#' @param measure    - list of measures used to seek the best parametrization
#' @param save.model - file name to save all random forest model and configuration
#' @param threshold  - cutoff point to decide based on probability values
#' @return predicted values

dt.classif<-function(train.task, test.task=NULL, measure = list(acc), save.model=NULL, threshold = 0.5){
  ####
  ###using rpart
  learn.method <- makeLearner("classif.rpart", predict.type = "prob", predict.threshold = threshold)
  
  #####
  #getParamSet("classif.rpart")
  #####
  class.learner_param = makeParamSet(
    makeIntegerParam("minsplit",lower = 2, upper = 50),#minimum number of observations in a node
    makeIntegerParam("minbucket", lower = 1, upper = 35),#Minimum number of observations in a terminal node - same values used by RF (nodesize)makeIntegerParam("nodesize", lower = 1, upper = 20)
    makeNumericParam("cp", lower = 0.0001, upper = 1)#complexity parameter. The lower it is, the larger the tree will grow.
  )
  ####
  
  rancontrol <- mlr::makeTuneControlGrid()
  
  set_cv <- mlr::makeResampleDesc("CV",iters = 10L)
  
  #parallelStart(mode="multicore", cpu=detectCores(), level="mlr.tuneParams")
  parallelStart(mode="socket", cpu=detectCores(), level="mlr.tuneParams")
  start<-Sys.time()
  model_tune <- mlr::tuneParams(learner = learn.method, resampling = set_cv, 
                                task = train.task, par.set = class.learner_param, 
                                #control = rancontrol, measures = measure.severe,
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


