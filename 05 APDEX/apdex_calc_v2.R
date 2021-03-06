# ������� ���������� APDEX
library(lubridate)
library(ggplot2)
#library(scales)
#library(forecast)
library(stringr)
#library(RColorBrewer)

apdexf <- function(respw, T_agreed = 0.8) {
  # http://stackoverflow.com/questions/3818147/count-number-of-vector-values-in-range-with-r
  which(0 < respw$response_time & respw$response_time < T_agreed)
  
  # ���������, ��� ����������� �������� �� 3 ���������:
  # N  � ����� ���������� ������������� ��������
  # NS - ���������� ��������, ������� ��������� �� ����� ��� ������� ����� 0 � �
  # NF � ���������� ��������, ������� ��������� �� � � 4� 
  # (�.� �� �������� ������� �� �������� ������� ����������� �� 4)
  # ������ APDEX = (NS + NF/2)/N.
  
  respw
  
  apdex_N  <- length(respw$response_time) #APDEX_total
  apdex_NS <- length(which(respw$response_time < T_agreed)) # APDEX_satisfied
  apdex_NF <- length(which(T_agreed < respw$response_time & respw$response_time < 4*T_agreed)) # APDEX_tolerated F=4T
  
  apdex <- (apdex_NS + apdex_NF/2)/apdex_N 
  return(apdex)
}


# http://stackoverflow.com/questions/5796924/how-can-i-determine-the-current-directory-name-in-r
getwd()
setwd("C:/iwork.HG/R.projects/05 APDEX/data")  # note / instead of \ in windows 
filename = "RUM_simulated_data.csv"

mydata <- read.table(filename, header = TRUE, stringsAsFactors = FALSE,
                     sep=";") # comment.char = "#"
#mydata$date <- mdy_hm(mydata$date) #12/27/2013 3:00
mydata$timestamp <- dmy_hms(mydata$timestamp) #01.06.2013

# �������� ������
# qplot(timestamp, response_time, data = mydata, geom = c("point", "smooth"))
qplot(timestamp, response_time, data = mydata)

# ���������� ��������� �����
# http://stackoverflow.com/questions/77434/how-to-access-the-last-value-in-a-vector
# http://stat.ethz.ch/R-manual/R-patched/library/utils/html/head.html
start_time <- head(mydata, 1, addrownums = FALSE)$timestamp
end_time <- tail(mydata, 1, addrownums = FALSE)$timestamp

as.duration(end_time - start_time)

# ���������� ��������� ���������� ���������� � ������� ������ �������� ��������
# duration ������� � �������� ���������� ����� ����� �������
# http://www.jstatsoft.org/v40/i03/
aggr_time = dminutes(15)
measures = floor(as.duration(end_time - start_time)/aggr_time)
mpoint <- seq(from = start_time, by = aggr_time, length.out = measures)

# ������� � ������ ������������
# http://www.jstatsoft.org/v40/i03/paper "Dates and Times Made Easy with lubridate"
cur_time <- start_time + dminutes(60) # minutes(60)

# subset(mydata, cur_time %<=% timestamp %<% cur_time + minutes(1))
# subdata <- mydata[cur_time < mydata$timestamp & mydata$timestamp < cur_time+minutes(10),]
respw <- subset(mydata, cur_time <= timestamp & timestamp < cur_time + dminutes(5))
respw

# �������� ������� ���� �� �������
mpoint
# mydata
#sapply(mpoint, function(x) {mean(x)})

# http://stackoverflow.com/questions/3505701/r-grouping-functions-sapply-vs-lapply-vs-apply-vs-tapply-vs-by-vs-aggrega
myFun <- function(x, data, dt) {
  dput(dt)
  return (subset(data, x <= timestamp & timestamp < x+dt))
}

rr <- myFun(cur_time, mydata, aggr_time)

for(i in mpoint){
  # print("Hello world!")
  print(date_decimal(i, tz = NULL))
}

res <- sapply(mpoint, function(x, data = mydata) 
  #{cat(x, ' -- ') str(subset(data, x <= timestamp & timestamp < x+dminutes(15)); cat('\n')} )
{str(subset(data, x <= timestamp & timestamp < x+dminutes(15)))} )
res
#res <- sapply(mpoint, function(x, data = mydata) {x+1})

apdexf(respw)



qplot(timestamp, response_time, data = respw, geom = c("point", "smooth"))
