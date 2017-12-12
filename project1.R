install.packages("TTR")
install.packages("plyr")
library(plyr)
library(TTR)
library(ggplot2)
library(dplyr)
library(vcd)
library(ISLR)

## Q1: Is your city hotter or cooler on avrage compared to the global average?
##     Has the difference been consistent over time?

## Q2: How do the changes in your city's temperatures over time compare to the changes in the global average?

## Q3: What does the overall trend look like? Is the world getting hotter or cooler?
##     Has the trend been consistent over the last few hundred years?

# 1 Read csv

boston = read.csv("~/Documents/Udacity/Project1/boston1781.csv", header = T, na.strings = "?")
global = read.csv("~/Documents/Udacity/Project1/global1781.csv", header = T, na.strings = "?")

# 2 Five numbers
View(boston)
View(global)
summary(boston$avg_temp)
mean(boston$avg_temp)
var(boston$avg_temp)
sqrt(var(boston$avg_temp))
sd(boston$avg_temp)
summary(global$avg_temp)
mean(global$avg_temp)
var(global$avg_temp)
sqrt(var(global$avg_temp))
sd(global$avg_temp)
ggplot(boston, aes(year, avg_temp)) + geom_line(colour = "red") + labs(x = "Year", y = "Average temperature", title = "Average temperature of Boston")


ggplot(global, aes(year, avg_temp)) + geom_line(color = "green") + labs(x = "Year", y = "Average temperature", title = "Average temperature of Global")

boxplot(boston$avg_temp, global$avg_temp)
df = data.frame(year = boston$year, bavg_temp = boston$avg_temp, gavg_temp = global$avg_temp)
meetyear = list()
attach(df)
filter(df, bavg_temp == gavg_temp)
meetyear = filter(df, bavg_temp >= gavg_temp)
View(meetyear)



# 3 Line chart
plot(boston$year, boston$avg_temp, col = "red", pch = "22", xlab = "Year",
     ylab = "avg_temp", main = "Average temperature trend", type = "l")
lines(global$year, global$avg_temp, col = "green", pch = "22", xlab = "Year",
     ylab = "avg_temp", type = "l")
grid(nx = 5, ny = 5, lwd = 2)
legend("topleft", legend = c("Avg_temp_bos", "Avg_temp_glo"),
       col = c("red", "green"), lwd = 2)
## abline(v = meetyear$year, col = "purple", lty = 2)
## abline(h = meetyear$bavg_temp, col = "black", lty = 2)
plot(meetyear$year, meetyear$bavg_temp, col = "red", xlab = "Year",
     ylab = "avg_temp", main = "Trend Boston_temp exceed Global_temp", type = "l")
points(meetyear$year, meetyear$gavg_temp, col = "green", xlab = "Year",
       ylab = "avg_temp", type = "l")
legend("topleft", legend = c("Avg_temp_bos", "Avg_temp_glo"),
       col = c("red", "green"), lwd = 2)


# 4 Moving Average
bma = data.frame(year = boston$year, ma = SMA(boston$avg_temp, n = 7))
View(bma)
gma = data.frame(year = global$year, ma = SMA(global$avg_temp, n = 7))
View(gma)


plot(bma$year, bma$ma, col = "red", pch = "22", xlab = "Year",
     ylab = "Moving_avg_temp", main = "MovingAverage temperature trend", type = "l")
lines(gma$year, gma$ma, col = "green", pch = "22", type = "l")
grid(nx = 5, ny = 5, lwd = 2)
legend("topleft", legend = c("MA_B", "MA_G"),
       col = c("red", "green"), lwd = 2)

