library(tidyverse)
library(scales)
library(lubridate)
library(parsedate)
library(fasttime)
library(anytime)
# library(tibble)
library(purrr)
library(magrittr)
# library(data.tree)
# library(rlist)
# library(reshape2)
# library(pipeR)
# library(jsonlite)
library(hrbrthemes)
library(tidyjson)
library(profvis)
library(elastic)
library(microbenchmark)

source("funcs.R")

# main -----------------------------

connect(es_host="89.223.29.108", es_port = 9200)
info() # ���������� ���������� ��� ����������

# --------------------------------------------------------------------------
# ������ scroll, ����� �������� ��� ��������, ������ ����� JSON ------------
body <- '{
"query": {
"bool": {
"must": [ 
{"match": { "source.ip": "10.0.0.232"}} 
],
"filter":  [
{ "range": { "start_time": { "gte": "now-7d", "lte": "now" }}}
] 
}
}
}'

# ���� �������������� ������ size ������ �� ����������� ������� ���������� �������� + �������
req_size <- 200 # ��� ���������� �������� ���������� �� ������� ����������\��������������� ������

#profvis({
res <- Search(index="packetbeat-*", body=body, scroll="1m", size=req_size)

# �������� �� ����� ������ � ����� ������

req_list <- seq(from=1, by=1, length.out=res$hits$total/req_size)

cat(res$hits$total, ",  ", req_list, "\n")

# ���� ����������� �� ����� ������, ������� ������ ��������� � ������������ �� �� ���� data.frame
df <- req_list %>%
  purrr::map_df(processScroll, scroll_id=res$`_scroll_id`, req_size=req_size, .id = NULL)
#})

# ���� ���������, ��� df �� ������ (0 ��������)
# browser()
# ����������� ����
df2 <- df %>%
  mutate(timestamp=fastPOSIXct(start_time)) %>% # ����� ������� � ISO 8601
  mutate(timegroup=hgroup.enum(timestamp, min_bin=5)) %>%
  group_by(timegroup) %>%
  summarise(volume_Mb=sum(bytes_total)/1024/1024) %>%
  ungroup()

# ����� ������������� ���������� ����������� ��������� �����
# tdf<- tibble(timegroup=seq(min(df1$timegroup), max(df1$timegroup) + days(f_depth), by="1 day"))

# ������ ������� �����������
# merge(df2, tdf, by="timegroup", all.x=TRUE, all.y=TRUE)
# res <- full_join(df2, tdf, by="timegroup")

gp <- ggplot(df2, aes(timegroup, volume_Mb)) + 
  geom_point(alpha=0.85, shape=1, size=3) +
  geom_line(alpha=0.85, lwd=1) +
  # theme_ipsum_rc(base_family="robotoC", base_size=16, axis_title_size=14) +
  scale_x_datetime(breaks=date_breaks("1 hour")
                   #minor_breaks = date_breaks("6 hours"),
                   ) +
  theme_ipsum_rc(base_size=16, axis_title_size=14) +
  theme(axis.text.x = element_text(angle=90)) +
  xlab("����, �����") +
  ylab("��������� ����� ������, Mb") +
  ggtitle("�������� �������", subtitle="��������� ����� � ����������")

gp
