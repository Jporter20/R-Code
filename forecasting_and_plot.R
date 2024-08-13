#clear workspace
rm(list = ls())



#clear memory
gc(reset = TRUE)

source("~/r-tools/connect.r")
# source("~/aff-daily-run/db2_connect.R")
con = db_connect()
con_db2 = db2_connect()


library(tseries)
library(forecast)
library(WriteXLS)
library(fpp2)

#load the data
AA15 <- read.csv("~/janeka/holiday_forecasting/AA15.csv")

AA16 <- read.csv("~/janeka/holiday_forecasting/AA16.csv")


# convert to time series
Y <- ts(AA15[,2], start=c(2017,9), end= c(2019,9), frequency = 12)

#Y <- ts(AA16[,2], start=c(2017,1), end= c(2019,9), frequency = 12)

##########################################################################################
#Perform preliminary analysis
##########################################################################################

#Time Plot
autoplot(Y) + 
  ggtitle("Time Plot: MC Volume Per Month") +
  ylab("MC VOlume")

autoplot(Y) + 
  ggtitle("Time Plot: PSS Volume Per Month") +
  ylab("PSS Volume")

#plot of difference take out trend because data has a strong trend
DY <- diff(Y)

#Time plot difference data 
autoplot(DY) +
  ggtitle("Time Plot: Change in MC Volume Per Month") +
  ylab("MC Volume")
  
# investigate seasonality (favorite - year comparison of seasonality)
ggseasonplot(DY) +
  ggtitle("Seasonal Plot: Change in MC Volume Per Month") +
  ylab("MC Volume")

#subseries plot
ggsubseriesplot(DY) +
  ggtitle("Seasonal Plot: Change in MC Volume Per M<onth") +
  ylab("MC Volume")

##########################################################################################
#Use a benchmark method to forecast, seasonal naive method
#y_t = y_(t-s) _+ e_t
##########################################################################################
fit <- snaive(DY) 
print(summary(fit))
checkresiduals(fit)

####################################################################
#Fit ETS method (exponential smoothing model) prodeicts the best method to forecast
####################################################################
fit_ets <- ets(Y)
print(summary(fit_ets))
checkresiduals(fit_ets)

####################################################################
#Fit and ARIMA model (take regular different and seasonal difference)
####################################################################
fit_arima <- auto.arima(Y,d=1,D=1, stepwise = FALSE, approximation = FALSE, trace = TRUE) #use regular data
print(summary(fit_arima))
checkresiduals(fit_arima)


####################################################################
#Forecast with  ETS  model
####################################################################
fcst <- forecast(fit_ets,h=12)
autoplot(fcst)
print(summary(fcst))

####################################################################
#Forecast with  ARIMA model
####################################################################
fcst <- forecast(fit_arima,h=12) #24 months
autoplot(fcst)
print(summary(fcst))



# Save the plot

ggsave(filename = "zipggplotAA15.png")
png(filename = "zipggplotAA15.png", units = "px", width = 600, height = 600)
autoplot(AA15, n.ahead=12, CI=.95, error.ribbon='blue',line.size=1)
print(summary(fcst))
dev.off()


wb<-createWorkbook(type="xlsx")

# Create a new sheet to contain the plot
sheet <-createSheet(wb, sheetName = "ggplotFORECASTAA15")

# Add the plot created previously
addPicture("zipggplotAA15.png", sheet, scale = 1, startRow = 4,
           startColumn = 5)

# Add title
xlsx.addTitle(sheet, rowIndex=1, title="ForecastPlotsggplot2AA15",
              titleStyle = TITLE_STYLE)

# remove the plot from the disk
res<-file.remove("zipggplotAA15.png")

# Save the workbook to a file...

saveWorkbook(wb, "ggplotforecastplotAA15.xlsx")

#Add forecast data to excel sheet

addDataFrame(print(summary(fcst)), sheet, startRow = 1, startColumn = 1)
saveWorkbook(wb, "ggplotforecastplotAA15.xlsx")

# The excel file and the sheet will be created in the working directory

getwd()
