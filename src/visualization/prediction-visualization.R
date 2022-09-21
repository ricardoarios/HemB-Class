# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# This code is released as part of the manuscript
# "Prediction of hemophilia A severity using a small-input machine learning framework", by Lopes et al., submitted in 2021.


###testing all classifiers
rm(list=ls())

#####... load dataset ...#####
# V3 - based on regression
source("src/preprocessing/load-data-classif.R")


#####... load validation measures ...#####
source("src/validation/validation-GreyZone.R")

#####... load classifiers ...#####
source("src/classification/rf.R")
source("src/classification/svm.R")
source("src/classification/dt.R")
source("src/classification/svm.R")
source("src/classification/naive.R")
source("src/classification/xgboost.R")


#####... Save prediction result ...#####
#classification.prediction<-c()
file.models<-c()


#####... select your measure ...#####
.MEASURE = list(kappa, mlr::auc)
#listMeasures("classif")

#####... only uncomment the following command if you're not using the full training dataset to adjuste the models ...#####
#load(file="data/CROSSVAL-10-TEST.rData")

##### check the correlation between variables
# pdf(file="results/corr-att.pdf")
# correlations <- cor(dataHemophilia[, -ncol(dataHemophilia)])
# corrplot(correlations, method="circle")
# dev.off()
#####

# dataHemophilia contains all instances used to train our models
train.task <- mlr::makeClassifTask(data = train, target = "Reported_Severity", positive = "Severe")

### running classifiers or just load pretrained ones

file.models[1] = "results/final_models/random.forest"
# uncomment the following command if you need retrain it
output<-randomForest.classif(train.task, test.task = NULL, .MEASURE, save.model = file.models[1], threshold = 0.7)
#

file.models[2] = "results/final_models/decision.tree"
# uncomment the following command if you need retrain it
output<-dt.classif(train.task, test.task = NULL, .MEASURE, save.model = file.models[2])
#

file.models[3] = "results/final_models/svm.rad"
# uncomment the following command if you need retrain it
output<-svm.classif(train.task, test.task = NULL, pol = FALSE, .MEASURE, save.model = file.models[3])
#

file.models[4] ="results/final_models/svm.pol"
# uncomment the following command if you need retrain it
output<-svm.classif(train.task, test.task = NULL, pol = TRUE, .MEASURE, save.model = file.models[4])
#

file.models[5] = "results/final_models/naive.bayes"
# uncomment the following command if you need retrain it
output<-naiveBayes.classif(train.task, test.task = NULL, .MEASURE, save.model = file.models[5])
#

file.models[6] = "results/final_models/xg.boost"
# uncomment the following command if you need retrain it
output<-xgboost.classif(train.task, test.task = NULL, .MEASURE, save.model = file.models[6])

############################################
#####... loading final test dataset ...#####
predict.dataset<-read.table(file="dataset/Hemophilia_B_all_instances_for_prediction_v5a.csv", 
	sep="\t", header = T)
na.rows<-c()
for(i in 1:ncol(predict.dataset)){
  na.rows<-c(na.rows, which(is.na(predict.dataset[,i])))
}
if(length(na.rows) > 0){
  predict.dataset<-predict.dataset[-unique(na.rows), ]
}

test<-subset(predict.dataset, select = -c(AA_HGVS, AA_Legacy, Protein_Change, aa1, aa2))
test$Reported_Severity<-rep("Severe", nrow(test))
test<-test[, colnames(train)]

test.task <- mlr::makeClassifTask(data = test, target = "Reported_Severity", positive = "Severe")
############################################


#####... using pretrained models to classify the test dataset ...#####
for(i in 1:length(file.models)){
 
  cat("Predicting using ", file.models[i], "\n")	
  load(file=file.models[i])
  output<-predict(model, test.task)
  
  predict.result.by.classifier<-cbind(predict.dataset, 
                         output %>% as.data.frame() %>% select(prob.Severe, prob.Others))
  
  write.table(predict.result.by.classifier, 
              file=paste(sep="", file.models[i], ".csv"), row.names = F, sep=",")
  
}


#####################################################
#####... The following commands are executed ########
##### just to plot the ROC curve...          ########
##################################################### 

####file.models[1]

class.learner <- makeLearner("classif.randomForest", predict.type = "prob", 
                             predict.threshold = 0.7)
class.learner$par.vals <- list(importance = TRUE)

load(paste(sep="", file.models[1],  ".tune"))

rf.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
rf.best.model$id<-"Random Forest"

####file.models[2]

class.learner <- makeLearner("classif.rpart", predict.type = "prob", predict.threshold = 0.7)

load(paste(sep="", file.models[2],  ".tune"))
dt.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
dt.best.model$id<-"Decision Tree"

####file.models[3]

class.learner <- makeLearner("classif.svm", predict.type = "prob", kernel="radial", cost = 1000)
class.learner$par.vals <- list(importance = TRUE)

load(paste(sep="", file.models[3],  ".tune"))
svm.rad.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
svm.rad.best.model$id<-"SVM (Radial)"


####file.models[4]

class.learner <- makeLearner("classif.svm", predict.type = "prob", kernel="polynomial", 
                             cost = 1000, predict.threshold = 0.7)
class.learner$par.vals <- list(importance = TRUE)

load(paste(sep="", file.models[4],  ".tune"))
svm.pol.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
svm.pol.best.model$id<-"SVM (Polynomial)"

####file.models[5]

class.learner <- makeLearner("classif.naiveBayes", predict.type = "prob", predict.threshold = 0.7)

load(paste(sep="", file.models[5],  ".tune"))
naive.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
naive.best.model$id<-"Naive Bayes"

####file.models[6]

class.learner <- makeLearner("classif.xgboost", predict.type = "prob", 
                             par.vals = list(
                               objective = "binary:logistic",
                               eval_metric = "error", nrounds = 100L)
)

load(paste(sep="", file.models[6],  ".tune"))

xg.best.model <- mlr::setHyperPars(class.learner, par.vals = model_tune$x)
xg.best.model$id<-"XGBoost"

##### run all

bmr = benchmark(list(rf.best.model, dt.best.model, svm.rad.best.model, svm.pol.best.model, naive.best.model, xg.best.model), 
                tasks = train.task, resampling = mlr::makeResampleDesc("CV", iters = 10L, stratify = TRUE), 
                   measures = .MEASURE, show.info = FALSE)

df = generateThreshVsPerfData(bmr, measures = list(fpr, tpr))

pdf(file="results/roc-curve.pdf")
plotROCCurves(df)
dev.off()

