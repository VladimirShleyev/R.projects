library(tidyverse)
library(lubridate)
library(magrittr)
library(forcats)
library(ggrepel)
library(stringi)
library(shiny)
library(DBI)
library(RPostgreSQL)
library(anytime)
library(tictoc)
library(profvis)
library(microbenchmark)
library(Cairo)
library(RColorBrewer)
library(extrafont)
library(hrbrthemes)
# library(debug)
library(config)


source("clickhouse.R")
# getwd()
eval(parse("funcs.R", encoding="UTF-8"))

con <- dbConnect(clickhouse(), host="10.0.0.44", port=8123L, user="default", password="")

tt4 <- dbGetQuery(con, "SHOW TABLES")

# ��������� ������������ ������ �������
city_subset <- read_csv("region.csv")

# ��������� ������� �������������� ��������� � ������� �������� �������
cities_df <- req(
  dbGetQuery(con, "SELECT * FROM regnames")  %>%
    mutate_if(is.character, `Encoding<-`, "UTF-8") %>%
    filter(translit %in% pull(city_subset)))

# � ������ �� ����� ���� ������� list ��� ���������. ��� -- ������� ��������, �������� -- ��������
# m <- cities_df %>% column_to_rownames(var="russian") %>% select(translit)
# � base R ����� ���:
# m <- as.list(cities_df$translit)
# names(m) <- cities_df$russian

buildReq0 <- function(begin, end, regs){
  # bigin, end -- ����; regs -- ������ ��������
  plain_regs <- stri_join(reg %>% map_chr(~stri_join("'", .x, "'", sep="")), 
                          sep = " ", collapse=",")
  cat(plain_regs)
  
  paste(
  "SELECT ",
  # 1. ������,  �������
  "region, segment, ",
  # 2. ���-�� ���������� ��������� �� ������
  "uniq(serial) AS unique_stb, ",
  # ���-�� ���������� ��������� �� ���� ������� ��������� ��������
  "( SELECT uniq(serial) ",
  "  FROM genstates ",
  "  WHERE toDate(begin) >= toDate('", begin, "') AND toDate(end) <= toDate('", end, "') AND region IN (", plain_regs, ") ",
  ") AS total_unique_stb, ",  
  # 4. ��������� ����� ��������� ����� �����������, ���
  "sum(duration) AS total_duration, ",
  # 8. ���-�� ������� ���������
  "count() AS watch_events ",
  "FROM genstates ",
  "WHERE toDate(begin) >= toDate('", begin, "') AND toDate(end) <= toDate('", end, "') AND region IN (", plain_regs, ") ",
  "GROUP BY region, segment", sep="")
}

regions <- c("Moskva", "Barnaul")

# r <- buildReq(begin=today(), end=today()+days(1), regions)
r <- buildReq(begin="2017-06-28", end="2017-06-30", regions)


df <- dbGetQuery(con, r) %>%
  # ����� ���������, ���
  mutate(total_duration=round(as.numeric(total_duration), 1)) %>%
  # 3. % ���������� ���������
  mutate(ratio_per_stb=round(unique_stb/total_unique_stb, 3)) %>%
  left_join(cities_df, by=c("region"="translit")) %>%
  select(-region) %>%
  select(region=russian, everything())

# ������ ������� --------------
# ��� N �� ������� �������������
reg_df <- df %>%
  top_n(10, total_duration) %>%
  arrange(desc(total_duration)) %>%
  mutate(label=format(total_duration, big.mark=" "))    

gp <- ggplot(reg_df, aes(fct_reorder(as.factor(region), total_duration, .desc=FALSE), total_duration)) +
  geom_bar(fill=brewer.pal(n=9, name="Blues")[4], alpha=0.5, stat="identity") +
  # geom_text(aes(label=label), hjust=+1.1, colour="blue") + # ��� ������������
  geom_label(aes(label=label), fill="white", colour="black", fontface="bold", hjust=+1.1) +
  # geom_text_repel(aes(label=label), fontface = 'bold', color = 'blue', nudge_y=0) +
  # scale_x_discrete("��������", breaks=df2$order, labels=df2$channelId) +
  scale_y_log10() +
#  theme_ipsum_rc(base_size=publish_set[["base_size"]], 
#                 axis_title_size=publish_set[["axis_title_size"]]) +  
  theme(axis.text.x = element_text(angle=90)) +
  ylab("����� �������������") +
  xlab("������") +
  ggtitle("��� N ��������", subtitle="�� ���������� ������� �������������, ���") +
  coord_flip() 

gp
