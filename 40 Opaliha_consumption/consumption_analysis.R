library(tidyverse)
library(lubridate)
library(magrittr)
library(scales)
library(forecast)
# library(ggthemr)
library(broom)
library(readr) #Hadley Wickham, http://blog.rstudio.org/2015/04/09/readr-0-1-0/


# https://github.com/cttobin/ggthemr
# ggthemr('lilac') # ������ ��� ������ � ggplot v2

# ggthemr_reset()

# UTF-8 issue
# http://stackoverflow.com/questions/19900668/r-wrong-encoding-in-rstudio-console-but-ok-in-r-gui-and-ggplot2
# Sys.setlocale("LC_ALL", "Russian")
# Sys.setlocale("LC_CTYPE", "en_RU.UTF-8")


# http://stackoverflow.com/questions/5796924/how-can-i-determine-the-current-directory-name-in-r
#getwd()
#setwd("R:/Ilya/�������/�����������_��������")  # note / instead of \ in windows 
filename <- "gas_consumption.csv"
filename <- "electricity_consumption.csv"

# mydata <- read.table(filename, header=TRUE, stringsAsFactors = FALSE, sep=";")
mydata <- read_delim(filename, delim = ";", quote = "\"",
    col_names = TRUE,
    locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"), # ��������, � ��������, ����� ���������� �����
    # col_types = list(date = col_datetime(format = "%d.%m.%Y %H:%M")), 
    progress = interactive()
  ) # http://barryrowlingson.github.io/hadleyverse/#5

#str(mydata)
# �� ����� ������ ����� readr::col_datetime, ��������� � ��������� ������� ���� ���� � �����, � � ��������� ������ ����
mydata$date <- dmy_hm(mydata$date, truncated=2, tz="Europe/Moscow") #truncated -- ����� ���� ������� 2 ��������� (����, ������)

# =================== ���� ���������� ======================

s_date <- dmy_hms("01.09.2015 0:0:0", tz="Europe/Moscow")
e_date <- s_date + month(2) - days(1) # months(0.5)
e_date = Sys.time()


subdata <- rename(mydata, timestamp=date) %>%
           filter(timestamp > s_date & timestamp < e_date)

# http://stackoverflow.com/questions/17244077/select-subset-by-date-in-r
# subdata <- mydata[ymd(20121201) < mydata$date & mydata$date < ymd(20130101),]
#subdata <- mydata[ymd(20120101) < mydata$date,]

# �������������� ������� -- subset
# http://stackoverflow.com/questions/8992585/creating-a-data-frame-based-on-day-of-week-from-a-data-frame-containing-several

# geom_point docs: http://docs.ggplot2.org/0.9.3.1/geom_point.html
# http://sape.inf.usi.ch/quick-reference/ggplot2/geom_point

#gp <- ggplot(subdata, aes(x=timestamp, y=balance_m3))
gp0 <- ggplot(subdata, aes(x=timestamp, y=balance_kwth))
gp0 <- gp0 +
  geom_point(size=4, shape=21) + # produce scatterplot # fill="green",
  geom_line() + 
  #  stat_smooth(aes(outfit=fit<<-..y..)) + #fitting http://stackoverflow.com/questions/9789871/method-to-extract-stat-smooth-line-fit
  theme_bw() +
  scale_x_datetime(labels = date_format("%d.%m (%a)"), minor_breaks = date_breaks("1 days")) +
  xlab("����") +
  ylab("������, ���")


gp <- ggplot(subdata, aes(x=timestamp, y=balance_rub))
gp <- gp +
  geom_point(size=4, shape=21) + # produce scatterplot # fill="green",
  geom_line() + 
#  stat_smooth(aes(outfit=fit<<-..y..)) + #fitting http://stackoverflow.com/questions/9789871/method-to-extract-stat-smooth-line-fit
  theme_bw() +
  scale_x_datetime(labels = date_format("%d.%m (%a)"), minor_breaks = date_breaks("1 days")) +
  xlab("����") +
  ylab("������, ���")

gp


# ���������� �������� ��������� ��� ����������� ������ ������� ����� �� ����
# http://www.tatvic.com/blog/linear-regression-using-r/
fit <-lm(balance_rub ~ timestamp, data = subdata)
summary(fit)
# tidy(fit)

# ����, ����� ��� ������ � ����
str(fit$coefficients)
# http://stackoverflow.com/questions/7257263/converting-date-times-in-posixct-gives-screwy-result
# the origin of time for the "POSIXct" class, �1970-01-01 00:00.00 UTC�, is before UTC was defined
# http://stat.ethz.ch/R-manual/R-devel/library/base/html/as.POSIXlt.html
zerotime <- as.POSIXct(as.numeric(-fit$coefficients[1]/fit$coefficients[2]), 
           tz="Europe/Moscow", 
           origin=as.POSIXct(strptime("1970-01-01 00:00:00", "%Y-%m-%d %H:%M:%S", tz="UTC")))
dput(zerotime)

# � ������ �������� ������ �� ���� ������ �� ����
# � ���� ���������� ������ �� ������� ���� ��������� ���������, � �� �������.
# 1. [ggplot2 Quick Reference: geom_abline](http://sape.inf.usi.ch/quick-reference/ggplot2/geom_abline), ������� ���� [�����](http://docs.ggplot2.org/current/geom_abline.html)
# - slope - (required) slope of the line (the "a" in "y=ax+b")
# - intercept - (required) intercept with the y axis of the line (the "b" in "y=ax+b").
# 2. ������������ ������� [stat_function()](https://kohske.wordpress.com/2010/12/25/draw-function-without-data-in-ggplot2/)

df <- data.frame(timestamp = zerotime, balance_rub=0, balance_kwth = NA, comment = NA)
# http://stackoverflow.com/questions/7476022/geom-point-and-geom-line-for-multiple-datasets-on-same-graph-in-ggplot2
# http://www.cookbook-r.com/Graphs/Shapes_and_line_types/
# ����� rbind ���������, ����������, ����� ���� � ���������� ������� ���������. � � ������� ������� 'Comment'
gp2 <- ggplot(rbind(subdata, df), aes(x=timestamp, y=balance_rub)) +
  geom_point(size=4, shape=21) + # produce scatterplot # fill="green",
  # geom_line(color = "blue", linetype="dashed") + 
  geom_abline(intercept = fit$coefficients[1], slope = fit$coefficients[2], color = "green", linetype="dashed") +
  geom_point(data=df, size=4, shape=21, color="red", fill="yellow") +  # predicted
  # stat_smooth(aes(outfit=fit<<-..y..)) + #fitting http://stackoverflow.com/questions/9789871/method-to-extract-stat-smooth-line-fit
  theme_bw() +
  scale_x_datetime(labels = date_format("%d.%m (%a)"), minor_breaks = date_breaks("1 days")) +
  xlab("����") +
  ylab("������, ���")

gp2



