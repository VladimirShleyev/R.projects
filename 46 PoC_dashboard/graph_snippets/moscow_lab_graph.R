# ���������� �������� ����� ��� ������� ����������
#library(tidyr)
library(ggplot2) #load first! (Wickham)
library(lubridate) #load second!
library(dplyr)
library(readr)
library(jsonlite)
library(magrittr)
#library(httr)
library(ggthemes)
library(wesanderson) # https://github.com/karthik/wesanderson
#library(ggmap)
library(RColorBrewer) # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
library(scales)
library(gtable)
library(grid) # ��� grid.newpage()
library(gridExtra) # ��� grid.arrange()
library(curl)
#library(KernSmooth)
#library(akima)
#library(rdrop2)
#library(rgl)



test_timegroup <- function() {
  dd <- dmy_hm("12-05-2016 1:30", tz = "Europe/Moscow")
  dd
  time.bin <- 3
  dd + minutes(time.bin * 60) / 2
  n <- floor(hour(dd + minutes(time.bin * 60) / 2) / time.bin)
  n
  
  floor_date(dd + minutes(time.bin * 60) / 2, unit = "day") + hours(n * time.bin)
}


hgroup.enum <- function(date, time.bin = 4){
  # ����������� ��� ���������, ������� ������ � ���������� +-1/2 ���������, � ����� ���������. 
  # ����� ��������� ����� ���� ������ 1, 2, 3, 4, 6, 12 �����, ������������ time.bin
  # ������ ��������� ���� � 0:00
  tick_time <- date + minutes(time.bin * 60)/2 # �������� �� ��� ��������� ������
  n <- floor(hour(tick_time) / time.bin)
  floor_date(tick_time, unit = "day") + hours(n * time.bin)
}

load_github_field_data <- function() {
  # ���������� ������ �� ��������
  #x <- read.csv( curl("https://github.com/iot-rus/Moscow-Lab/raw/master/result.txt") )
  temp.df <- try({
    read_delim(
      curl("https://github.com/iot-rus/Moscow-Lab/raw/master/result.txt"),
      delim = ";",
      quote = "\"",
      # ����; �����; ���; ������; �������; ������� (0% ���������); �������� (100%); ������� ���������
      col_names = c(
        "date",
        "time",
        "name",
        "lat",
        "lon",
        "calibration_0",
        "calibration_100",
        "voltage"
      ),
      locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"),
      # ��������, � ��������, ����� ���������� �����
      progress = interactive()
    ) # http://barryrowlingson.github.io/hadleyverse/#5
  })

  
  if(class(temp.df) != "try-error") {
    # ����������� ����������� ������
    df <- temp.df %>%
      mutate(value = round(100 / (calibration_100 - calibration_0) * (voltage - calibration_0), 0)) %>%
      # ����������� ��������
      mutate(work.status = (value >= 0 & value <= 100)) %>%
      # ������� ��������� �����
      mutate(timestamp = ymd_hm(paste(date, time), tz = "Europe/Moscow")) %>%
      # �������� ��� �������
      mutate(name = gsub(".*:", "", name, perl = TRUE)) %>%
      mutate(location = "Moscow Lab") %>%
      select(-calibration_0, -calibration_100, -voltage, -date, -time)
  } else {
    df <- NA # � ��������� ������ �� ������������� � ������������� �������� ������
    }
  df
}

# main() ===================================================

#df <- load_github_field_data()
if (!is.na(df)) { raw.df <- df}
# .Last.value

# �������� ���������� �� ��������� �������, ���� ��������� ����������� ��������� ��� � ������� ����� �������
# ��������� ������ �� ������� ��������

# ����������� �� ��������� ����������
raw.df <- raw.df %>%
  mutate(timegroup = hgroup.enum(timestamp, time.bin = 4))
  
  
avg.df <- raw.df %>%
  filter(work.status) %>%
  group_by(location, name, timegroup) %>%
  summarise(value.mean = mean(value), value.sd = sd(value)) %>%
  ungroup() # �������� �����������

plot_palette <- brewer.pal(n = 5, name = "Blues")
plot_palette <- wes_palette(name="Moonrise2") # https://github.com/karthik/wesanderson

