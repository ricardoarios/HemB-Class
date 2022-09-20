#######################################################
# Code implemented to load the analyzed dataset 
#	as well as the required libraries
#
#######################################################
# This code is part of the Hema-Class framework
# Date: December, 2020
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

# loading main packages
library(dplyr)
library(caTools)
library(reshape)
library(ggplot2)
library(mlr)
library(parallelMap)
library(parallel)
library(KernelKnn)
library(BBmisc)

source("src/preprocessing/cvClass.R")


hemo.data<-read.table(file="dataset/HemB_Dataset_v5a.csv", sep="\t", header = T)
hemo.data<-subset(hemo.data, select = -c(cDNA, AA_HGVS, AA_Legacy, Domain, Protein_Change, aa1, aa2))
#head(hemo.data)
#hemo.data<-subset(hemo.data, select = -c(degree, kcore))
#head(hemo.data)

### should we use normalization?
hemo.data<-normalize(hemo.data, method = "range", range = c(0, 1))

### remove NA
cat('Data length [L C]:', dim(hemo.data), "\n")
na.values<-apply(hemo.data, 1, function (x) any(is.na(x)))
cat ('Na ratio: ', sum(na.values)/nrow(hemo.data))
hemo.data<-hemo.data[-c(which(na.values)), ]
cat('Data length [L C]:', dim(hemo.data), "\n")

### box plot attributes
temp_df <- subset(hemo.data, select = -c(Reported_Severity))
temp_df <- hemo.data
melt_df <- melt(temp_df)

p<-ggplot(melt_df, aes(x=variable, y=value)) + 
  geom_boxplot(fill="slateblue", alpha=0.2) + 
  theme(text = element_text(size=20),
        axis.text.x = element_text(angle=90, hjust=1)) +
  xlab("Variable") + ylab("Value")

pdf(file="results/boxplot.pdf")
print(p)
dev.off()
###

#write.table(train, file = "/home/rios/programming/python/hemo-2r7e.csv", row.names = F, sep=",")

cv.10<-cv.bin.strat.class(dataset=hemo.data, seed=123456, cv=10)
train = hemo.data
