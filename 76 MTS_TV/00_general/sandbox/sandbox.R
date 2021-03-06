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




df <- readr::read_delim("datamodel.csv", delim=";")

# �������� 
publishToSQL <- function(clean_df) {
  # ������ ������� � PostgreSQL ---------------------
  # Connect to a specific postgres database
  
  if (Sys.info()["sysname"] == "Windows") {
    dw <- config::get("media-tel")
  }else{
    dw <- config::get("cti")
  }
  
  # dbConnect �� RPostgreSQL
  con <- dbConnect(dbDriver(dw$driver),
                   host = dw$host,
                   user = dw$uid,
                   password = dw$pwd,
                   port = dw$port,
                   dbname = dw$database
  )
  dbWriteTable(con, "tv_list", clean_df, overwrite = TRUE)
  
  # # ������������� �������� ��������� ���������� ������ � unicode
  # m <- dbReadTable(con, "tv_list") %>%
  # mutate_if(is.character, `Encoding<-`, "UTF-8")
  
  dbDisconnect(con)
}

# ���������� �������� ������ �� CH
if (TRUE){
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

buildReq <- function(begin, end, regs){
  # bigin, end -- ����; regs -- ������ ��������
  plain_regs <- stri_join(regions %>% map_chr(~stri_join("'", .x, "'", sep="")), 
                          sep = " ", collapse=",")
  cat(plain_regs)
  
  paste(
  "SELECT ",
  # 1. �������� ������ � ������ (����� ��� �������������� ������)
  "channelId, region, ",
  # 2. ���-�� ���������� ��������� �� ������
  "uniq(serial) AS unique_stb, ",
  # ���-�� ���������� ��������� �� ���� �������
  "( SELECT uniq(serial) ",
  "  FROM genstates ",
  "  WHERE toDate(begin) >= toDate('", begin, "') AND toDate(end) <= toDate('", end, "') AND region IN (", plain_regs, ") ",
  ") AS total_unique_stb, ",  
  # 4. ��������� ����� ��������� ����� �����������, ���
  "sum(duration) AS channel_duration, ",
  # 8. ���-�� ������� ���������
  "count() AS watch_events ",
  "FROM genstates ",
  "WHERE toDate(begin) >= toDate('", begin, "') AND toDate(end) <= toDate('", end, "') AND region IN (", plain_regs, ") ",
  "GROUP BY channelId, region", sep="")
}

regions <- c("Moskva", "Barnaul")

r <- buildReq(begin=today(), end=today()+days(1), regions)
df <- dbGetQuery(con, r) %>%
  # 6. ������� ����� ���������, ���
  mutate(mean_duration=channel_duration/watch_events) %>%
  # 3. % ���������� ���������
  mutate(ratio_per_tv_box=unique_stb/total_unique_stb) %>%
  # 5. % ������� ���������
  mutate(watch_ratio=channel_duration/sum(channel_duration)) %>%
  # 7. ������� ��������� ����� ��������� ����� ���������� �� ������, ���
  mutate(duration_per_stb=channel_duration/unique_stb) %>%
  left_join(cities_df, by=c("region"="translit"))
}


# ������� ������ ��� ������� -----------------------------------
# ������� �������� ��������� c ������� �������� �������
reg_df <- df %>%
  top_n(10, channel_duration) %>%
  arrange(desc(channel_duration)) %>%
  mutate(label=format(channel_duration, big.mark=" "))

gp <- ggplot(reg_df, aes(fct_reorder(as.factor(channelId), channel_duration, .desc=FALSE), channel_duration)) +
  geom_bar(fill=brewer.pal(n=9, name="Greens")[4], alpha=0.5, stat="identity", width=0.8) +
  # geom_text(aes(label=label), hjust=+1.1, colour="blue") + # ��� ������������
  geom_label(aes(label=label), fill="white", colour="black", fontface="bold", hjust=+1.1) +
  # geom_text_repel(aes(label=label), fontface = 'bold', color = 'blue', nudge_y=0) +
  # scale_x_discrete("��������", breaks=df2$order, labels=df2$channelId) +
  scale_y_log10() +
  theme_ipsum_rc(base_size=14, axis_title_size=12) +  
  theme(axis.text.x = element_text(angle=90)) +
  ylab("��������� ���������� �����") +
  xlab("�����") +
  ggtitle("���������� �������������", subtitle="��� 10 �������") +
  coord_flip()  

gp

if (FALSE){
  format(reg_df$channel_duration, big.mark=" ")

  # stri_join(regions %>% map_chr(~stri_join("-+", .x, "+-", sep=",")), sep = " ", collapse=" ")
  stri_join(regions %>% map_chr(~stri_join("'", .x, "'", sep="")), sep = " ", collapse=",")
}

if (FALSE){
# ������������ ������ � ��������
e <- now()
b <- now() - days(3)

e-b
m <- interval (b, e)
m/days(1)

# ---
e <- today()
b <- today() - days(3)

e-b
m <- interval (b, e)
m/days(1)



today<-mdy(08312015)
dob<-mdy(09071982)

interval(dob, today) / years(1)
}
