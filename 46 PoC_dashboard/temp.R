# ���������� �������� ����� ��� ������� ����������
#library(tidyr)
library(ggplot2) #load first! (Wickham)
library(ggdendro) # ��� ������ ����
library(lubridate) #load second!
library(dplyr)
library(tidyr)
library(readr)
library(jsonlite)
library(magrittr)
library(httr)
library(ggthemes)
#library(ggmap)
library(RColorBrewer) # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
library(scales)
library(gtable)
library(grid) # ��� grid.newpage()
library(gridExtra) # ��� grid.arrange()
library(curl)
library(arules)
# library(KernSmooth)
#library(akima)
#library(rdrop2)
# library(rgl)
library(futile.logger)



req <- curl_fetch_memory("https://raw.githubusercontent.com/iot-rus/Moscow-Lab/master/weather.txt")
  
# ����� ����, � �� ���������. � ���� ������ ������������ ������������� 

wrecs <- rawToChar(req$content) # weather history
# wh_json <- gsub('\\\"', "'", txt, perl = TRUE) 
# ������� ����� ����� �� , � ������� ������� � ��������� ��� ������������ ������������ ����������� json
# ��������� ',' ���� �������, ����� ����� ����������� (������� ������)
tmp <- paste0('{"res":[', gsub("\\n", ",\n", wrecs, perl = TRUE), ']}')
wh_json <- gsub("},\n]}", "}]}", tmp)
# t <- cat(wh_json)
write(wh_json, file="./export/wh_json.txt")
data <- fromJSON(wh_json)