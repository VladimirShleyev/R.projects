library(readr) #Hadley Wickham, http://blog.rstudio.org/2015/04/09/readr-0-1-0/
# library(readxl) # https://github.com/hadley/readxl
library(dplyr)
library(magrittr)
library(ggplot2) #load first! (Wickham)
library(lubridate) #load second!
library(scales)
#library(forecast)
library(stringr)
library(purrr)
library(tibble)
#library(RColorBrewer)
#library(wesanderson) # https://github.com/karthik/wesanderson
#library(broom)

source("funcs.R") # ���� ������� ��� �������������� � ������������� �������

# readxl - http://poldham.github.io/reading-writing-excel-files-R/
# rawdata <- read_excel("./src/tv_sample.xlsx", sheet = 1, col_names = TRUE, col_types =)

# ��������, ��� ������������ ���� � ����� ��������� �������
tdate <- dmy_hms("19.01.2015 17:52:51Z+00", truncated = 3, tz = "Europe/Moscow")
tdate
with_tz(tdate, tz = "Asia/Yekaterinburg")

# ���������� timezone
# http://stackoverflow.com/questions/36300381/dplyr-mutate-with-function-call-returning-incorrect-value
# http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml
get_tz <- function(m) {
  case_when(m == "������" ~ "Europe/Moscow",
            m == "�����" ~ "Asia/Yekaterinburg")
}

# ��� �� ������� ��, ��� dmy �� ��������� tz � ���� �������
get_tz_offset <- function(m) {
  case_when(m == "������" ~ "+03",
            m == "�����" ~ "+05")
}

# http://barryrowlingson.github.io/hadleyverse/#5
# ����� ����������� �����
raw_tv.df <- read_delim(
  "./data/tv.csv", delim = ";", quote = "\"",
  col_names = TRUE,
  col_types = str_c(rep("c", 18), collapse = ""),
  locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"), # ��������, � ��������, ����� ���������� �����
  progress = interactive()
)

raw_installs.df <- read_delim(
  "./data/installs.csv", delim = ";", quote = "\"",
  col_types = "cci",
  locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"), # ��������, � ��������, ����� ���������� �����
  progress = interactive()
)

raw_visits.df <- read_delim(
  "./data/visits.csv", delim = ";", quote = "\"",
  col_types = "cciii",
  locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"), # ��������, � ��������, ����� ���������� �����
  progress = interactive()
)

# ������� �������������� �������

problems(raw_tv.df)
problems(raw_installs.df)
problems(raw_visits.df)
unique(raw_tv.df$city)
dplyr::distinct(raw_tv.df, city)

# ���� �������� ������ ���������� �������� �� ������ �������, ������������
t1 <- map(raw_tv.df, unique) # or length
t2 <- map(raw_installs.df, unique)
t3 <- map(raw_visits.df, unique)

# ===== �������� ����� � �������, ����� �������� ������ ���������� copy-paste
raw_tv.df %<>%
  mutate(timestamp = dmy_hms(str_c(local_date, local_time, "Z", get_tz_offset(city), sep = " "), 
                             truncated = 3, tz = "Europe/Moscow")) 
raw_installs.df %<>%
  mutate(timestamp = dmy_hms(moscow_time, truncated = 3, tz = "Europe/Moscow")) 
raw_visits.df %<>%
  mutate(timestamp = dmy_hms(moscow_time, truncated = 3, tz = "Europe/Moscow"))

#  select(city, local_time, local_date, timestamp)

# ===== ��������� ��������� �� ������
# ���������� ��������, ���� ���������

s_date <- dmy_hm("18.01.2015 0:0", tz="Europe/Moscow")
e_date <- s_date + days(60)

dst <- "�����"
dst <- "������"
# http://stackoverflow.com/questions/24569154/use-variable-names-in-functions-of-dplyr

subdata <- raw_installs.df %>%
  filter_(str_c("city == '", dst, "'")) %>%
  mutate(timestamp = dmy_hms(moscow_time, truncated = 3, tz = "Europe/Moscow")) %>%
  #mutate(timestamp2 = lubridate::with_tz(timestamp, tzone = 'Asia/Yekaterinburg')) %>%
  # mutate_(timestamp = str_c("lubridate::with_tz(timestamp, tzone = '", get_tz(dst), "')")) %>% # ��������
  filter(timestamp > s_date & timestamp < e_date) %>%
  mutate(timegroup = hgroup.enum(timestamp, time.bin = 1)) %>%
  # ��������� ��� �����������
  group_by(timegroup) %>%
  summarise(inst = sum(installations))

tv.df <- raw_tv.df %>% 
  select(timestamp, city) %>%
  filter_(str_c("city == '", dst, "'")) %>%
  filter(timestamp > s_date & timestamp < e_date) %>%
  mutate(stub = 1000)

gp <- ggplot(subdata, aes(x = timegroup, y = inst)) +
  geom_point(size = 2, shape = 21) + # produce scatterplot
  geom_line(lwd = 1) +
  scale_x_datetime(labels = date_format_tz("%d.%m %H:%M", tz = get_tz(dst)),
  #scale_x_datetime(labels = date_format_tz("%d.%m %H:%M", tz = "Europe/Moscow"), 
                   breaks = date_breaks("4 hours"), 
                   minor_breaks = date_breaks("30 mins")) + 
  # ������� ���� ������ �� ������ �������
  geom_point(data = tv.df, mapping = aes(x = timestamp, y = stub), size = 1, color = "red") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
gp


stop()

