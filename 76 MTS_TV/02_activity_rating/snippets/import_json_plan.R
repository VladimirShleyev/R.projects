library(tidyverse)
library(lubridate)
library(magrittr)
library(forcats)
library(jsonlite)
library(stringi)
library(stringr)
library(tictoc)
library(profvis)
library(microbenchmark)
library(Cairo)
library(RColorBrewer)
library(extrafont)
library(hrbrthemes)

getwd() # ����� ������, ����� ���������� �������� �������

#source("clickhouse.R")
#eval(parse("funcs.R", encoding="UTF-8"))


fname <- "./data/channels.json"

df0 <- jsonlite::fromJSON(fname, simplifyDataFrame=TRUE)

prog_df <- df0 %>% select(channelId, ch_name=name)

df <- readRDS("./data/channels_report1.rds") %>%
  filter(complete.cases(.))

df %<>% # ��� ������ �������� ������, ��� logi
  left_join(prog_df, by=c("channelId")) %>%
  # �������
  # mutate_at(vars(ch_name), ~if_else(is.na(.x), str_c("_", .$channelId, "_"), .x)) %>%
  mutate(ch_name=if_else(is.na(ch_name), str_c("_", channelId, "_"), ch_name)) %>%
  select(-channelId) %>%
  select(channelId=ch_name, everything())
stop()









cur_df <- readRDS("./data/cur_df_report2.rds") %>%
  filter(complete.cases(.))
# � ���� ������� ���� ������ NA, ������� � �������� ������ ���������� Vologda

colnames_df <- getRusColnames(cur_df)

colheader <- htmltools::withTags(
  table(class = 'display',
        thead(
          tr(colnames_df %>%
          {purrr::map2(.$col_label, .$col_runame_screen, ~th(title=.x, .y))})
        )))

# ������� ---------------- 
# htmltools::withTags(
#   table(class = 'display',
#         thead(
#           tr(colnames_df %>% 
#                {purrr::map2(.$col_label, .$col_runame_screen, 
#                                           ~ {print(paste(.x, "-", .y, "-<, ")); 
#             th(title=.x, .y)})})
#         )))
# # ����������� �������
# htmltools::withTags(
#   table(class = 'display',
#         thead(
#           tr(apply(colnames_df, 1,
#                    function(x) th(title=x[4], x[2])))
#         )))



# � ������ ��������� ������� ������� -----------
DT::datatable({cur_df},
              # colnames=c('�����'='channelId', '�������'='segment', '������'='region', '����'='date'),
              rownames=FALSE,
              filter='bottom',
              # ������ ����� ������� �������� �������
              container=colheader,
              options=list(dom='fltip', pageLength=7, lengthMenu=c(5, 7, 10, 15),
                           order=list(list(3, 'desc')))) %>%
  DT::formatPercentage("stb_ratio", 2)


stop()

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
  "sum(duration)/60 AS total_duration, ",
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
