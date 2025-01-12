### Fake ordinal data https://stats.stackexchange.com/questions/374413/how-to-simulate-likert-scale-data-in-r
rm(list=ls()) 
options(stringsAsFactors = FALSE)
graphics.off()
library(brms)
library(rstan)
setwd("~/Documents/git/proterant/investment")
set.seed(147)
N<-500
sigma<-0.5
dat<-data.frame(y=sample(1:6, N, replace = TRUE, prob = c(0.2, 0.1,0.1, 0.3, 0.2,0.1)))
### need a way to make this kind of data more sophisticated

#bmer<-brm(y~1,data=dat,family=cumulative("logit"))
#summary(bmer)
#fixef(bmer)
#newdata<-data.frame(y=1)
#fitted(bmer,newdata=newdata)
pp_check(bmer,nsamples = 100)
## now stan
datalist.simple <- with(dat, 
                        list(y = dat$y, 
                             N = nrow(dat),
                             K = length(unique(dat$y))))
                      
fit <- stan('ordi_stan.stan', data=datalist.simple,iter = 1000, warmup=500, chains=2, seed=4938483)

m2lni.sum <- summary(fit)$summary[2:6,1:3]
#c(0.2, 0.1,0.1, 0.3, 0.2,0.1) original probabilities

exp(m2lni.sum)
#https://betanalpha.github.io/assets/case_studies/ordinal_regression.html



params <- extract(fit)
par(mfrow=c(1, 1))

hist(params$gamma, main="", xlab="gamma", yaxt='n', ylab="")
#PPP check
B <- 6
idx <- rep(1:B, each=2)
x <- sapply(1:length(idx), function(b) if(b %% 2 == 0) idx[b] + 0.5 else idx[b] - 0.5)

obs_counts <- hist(dat$y, breaks=(1:(B + 1)) - 0.5, plot=FALSE)$counts
pad_obs_counts <- sapply(idx, function(n) obs_counts[n])

pred_counts <- sapply(1:1000, function(n) 
  hist(params$y_ppc[n,], breaks=(1:(B + 1)) - 0.5, plot=FALSE)$counts)
probs = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
cred <- sapply(1:B, function(b) quantile(pred_counts[b,], probs=probs))
pad_cred <- do.call(cbind, lapply(idx, function(n) cred[1:9,n]))

##colors
c_light <- c("#DCBCBC")
c_light_highlight <- c("#C79999")
c_mid <- c("#B97C7C")
c_mid_highlight <- c("#A25050")
c_dark <- c("#8F2727")
c_dark_highlight <- c("#7C0000")


plot(1, type="n", main="Posterior Predictive Distribution",
     xlim=c(0.5, B + 0.5), xlab="y",
     ylim=c(0, max(c(obs_counts, cred[9,]))), ylab="")

polygon(c(x, rev(x)), c(pad_cred[1,], rev(pad_cred[9,])),
        col = c_light, border = NA)
polygon(c(x, rev(x)), c(pad_cred[2,], rev(pad_cred[8,])),
        col = c_light_highlight, border = NA)
polygon(c(x, rev(x)), c(pad_cred[3,], rev(pad_cred[7,])),
        col = c_mid, border = NA)
polygon(c(x, rev(x)), c(pad_cred[4,], rev(pad_cred[6,])),
        col = c_mid_highlight, border = NA)
lines(x, pad_cred[5,], col=c_dark, lwd=2)

lines(x, pad_obs_counts, col="white", lty=1, lw=2.5)
lines(x, pad_obs_counts, col="black", lty=1, lw=2)



##complicate it
dat$y2<-rnorm(length(dat$y),dat$y+1,sigma)
dat$y2<-round(dat$y2)
