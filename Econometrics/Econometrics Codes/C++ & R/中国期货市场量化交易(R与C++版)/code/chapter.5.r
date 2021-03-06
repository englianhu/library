## chapter 5.1
##
rm(list=ls())
source("d:/liwei/book/code/helper.r")


train.range <- 1:4
valid.range <- 5
test.range <- 6:9
train.contracts <- all.contracts[train.range]
valid.contracts <- all.contracts[valid.range]
test.contracts <- all.contracts[test.range]
#train.mat <- prepare.data(model$signals, model$y, product, train.contracts, over.night=-1)
#valid.mat <- prepare.data(model$signals, model$y, product, valid.contracts, over.night=-1)
#test.mat <- prepare.data(model$signals, model$y, product, test.contracts, over.night=-1)
#colnames(train.mat) <- c(paste("x",1:19,sep="."),"y")
#colnames(valid.mat) <- c(paste("x",1:19,sep="."),"y")
#colnames(test.mat) <- c(paste("x",1:19,sep="."),"y")
load(file="d:/liwei/book/data/chpt5.data.1.RData")
dim(train.mat)
## [1] 14445    20
dim(valid.mat)
## [1] 3375   20
dim(test.mat)
## [1] 16761    20
library(gbm)
##n.signals <- length(model$signals)
n.signals <- ncol(train.mat)-1
set.seed(100)
n.tree <- 300
depth <- 2
gbm.model <- gbm(y~., data=train.mat, shrinkage = 0.01, 
                 interaction.depth = depth, distribution="gaussian",n.trees=n.tree, verbose=FALSE)

r2 <- rep(0,n.tree)
for (i in 1:n.tree) {
  pred <- predict.gbm(gbm.model,newdata=valid.mat[,1:n.signals],n.trees = i)
  r2[i] <- R2(pred, valid.mat$y,"traditional")
}

plot(r2, type="l", main="gbm validation", xlab="n.tree")
best <- which.max(r2)
best
## 172 it may be different from the book
test.pred <- predict.gbm(gbm.model,newdata=test.mat[,1:n.signals],n.trees = best)
R2(test.pred, test.mat$y, "traditional")
## [1] 0.0001811405

test.r2 <- rep(0,n.tree)
for (i in 1:n.tree) {
  test.pred <- predict.gbm(gbm.model,newdata=test.mat[,1:n.signals],n.trees = i)
  test.r2[i] <- R2(test.pred, test.mat$y, "traditional")
}
## Figure 5-3
plot(test.r2, type="l", main="test set", xlab="n.tree")
which.max(test.r2)
## 85
max(test.r2)
## [1] 0.0009136092

library(randomForest)
set.seed(100)
n.node <- 10
r2 <- rep(0,n.node)
for (i in 1:10) {
  rf.model <- randomForest(y~., data=train.mat, maxnodes=i*20)
  pred <- predict(rf.model, newdata=valid.mat[,1:n.signals])
  r2[i] <- R2(pred, valid.mat$y, "traditional")
  cat(i,r2[i],"\n")
}
## Figure 5-4
plot(1:10*20, r2, type="l", main="random forest optimization", xlab="maxnode", ylab="r2")
which.max(r2)
## 4
rf.model <- randomForest(y~., data=train.mat, maxnodes=80)
pred <- predict(rf.model, newdata=test.mat[,1:n.signals])
R2(pred, test.mat$y, "traditional")
## [1] -0.01176351

### chpt 5.2
strat.product <- "hc"
strat.contracts <- get.dates(strat.product)
strat.contracts
product <- "rb"
product.contracts <- get.dates(product)

product.date.time <- get.product.date.time(product.contracts) ## ?????????????????????????????????
strat.date.time <- get.product.date.time(strat.contracts) ## ?????????????????????????????????
length(product.date.time) ## ????????????????????????
## [1] 74565
length(strat.date.time) ## ????????????????????????
## [1] 47250


if (length(product.date.time)>length(strat.date.time)) { ## ??????????????????????????????
  product.index <- match(strat.date.time, product.date.time) ## ??????????????????
  bad <- which(is.na(product.index)) ## ????????????????????????
  product.index[bad] <- product.index[bad-1]+1
  aa <- match(product.date.time, strat.date.time)
  bad <- which(is.na(aa))
  if (bad[1]==1) bad <- bad[-1]
  aa[bad] <- aa[bad-1]+1
  strat.index <- aa[!is.na(aa)]
} else { ## ??????????????????????????????
  strat.index <- match(product.date.time, strat.date.time) ## ??????????????????
  bad <- which(is.na(strat.index)) ## ????????????????????????
  strat.index[bad] <- strat.index[bad-1]+1
  product.index <- 1:length(product.date.time)
}

## product.data <- prepare.data(signals, y.str, product,product.contracts)[product.index,]
## ??????????????????????????????
## strat.data <- prepare.data(signals, y.str, strat.product, strat.contracts)[strat.index,]
load(file="d:/liwei/book/data/chpt5.data.2.RData")

