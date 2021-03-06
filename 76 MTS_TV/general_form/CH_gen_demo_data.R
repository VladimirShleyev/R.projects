# ��������� �������� ������ ��� �������� � CH
# ����� �����: 800 ��� ��������� * 100 ������������ � ����� * 30 ����\��� * 3 ������

rm(list=ls()) # ������� ��� ����������
gc()
library(tidyverse)
library(magrittr)
library(lubridate)
library(stringi)
library(anytime)
library(tictoc)

system.time(raw_df <- as_tibble(readRDS("./data/tvstream3.rds")))


# ������� ����� ������� ��������
tic()
df <- raw_df %>%
  select(-data_date) %>% # data_date ������ ����� ����� NA
  filter(complete.cases(.)) %>% # �������� ������ � NA
  # mutate(timestamp = anytime(as.numeric(now()-seconds(as.integer(runif(n(), 0, 10*24*60*60)))))) %>%
  select(-date, -timestamp) %>%
  mutate(duration=if_else(duration<1, as.integer(runif(n(), 1, 10)), duration))
#  mutate(segment=sample(c("IPTV", "DVB-C", "DVB-S"), n(), replace=TRUE))
toc()

print(paste0("������ �������: ", round(as.numeric(object.size(df) / 1024 / 1024), digits = 1), "��"))

# system.time(saveRDS(df, "./data/tvstream4.rds", ascii = FALSE, compress = "gzip"))

object.size(df$segment)
n_distinct(df$duration)
summary(df)

if (FALSE){
  # ������� �������� ��� �������
  tic("����� ���������� ��������")
  unq <- map(select(raw_df, -timestamp, -date, -switchEvent, - data_date, -duration), unique) %>% 
    map(sort, decreasing = T)
  toc()
  tic("������ ������")
  for (i in names(unq)){
    fname <- paste0("./output/", i, ".csv")
    print(fname)
    write_csv(as_tibble(unq[[i]]), fname, col_names=FALSE)
  }
  toc()
}

# ������� ����� �������� �������
tic()
recs <- 10^7
end_time <- as.numeric(now() + months(1))
# df_out <- tibble(timestamp=end_time-seconds(as.integer(runif(recs, 0, 3*30*24*60*60))))
df_out <- tibble(timestamp=end_time - as.integer(runif(recs, 0, 3*30*24*60*60)))

df <- raw_df %>%
  select(-data_date) %>% # data_date ������ ����� ����� NA
  filter(complete.cases(.)) %>% # �������� ������ � NA
  # mutate(timestamp = anytime(as.numeric(now()-seconds(as.integer(runif(n(), 0, 10*24*60*60)))))) %>%
  select(-date, -timestamp) %>%
  mutate(duration=if_else(duration<1, as.integer(runif(n(), 1, 10)), duration))
#  mutate(segment=sample(c("IPTV", "DVB-C", "DVB-S"), n(), replace=TRUE))
toc()

tic()
write_csv(df, "./data.csv.gz")
toc()

