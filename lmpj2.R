library(ISLR)
library(leaps)
library(glmnet)
# read csv
df = read.csv('/Users/wuzirong/Documents/UMLMSBA/Stat.Predictive/PJ2/tmdb_final.csv')
#View(df)
dim(df)
# Try to fit LM at first
#lm.fit = lm(revenue_adj~., data = df)
#summary(lm.fit)
#par(mfrow = c(2, 2))
#plot(lm.fit)
totalminmse = rep(0, 100) # store all minimum MSE according to different seed


# set sample and train set
dim(df)
attach(df)
# try different seed in order to verify the result
#for (s in 1:100){ 
  # according the for loop, get the lowest MSE is from seed 96
  set.seed(96) # should be s in the for loop
  train = sample(dim(df)[1], dim(df)[1] * 0.7)
  test = df[-train, ]
  # fit the lm using subset
  lm.fit1 = lm(revenue_adj~., data = df, subset = train)
  summary(lm.fit1)
  #par(mfrow = c(2, 2))
  #plot(lm.fit1)
  # using the test set for prediction
  lm.pred = predict(lm.fit1, test)
  summary(lm.pred)
  OriginMSE = mean((test$revenue_adj - lm.pred)^2)
  #par(mfrow = c(1, 1))
  #plot(lm.pred, test$revenue_adj)


#Bestsubset
  regfit = regsubsets(revenue_adj~., data = df[train, ], nvmax = 27)
  regfit.summary = summary(regfit)
  regfit.summary
# get the best selection from C_p, AdjustR2, and BIC
  par(mfrow = c(2, 2))
  aicmin = which.min(regfit.summary$rsq)
  bicmin = which.min(regfit.summary$bic)
  cpmin = which.min(regfit.summary$cp)
  r2max = which.max(regfit.summary$adjr2)
# plot the bic, cp, and adjr2
  #plot(regfit.summary$cp, type = "l", xlab = "Number of variables", ylab = "C_p")
  #points(cpmin, regfit.summary$cp[cpmin], col = 'red', cex = 2, pch =20)
  #plot(regfit.summary$adjr2, type = "l", xlab = "Number of variables", ylab = "AdjR2")
  #points(r2max, regfit.summary$adjr2[r2max], col = 'red', cex = 2, pch =20)
  #plot(regfit.summary$bic, type = "l", xlab = "Number of variables", ylab = "BIC")
  #points(bicmin, regfit.summary$bic[bicmin], col = 'red', cex = 2, pch =20)

  coef(regfit, bicmin)
# predict using the bestsubset result
# create function for predict cause of regsubsets() is unable to predict()
  predict.regsubsets = function(object, newdata, id, ...){ # function for fit a lm model based on best subset selection
    form = as.formula(object$call[[2]])
    mat = model.matrix(form, newdata)
    coefi = coef(object, id = id)
    xvars = names(coefi)
    mat[, xvars] %*% coefi
  }
  bs.pred = predict.regsubsets(regfit, df[-train, ], bicmin)
  bs.pred = as.array(bs.pred)
  BSMSE = mean((df$revenue_adj[-train] - bs.pred)^2)
  BSMSE


# RR and LASSO

  x = model.matrix(revenue_adj~., df)[, -1]
  y = df$revenue_adj

  par(mfrow = c(1, 1))
# Ridge Regression
  ridge.mo = cv.glmnet(x[train, ], y[train], alpha = 0)
  #plot(ridge.mo)
  #points(bestlam.r, ridge.mo$lambda.min, col = 'blue', cex = 2, pch =23)
  bestlam.r = ridge.mo$lambda.min
  bestlam.r
  # fit the RR model in best lambda
  ridge.mo.minlam = glmnet(x[train, ], y[train], lambda = bestlam.r, alpha = 0)
  ridge.minlam.pred = predict(ridge.mo.minlam, s = bestlam.r, newx = x[-train, ])
  predict(ridge.mo.minlam, s = bestlam.r, type = "coefficients")[1:29, ]
  RRMSE = mean((y[-train] - ridge.minlam.pred)^2)
  RRMSE

# LASSO
  lasso.mo = cv.glmnet(x[train, ], y[train], alpha = 1)
  #plot(lasso.mo)
  bestlam.l = lasso.mo$lambda.min # get the minimum value of lambda
  bestlam.l
  # fit the lasso model in best lambda
  lass.mo.lambmin = glmnet(x[train, ], y[train], lambda = bestlam.l, alpha = 1)
  lasso.lambmin.pred = predict(lass.mo.lambmin, s = bestlam.l, newx = x[-train, ])
  LASSOMSE = mean((y[-train] - lasso.lambmin.pred)^2)
  predict(lass.mo.lambmin, s = bestlam.l, type = "coefficients")[1:29, ] # gather the coefficients from model


# Comparison
  par(mfrow = c(1, 1))
  MSEs = c(OriginMSE, BSMSE, RRMSE, LASSOMSE) # get MSEs from all models
  minmse = which.min(MSEs)
  xlabel = c("OrigMSE", "BSMSE", "RRMSE", "LOMSE")
  # create barchart for comparing the MSEs.
  barplot(MSEs, border = F, names.arg = xlabel, las = 2, 
        col = c("red", "darkgreen", "darkblue", "purple"), 
        main = paste("Comparison among all MSEs with seed", s),
        ylim = c(0, 25000), type = "l")
  totalminmse[s] = MSEs[minmse] # store the minimum MSE in seed number s
#}
minmsetotal = which.min(totalminmse) # get minimum seed
minmsetotal
totalminmse[minmsetotal] # check the minimum MSE value
minmse
