library(tidyverse)
library(forcats)
library(magrittr)
library(stringi)
library(ggthemes)
library(scales)
library(RColorBrewer)
library(hrbrthemes)
library(lubridate)
library(profvis)

# Reading and combining many tidy data files in R, Jun 13, 2016 in science
# http://serialmentor.com/blog/2016/6/13/reading-and-combining-many-tidy-data-files-in-R

flow_list <- dir(path="./data/", pattern="edr_BASE-edr_flow_format.*", full.names=TRUE)
http_list <- dir(path="./data/", pattern="edr_BASE-edr_http_format.*", full.names=TRUE)
regions <- c("�����������", "�����������", "������������", "�.��������", 
             "���������", "������", "�����-���������")


# ����������� flow edr ����� -----------------------------------------
if(FALSE){
  flow_df <- flow_list %>%
    purrr::map(read_delim, delim=',')
  df <- reduce(flow_df, rbind) %>%
    repair_names()
  profvis({saveRDS(df, "flow_df.rds")})
}

# ����������� http eDR ����� -----------------------------------------
http_df <- http_list %>%
  purrr::map(read_delim, delim=',')

df <- reduce(http_df, rbind) %>%
  repair_names() %>%
  sample_frac(0.2) # � ����� ��������� ������� ������ �����

# �������������� -----------------------------------------
# ������� ����� ������� �� ������ ��������
fix_names <- names(df) %>%
  stri_replace_all_fixed(pattern=c("#", "-", " "), replacement=c("", "_", "_"), vectorize_all=FALSE)
names(df) <- fix_names

# �������� ������ ��� ������� �� ������ ������ �������� xDR ------------------------------
# ��������� ����� ���������� radius_name � ���������� �� � ��� ���� ������� ����� MSISDN
radius_subst <- distinct(df, radius_user_name)
n_users <- round(nrow(radius_subst)/230)
msisdn <- sample(c(916, 925, 918), n_users, replace=TRUE)*10^7 + floor(runif(n_users, 10^6, 10^7-1))
# ���������� �����������
radius_subst$msisdn <- sample(msisdn, nrow(radius_subst), replace=TRUE)

radius_subst %>%
  group_by(msisdn) %>% 
  count() %>%
  arrange(desc(n))

# ������� MSISDN � ��������� �������� � �������� ������
df1 <- df %>% left_join(radius_subst, by="radius_user_name") %>%
  mutate(site=sample(regions, nrow(.), replace=TRUE))

# � ������ ���������� �������� ������ �� ���������� ���������� � �����. 
# ������� ���, ����� start_time � end_time ���������� �� [0-10] ���
time_sample <- function(N, st = "2012/01/01", et = lubridate::now()) {
  st <- as.POSIXct(as.Date(st))
  et <- as.POSIXct(as.Date(et))
  dt <- as.numeric(difftime(et, st, unit = "sec"))
  ev <- sort(runif(N, 0, dt))
  rt <- st + ev
}

df1 %<>% mutate(end_timestamp=time_sample(nrow(.), now()-days(30), now()+5)) %>%
  mutate(start_timestamp=end_timestamp-seconds(runif(nrow(.), -10, 0))) %>% 
  #mutate(start_timestamp=as.POSIXct(sn_start_time, origin="1970-01-01", tz="Europe/Moscow")) %>%
  #mutate(end_timestamp=as.POSIXct(sn_end_time, origin="1970-01-01", tz="Europe/Moscow")) %>%
  mutate(downlink_bytes=as.numeric(transaction_downlink_bytes)) %>%
  mutate(uplink_bytes=as.numeric(transaction_uplink_bytes)) # %>%  
# select(start_timestamp, end_timestamp, everything())

system.time(saveRDS(df1, "./Shiny_DPI_reports/edr_http_small.rds", compress=FALSE))

stop()
system.time(write_csv(df1, "./Shiny_DPI_reports/edr_http_small.csv"))