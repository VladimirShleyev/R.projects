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


# ������ ������ -----------------------------------------
if(FALSE){
flow_df <- flow_list %>%
 purrr::map(read_delim, delim=',')
df <- reduce(flow_df, rbind) %>%
  repair_names()
profvis({saveRDS(df, "flow_df.rds")})
}

http_df <- http_list %>%
  purrr::map(read_delim, delim=',')

df <- reduce(http_df, rbind) %>%
  repair_names()

# �������������� -----------------------------------------
# ������� ����� ������� �� ������ ��������
fix_names <- names(df) %>%
  stri_replace_all_fixed(pattern=c("#", "-", " "), replacement=c("", "_", "_"), vectorize_all=FALSE)
names(df) <- fix_names

# ���������� ������ ��� ������� �� ������ ������ �������� xDR ------------------------------
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

# ������� MSISDN � �������� ������
df1 <- left_join(df, radius_subst, by="radius_user_name")

# � ������ ���������� �������� ������ �� ���������� ���������� � �����. 
# ������� ���, ����� start_time � end_time ���������� �� [0-10] ���
time_sample <- function(N, st = "2012/01/01", et = lubridate::now()) {
  st <- as.POSIXct(as.Date(st))
  et <- as.POSIXct(as.Date(et))
  dt <- as.numeric(difftime(et, st, unit = "sec"))
  ev <- sort(runif(N, 0, dt))
  rt <- st + ev
}

df1 %<>% mutate(end_timestamp=time_sample(nrow(.), now()-days(1), now())) %>%
  mutate(start_timestamp=end_timestamp-seconds(runif(nrow(.), -10, 0))) %>% 
  #mutate(start_timestamp=as.POSIXct(sn_start_time, origin="1970-01-01", tz="Europe/Moscow")) %>%
  #mutate(end_timestamp=as.POSIXct(sn_end_time, origin="1970-01-01", tz="Europe/Moscow")) %>%
  mutate(downlink_bytes=as.numeric(transaction_downlink_bytes)) %>%
  mutate(uplink_bytes=as.numeric(transaction_uplink_bytes)) # %>%  
  # select(start_timestamp, end_timestamp, everything())

write_csv(df1, "./Shiny_DPI_reports/edr_http.csv")

# ��������� ��������� ���������� xDR
cat(sprintf("����������� ����� ��������:  %s\n������������ ����� ��������: %s\nUplink:   %s ��\nDownlink: %s ��",
            min(df1$end_timestamp), 
            max(df1$end_timestamp),
            round(sum(df1$uplink_bytes)/1024^2, 1),
            round(sum(df1$downlink_bytes)/1024^3, 1)
            )
)

group_df <- df1 %>%
  group_by(radius_user_name) %>%
  summarise(user_recs=n(), 
            uplink_Kb=round(sum(uplink_bytes)/1024, 1), 
            downlink_Kb=round(sum(downlink_bytes)/1024, 1)) %>%
  arrange(desc(user_recs))


# �������� TOP-10 ������������� -------------------------------------------------------

plot_df <- group_df %>%
  top_n(10, downlink_Kb) %>%
  mutate(downlink_Mb=downlink_Kb/1024) %>%
  arrange(desc(downlink_Kb))

gp <- ggplot(plot_df, aes(fct_reorder(radius_user_name, downlink_Mb), downlink_Mb)) + 
  geom_bar(fill=brewer.pal(n=9, name="Blues")[4], alpha=0.5, stat="identity") +
  theme_igray() +
  xlab("Raduis ���") +
  ylab("��������� Downlink, Mb") +
  coord_flip()

gp

# ��������� ������������� ������� ------------------------------------------------------
df2 <- df1 %>% 
  select(timestamp=end_timestamp, downlink_bytes, uplink_bytes) %>%
  gather(downlink_bytes, uplink_bytes, key="direction", value="bytes") %>%
  sample_frac(0.2) %>%
  filter(bytes>0.1)

windowsFonts(robotoC="Roboto Condensed")

gp2 <- ggplot(df2, aes(timestamp, bytes)) + 
  geom_point(aes(colour=direction), alpha=0.4, shape=1, size=2) +
  theme_ipsum_rc(base_family="robotoC", base_size=14) +
  theme(legend.position="right") +
  scale_y_log10(breaks=trans_breaks("log10", function(x) 10^x),
                labels=trans_format("log10", math_format(10^.x)))

gp2
