# Decision Tree
setwd("C:/Users/B�n�dicte/Documents/Dataiku")
set.seed(100)
source("Scripts/data.R")
library(tree) # library used to build a decision tree

training <- read.csv("Data/census_income_learn.csv", header=F)
colnames(training) <- c("AAGE","ACLSWKR","ADTIND","ADTOCC", "AHGA", 
                        "AHRSPAY", "AHSCOL", "AMARITL", "AMJIND",
                        "AMJOCC", "ARACE", "AREORGN", "ASEX", "AUNMEM", 
                        "AUNTYPE", "AWKSTAT", "CAPGAIN", "CAPLOSS", "DIVVAL", 
                        "FILESTAT", "GRINREG", "GRINST", "HHDFMX", 
                        "HHDREL", "MARSUPWT", "MIGMTR1", "MIGMTR3", "MIGMTR4", 
                        "MIGSAME", "MIGSUN","NOEMP", "PARENT", 
                        "PEFNTVTY","PEMNTVTY","PENATVTY","PRCITSHP", 
                        "SEOTR", "VETQVA", "VETYN", "WKSWORK","YEAR", "INCOME")

# Pre-processing
# The attribute "instance weight" should *not* be used in the 
# classifiers, so it is set to "ignore" in this file
training <- subset(training, select=-c(MARSUPWT))

training <- data.modificationOfCountryOfBirth(training)
training <- subset(training, select=-c(GRINST,HHDFMX))
training <- subset(training, select=-c(ADTIND,ADTOCC))


# 10-fold cross-validation
# Randomly shuffle the training data
training <- training[sample(nrow(training)),]

#Create 10 equally size folds
folds <- cut(seq(1,nrow(training)), breaks=10, labels=FALSE)
folds

err <- matrix(nrow=10, ncol=1)

#Perform 10-fold cross validation
for(i in 1:10){
  print(i)
  testIndexes <- which(folds==i,arr.ind = TRUE)
  
  testData <- training[testIndexes, ]
  trainData <- training[-testIndexes, ]
  
  # creation of the training and test data sets 
  Xtest <- as.data.frame(testData)[,1:length(testData)-1]
  ztest <- factor(testData[,length(testData)])
  
  Xtrain <- as.data.frame(trainData)[,1:length(trainData)-1]
  ztrain <- factor(trainData[,length(trainData)])
  
  # Tree
  control_tree <- tree.control(nobs=dim(Xtrain)[1],mindev = 0.0001) # entire tree
  # construction of an entire tree
  tr <- tree(ztrain ~ ., data.frame(Xtrain), control = control_tree) # zapp has to be factor
  # pruning the tree
  validation <- cv.tree(tr, FUN = prune.misclass)
  
  #cvtree <- cv.tree(tr)
  #best.size <- cvtree$size[which(cvtree$dev==min(cvtree$dev))][1]
  #tr <- prune.misclass(tr, best=best.size)
  
  # predictions for the test data set
  prob <- predict(tr, Xtest)
  pred <- as.matrix(max.col(prob))
  
  # computation of the test error rate
  err[i] <- sum(levels(ztest)[pred] != ztest)/length(ztest)
  print(err[i])
}

IC <- function(moy,var,n,alpha) {
  student <- qt(1-alpha/2, df = n-1)
  IC <- c(moy - student*sqrt(var/n), moy + student*sqrt(var/n))
  IC
}

# computation of the mean and the variance of the 10 values of test error rate
err_mean <- mean(err)
var <- apply(err,1, function(x) ((x-err_mean)^2))
var <- 1/(10-1)*apply(matrix(var),2,sum)
IC <- IC(err_mean,var,10,0.05) # confidence interval at 95%
