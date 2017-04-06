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
library(RcppRoll)
library(digest)
library(fuzzyjoin)


df0 <- readRDS("./Shiny_DPI_reports/edr_http_small.rds")

# facet ������� ��� top 10 up/down ---------------------------------
t <- 9161234567
sprintf("(%s) %s-%s-%s", unlist(list(1, 2, 3, 4)))
st <- as.character(t)
m <- st %>% {sprintf("(%s) %s-%s-%s", stri_sub(., 1, 3), stri_sub(., 4, 5), stri_sub(., 6, 7), stri_sub(., 8, 9))}

df1 <- df0 %>%
  select(timestamp=end_timestamp, downlink_bytes, uplink_bytes, site, msisdn) %>%
  gather(downlink_bytes, uplink_bytes, key="direction", value="bytes") %>%
  sample_frac(0.2) %>%
  filter(bytes>0.1)


group_df <- df0 %>%
  mutate(msisdn=as.factor(msisdn)) %>%
  group_by(msisdn) %>%
  summarise(user_recs=n(), 
            uplink_Kb=round(sum(uplink_bytes)/1024, 1), 
            downlink_Kb=round(sum(downlink_bytes)/1024, 1)) %>%
  arrange(desc(user_recs)) %>%
  mutate(msisdn_chr=as.character(msisdn) %>% 
           {sprintf("(%s) %s-%s-%s", stri_sub(., 1, 3), 
                    stri_sub(., 4, 5), stri_sub(., 6, 7), stri_sub(., 8, 9))})
         

plot_df <- group_df %>%
  gather(downlink_Kb, uplink_Kb, key="direction", value="volume") %>%
  group_by(direction) %>%
  top_n(10, volume) # ����� ��������� � ����������
  #mutate(downlink_Mb=downlink_Kb/1024) %>%
  #arrange(desc(downlink_Kb))

gp <- ggplot(plot_df, aes(fct_reorder(msisdn, volume), volume)) + 
  geom_bar(fill=brewer.pal(n=9, name="Blues")[4], alpha=0.5, stat="identity") +
  facet_grid(.~direction, scales="free") +
  theme_ipsum_rc(base_size=16, axis_title_size=14) +
  xlab("'��� ��' MSISN") +
  ylab("��������� Downlink, Mb") +
  coord_flip()

gp

# ������� top 10 ��� ��������, up/down ---------------------------------

regions <- c("�����������", "�����������", "������������", "�.��������", "���������", "������", "�����-���������")
subregions <- c("���������", "������")

df2 <- df0 %>%
  select(timestamp=end_timestamp, down=downlink_bytes, up=uplink_bytes, site, msisdn) %>%
  gather(up, down, key="direction", value="bytes") %>%
  group_by(site, direction, msisdn) %>%
  summarise(user_recs=n(), bytes=sum(bytes)) %>%
  top_n(10, bytes) %>%
  ungroup() # %>% spread(direction, bytes)

# spread ���� �� 4 ������, ��������� � ���������� ������ ���� � ��� �� msisdn ������������ � � up � � down
# df2 %>% filter(!is.na(downlink_bytes) & !is.na(uplink_bytes))


# ������ time-series ������ ---------------------------------

hgroup.enum <- function(date, time.bin = 4){
  # ����������� ��� ���������, ������� ������ � ���������� [0, t] � ����� ���������.
  # ����� ��������� ����� ���� ������ 1, 2, 3, 4, 6, 12 �����, ������������ time.bin
  # ������ ��������� ���� � 0:00
  # �������� ��� �����������. ��� ����������� ������ ���� ����������� ��������� ����� ������ 1
  # 0.5 -- ��� � �������.0.25 -- ��� � 15 �����
  
  tick_time <- date
  if (time.bin < 1 & !(time.bin %in% c(0.25, 0.5))) time.bin = 1
  n <- floor((hour(tick_time)*60 + minute(tick_time))/ (time.bin * 60))
  floor_date(tick_time, unit="day") + minutes(n * time.bin *60)
}

# ������� �����
# https://edwinth.github.io/blog/padr-examples/
plot_df <- df0 %>%
  mutate(msisdn=sample(100:199, nrow(.), replace=TRUE)) %>%
  select(timestamp=end_timestamp, down=downlink_bytes, up=uplink_bytes, msisdn)

saveRDS(plot_df, "padr_sample.rds")
write_csv(plot_df, "padr_sample.csv")

plot_df <- readRDS("padr_sample.rds")
tmp_df <- plot_df %>%
  thicken("day", col="time") # don't work


# https://edwinth.github.io/blog/padr-examples/
plot_df <- df0 %>%
  filter(site=="������") %>%
  select(timestamp=end_timestamp, down=downlink_bytes, up=uplink_bytes, site, msisdn) %>%
  mutate(timegroup=hgroup.enum(timestamp, time.bin=24)) %>%
  # thicken("day", col="time") %>% # �� ��������
  group_by(site, timegroup) %>%
  summarize(up=sum(up), down=sum(down)) %>%
  ungroup() %>%
  gather(up, down, key="direction", value="volume") %>%
  mutate(volume=volume/1024/1024) %>% #����������� � ��
  group_by(site, direction) %>%
  mutate(volume_meanr = RcppRoll::roll_meanr(x=volume, n=7, fill=NA)) %>%
  ungroup()
  # filter(volume>1)

windowsFonts(robotoC="Roboto Condensed")

gp <- ggplot(plot_df, aes(timegroup, volume)) + 
  # http://www.sthda.com/english/wiki/ggplot2-colors-how-to-change-colors-automatically-and-manually
  facet_wrap(~site, nrow=2) +
  # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
  scale_color_brewer(palette="Set1",
                     name="������",
                     breaks=c("up", "down"),
                     labels=c("Uplink", "Downlink")
                     ) +
  # geom_line(aes(colour=direction), alpha=0.4, lwd=1) +
  geom_line(aes(y=volume_meanr, colour=direction), alpha=0.6, lwd=1) +
  geom_point(aes(colour=direction), alpha=0.6, shape=1, size=3) +
  scale_y_continuous(trans='log10') +
  #scale_y_log10(breaks=trans_breaks("log10", function(x) 10^x),
  #              labels=trans_format("log10", math_format(10^.x))) +
  #annotation_logticks() +
  # theme_ipsum_rc(base_size=16, axis_title_size=14) +
  theme_ipsum_rc(base_family="robotoC", base_size=16, axis_title_size=14) +
  xlab("����, �����") +
  ylab("��������� ����� ������, Mb")

gp

# ������ �������� �� ����� ������ ��� ������ � ��������� �� ������� ------------------------------------
t <- traffic_df()
m <- t %>% group_by(timegroup) %>% nest()

m5 <- t %>% group_by(timegroup) %>%
  mutate(meanr=mean(volume_meanr)) %>%
  ungroup() %>%
  arrange(timegroup)

m2 <- m %>%
  mutate(global_meanr=purrr::map(data, ~ mean(.x$volume_meanr)))
# ���� �� ���������� ����� ����������
m3 <- m2 %>% ungroup() %>% unnest(data)

# �������������� http_hosts ------------------------------------
repl_df <- tribble(
  ~pattern, ~category,
  "instagramm\\.com", "Instagramm",
  "vk\\.com", "���������",
  "xxx", "XXX",
  "facebook.com", "Facebook",
  "twitter.com", "Twitter",
  "windowsupdate\\.com", "Microsoft" 
)

t <- df0 %>% group_by(http_host) %>%
  summarise(n=n())

t2 <- regex_left_join(t, repl_df, by=c(http_host="pattern"))



  