# -----------------------------------------------------------
# http://www.cookbook-r.com/Graphs/Shapes_and_line_types/
p1 <- ggplot(raw.df %>% filter(work.status), aes(x = timegroup, y = value, colour = name)) + 
  # http://www.sthda.com/english/wiki/ggplot2-colors-how-to-change-colors-automatically-and-manually
  # scale_fill_brewer(palette="Spectral") + 
  # scale_color_manual(values=wes_palette(n=3, name="GrandBudapest")) +
  # scale_color_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
  # ������ ����������� ��������
  
  geom_ribbon(aes(ymin = 70, ymax = 90), fill = "chartreuse") +
  geom_line(lwd = 2) +
  geom_point(shape = 19, size = 3) +
  geom_hline(yintercept = c(70, 90), lwd = 1.2, linetype = 'dashed') +
  
  scale_x_datetime(labels = date_format(format = "%d.%m%n%H:%M", tz = "Europe/Moscow"),
                   breaks = date_breaks('4 hour') 
                   # minor_breaks = date_breaks('1 hour')
                   ) +
  # ��������� ��������� �������
  geom_point(data = raw.df %>% filter(!work.status), size = 3, shape = 21, stroke = 0, colour = 'red', fill = 'yellow') +
  geom_point(data = raw.df %>% filter(!work.status), size = 3, shape = 13, stroke = 1.1, colour = 'red') +

  theme_igray() + 
  scale_colour_tableau("colorblind10", name = "���������\n�����") +
  # scale_color_brewer(palette = "Set2", name = "���������\n�����") +
  # ylim(0, 100) +
  xlab("����� � ���� ���������") +
  ylab("��������� �����, %") +
  # theme_solarized() +
  # scale_colour_solarized("blue") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  theme(axis.text.y = element_text(angle = 0))

# -----------------------------------------------------------
# http://www.cookbook-r.com/Graphs/Shapes_and_line_types/
p2 <- ggplot(avg.df, aes(x = timegroup, y = value.mean, colour = name)) + 
  # http://www.sthda.com/english/wiki/ggplot2-colors-how-to-change-colors-automatically-and-manually
  # scale_fill_brewer(palette="Dark2") +
  # scale_color_brewer(palette="Dark2") + 
  scale_color_manual(values = plot_palette) +
  scale_fill_manual(values = plot_palette) +
  #scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9")) +
  # ������ ����������� ��������
  
  geom_ribbon(aes(ymin = 70, ymax = 90), fill = "darkseagreen1") +
  geom_ribbon(aes(ymin = 70, ymax = 90), fill = "mediumaquamarine") +
  geom_ribbon(
    aes(ymin = value.mean - value.sd, ymax = value.mean + value.sd, fill = name),
    alpha = 0.3
  ) +
  geom_line(lwd = 1.5) +
  geom_point(data = raw.df, aes(x = timestamp, y = value), shape = 1, size = 2) +
  geom_hline(yintercept = c(70, 90), lwd = 1.2, linetype = 'dashed') +
  geom_point(shape = 19, size = 3) +
  scale_x_datetime(labels = date_format(format = "%d.%m%n%H:%M", tz = "Europe/Moscow"),
                   breaks = date_breaks('8 hour') 
                   # minor_breaks = date_breaks('1 hour')
  ) +
  # ��������� ��������� �������
  # geom_point(data = raw.df %>% filter(!work.status), aes(x = timegroup, y = value), 
  #            size = 3, shape = 21, stroke = 0, colour = 'red', fill = 'yellow') +
  # geom_point(data = raw.df %>% filter(!work.status), aes(x = timegroup, y = value), 
  #            size = 3, shape = 13, stroke = 1.1, colour = 'red') +
  
  theme_igray() + 
  # scale_colour_tableau("colorblind10", name = "���������\n�����") +
  # scale_color_brewer(palette = "Set2", name = "���������\n�����") +
  # ylim(0, 100) +
  xlab("����� � ���� ���������") +
  ylab("��������� �����, %") +
  # theme_solarized() +
  # scale_colour_solarized("blue") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  theme(axis.text.y = element_text(angle = 0))

p2