## ??????????????????????????????
dim(product.data) ## ????????????????????????
## [1] 47250    20
dim(strat.data)
## [1] 47250    20


n.signal <- ncol(product.data)-1 ## ???????????????
colnames(strat.data) <- paste(strat.product,colnames(strat.data),sep=".")
## ?????????????????????????????????
all.data <- cbind(product.data[,1:n.signal], strat.data[,1:n.signal]) ## ???????????????????????????
all.data$y <- product.data$y ## ????????????????????????????????????
all.data <- clean(all.data) ## ????????????
n.data <- nrow(all.data) ## ????????????
dim(all.data) ## ????????????
## [1] 47250    39
n.bar <- nrow(all.data)
train.range <- 1:10000
valid.range <- 10001:20000
test.range <- setdiff(1:n.bar, c(train.range, valid.range))
train.mat <- all.data[train.range,]
valid.mat <- all.data[valid.range,]
test.mat <- all.data[test.range,]
n.coef <- 100
grid=10^seq(-2,-6,length=n.coef)
x <- as.matrix(train.mat[,1:(ncol(train.mat)-1)])
x.valid <- as.matrix(valid.mat[,1:(ncol(train.mat)-1)])
x.test <- as.matrix(test.mat[,1:(ncol(train.mat)-1)])
fit.lasso <- glmnet(x,train.mat$y,intercept=FALSE, lambda = grid)
coef.mat <- coef(fit.lasso)[-1,]
oos.mat <- rep(0,n.coef)
for (i in 1:n.coef) {
  cur.coef <- coef.mat[,i]
  pred <- x.valid%*%cur.coef
  oos.mat[i] <- R2(pred,valid.mat$y, "traditional")
}
## Figure 5-5
plot(oos.mat, type="l", main="cross symbol validation")
best <- which.max(oos.mat)
best
## 41
pred.test <- x.test %*% coef.mat[,best]
R2(pred.test, test.mat$y, "traditional")
## [1] -0.002754658
########## without hc

train.mat <- all.data[train.range,c(1:n.signal,39)]
valid.mat <- all.data[valid.range,c(1:n.signal,39)]
test.mat <- all.data[test.range,c(1:n.signal,39)]
grid=10^seq(-2,-6,length=n.coef)
x <- as.matrix(train.mat[,1:(ncol(train.mat)-1)])
x.valid <- as.matrix(valid.mat[,1:(ncol(train.mat)-1)])
x.test <- as.matrix(test.mat[,1:(ncol(train.mat)-1)])
fit.lasso <- glmnet(x,train.mat$y,intercept=FALSE, lambda = grid)
coef.mat <- coef(fit.lasso)[-1,]
oos.mat <- rep(0,n.coef)
for (i in 1:n.coef) {
  cur.coef <- coef.mat[,i]
  pred <- x.valid%*%cur.coef
  oos.mat[i] <- R2(pred,valid.mat$y, "traditional")
}
## Figure 5-6
plot(oos.mat, type="l", main="only rb validation")
best <- which.max(oos.mat)
best
## 58
pred.test <- x.test %*% coef.mat[,best]
R2(pred.test, test.mat$y, "traditional")
## [1] -0.006316881

### chapter 5.3

y.str <- "fcum.32"
train.range <- 1:40
valid.range <- 41:50
test.range <- 51:150
#train.mat <- prepare.tick.data(signal.list, y.str, product, all.dates[train.range])
#valid.mat <- prepare.tick.data(signal.list, y.str, product, all.dates[valid.range])
#test.mat <- prepare.tick.data(signal.list, y.str, product, all.dates[test.range])
load(file="d:/liwei/book/data/chpt5.data.3.RData")
dim(train.mat)
## [1] 1609232      12
dim(valid.mat)
## [1] 407031     12
dim(test.mat)
## [1] 4017980      12
n.coef <-100
grid=10^seq(-4,-7,length=n.coef)
x <- as.matrix(train.mat[1:(ncol(train.mat)-1)])
x.valid <- as.matrix(valid.mat[1:(ncol(valid.mat)-1)])
x.test <- as.matrix(test.mat[1:(ncol(test.mat)-1)])
fit.lasso <- glmnet(x,train.mat$y,intercept=FALSE, lambda = grid,alpha=1)
coef.mat <- coef(fit.lasso)[-1,]
if (dim(coef.mat)[2]<100) n.coef <- dim(coef.mat)[2]
oos.mat <- rep(0,n.coef)
for (i in 1:n.coef) {
  cur.coef <- coef.mat[,i]
  pred <- x.valid%*%cur.coef
  oos.mat[i] <- R2(pred,valid.mat$y)
}
## Figure 5-7
plot(oos.mat, type="l", main="high frequency lasso")
best <- which.max(oos.mat)
best
## 62
pred.test <- x.test %*% coef.mat[,best]
R2(pred.test, test.mat$y)
## [1] 0.0108247
set.seed(100)
n.tree <- 600
depth <- 10
system.time(gbm.model <- gbm(y~., data=train.mat, shrinkage = 0.01, 
                             interaction.depth = depth, distribution="gaussian",n.trees=n.tree, verbose=FALSE))

