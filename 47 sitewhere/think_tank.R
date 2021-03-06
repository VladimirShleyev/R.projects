library(ggplot2) #load first! (Wickham)
library(lubridate) #load second!
library(dplyr)
library(tidyr)
library(readr)
library(jsonlite)
library(magrittr)
library(curl)
library(httr)
library(ggthemes)
library(ggdendro) # ��� ������ ����
#library(ggmap)
library(RColorBrewer) # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
library(scales)
library(gtable)
library(grid) # ��� grid.newpage()
library(gridExtra) # ��� grid.arrange()


drange <- c(2210, 2270, 2330, 2390, 2450, 2510)
levs <- list(low = head(drange, -1), up = tail(drange, -1), 
             category = c('WET+', 'WET', 'NORM', 'DRY', 'DRY+'))

stop()

# --------------------------------------------------------------------------------------------------------
source("../46 PoC_dashboard/common_funcs.R") # ���� ������� ��� �������������� � ������������� �������

d <- dmy_hms("12-07-2016 14:45:03", tz = "Europe/Moscow")
d
hgroup.enum2(d, 1.2)


time.bin <- 1.2
tick_time <- d

if (time.bin < 1 & !(time.bin %in% c(0.25, 0.5))) time.bin = 1

n <- floor((hour(tick_time)*60 + minute(d))/ (time.bin * 60))
floor_date(tick_time, unit = "day") + minutes(n * time.bin *60)

stop()

# --------------------------------------------------------------------------------------------------------
req <- try({
  curl_fetch_memory("https://raw.githubusercontent.com/iot-rus/Moscow-Lab/master/weather.txt")
  # status_code == 200
  # class(try-error)
})
# �������� ������ 1-�� ������� ������, �������� ��� ������ ������� ���������� ������ ���-�� ���������
if(class(req)[[1]] != "try-error" && req$status_code == 200) {
  # ����� ����, � �� ���������. � ���� ������ ������������ ������������� 
  print("conversion")
} else {
  print("error")
}
  