## ????????????
##??????????????????
## 5899.52    1.08 5928.26  ## ????????????

## if waiting too long we can just load the model
load(file="d:/liwei/book/data/chpt5.gbm.hft.RData")


gbm.r2 <- rep(0,100)
for (i in 1:100) {
  pred <- predict.gbm(gbm.model,newdata=valid.mat[,1:(ncol(valid.mat)-1)],n.trees = i*6)
  gbm.r2[i] <- R2(pred, valid.mat$y)
  cat(i, gbm.r2[i],"\n")
}
## Figure 5-8
plot(1:100*6,gbm.r2, type="l", main="gbm high frequency", xlab="#tree", ylab="r2")

best <- which.max(gbm.r2)*6
best
## 282
gbm.test.pred <- predict.gbm(gbm.model,newdata=test.mat[,1:(ncol(valid.mat)-1)],n.trees = best)
R2(gbm.test.pred, test.mat$y)
## [1] 0.01765722
## 

library(h2o) ## ??????h2o???
h2o.init( ## h2o?????????
     nthreads=-1,
     max_mem_size = "8G")
h2o.removeAll() 
load(file="d:/liwei/book/data/chpt5.data.3.RData")

train.frame <- as.h2o(train.mat, destination_frame = "train.frame") ## ??????????????????h2o??????
valid.frame <- as.h2o(valid.mat, destination_frame = "valid.frame") ## ??????????????????h2o??????
test.frame <- as.h2o(test.mat, destination_frame = "test.frame") ## ??????????????????h2o??????
dim(train.frame)
## [1] 1609232      12

rf.r2 <- rep(0,10) ## ????????????R??????
for (i in 1:10) { ## ??????????????????
  h2o.rf.model <- h2o.randomForest(x=1:11, ## ????????????11???
                                   y=12, ## ???????????????12???
                                   training_frame = train.frame, ## ????????????
                                   seed=100, ## ????????????
                                   ntrees=500,## ????????????
                                   max_depth = i*2) ## ????????????
  h2o.valid.pred <- as.vector(h2o.predict(h2o.rf.model, newdata=valid.frame)) ## ??????????????????
  rf.r2[i] <- R2(h2o.valid.pred, valid.mat$y) ## ?????????R??????
  cat(i, rf.r2[i],"\n")
}


h2o.test.pred <- as.vector(h2o.predict(h2o.rf.model, newdata=test.frame)) ## ??????????????????
R2(h2o.test.pred, test.mat$y) ## ?????????R??????
## [1] 0.003325238 may be different from the book 

x <- seq(from=-10, to=10, by=0.1)
## Figure 5-9
plot(x,1/(1+exp(-x)), type="l") ## sigmoid??????


relu <- ifelse(x<0,0,x)
## Figure 5-10
plot(x,relu, type="l",main="relu") ## ReLu??????


n.level <- 13 ## ??????
dl.r2 <- rep(0,n.level) ## R????????????
for (i in 2:n.level) { ## ??????????????????
  h2o.dl.model <- h2o.deeplearning(x=1:11,
                                   y=12,
                                   training_frame = train.frame,
                                   seed=100,
                                   input_dropout_ratio = 0.2, ## ????????????
                                   activation="RectifierWithDropout",
                                   hidden = rep(i,3), ## ???????????????
                                   hidden_dropout_ratios = rep(0.3,3), ## ??????????????????
                                   distribution = "gaussian") ## ????????????
  h2o.valid.pred <- as.vector(h2o.predict(h2o.dl.model, newdata=valid.frame)) ## ?????????????????????
  dl.r2[i] <- R2(h2o.valid.pred, valid.mat$y) ## ????????????R??????
  cat(i,dl.r2[i],"\n")
}

## Figure 5-11 may be different from the book
plot(dl.r2, type="l", main="deep learning optimization", xlab="#hidden nodes")
best <- which.max(dl.r2)
best
## [1] 8 maybe different from the book


h2o.dl.model <- h2o.deeplearning(x=1:11, ## ?????????????????????
                                 y=12,
                                 training_frame = train.frame,
                                 seed=100,
                                 input_dropout_ratio = 0.2,
                                 activation="RectifierWithDropout",
                                 hidden = c(best,best,best), ## 11????????????????????????
                                 hidden_dropout_ratios = c(0.3,0.3,0.3),
                                 distribution = "gaussian")
h2o.test.pred <- as.vector(h2o.predict(h2o.dl.model, newdata=test.frame)) ## ??????????????????
R2(h2o.test.pred, test.mat$y) ## ?????????R??????
## [1]  0.008673514

dl.r2[best] ## ?????????R??????
## [1] 0.01507217

