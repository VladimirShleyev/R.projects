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
#library(ggmap)
library(RColorBrewer) # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
library(scales)
library(gtable)
library(grid) # ��� grid.newpage()
library(gridExtra) # ��� grid.arrange()
# library(KernSmooth)
#library(akima)
#library(rdrop2)
# library(rgl)


ifile <- "./data/appdata_field.csv"
back_days <- 3
# ��������� �� ��������� �������� ������: �������, ����������� ���������� � ���� ����� �������, �������

# ���������� ������ �� ��������
raw.df <- read_delim(
  ifile,
  delim = ",",
  quote = "\"",
  col_names = TRUE,
  locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"),
  # ��������, � ��������, ����� ���������� �����
  # col_types = list(date = col_datetime(format = "%d.%m.%Y %H:%M")),
  progress = interactive()
) # http://barryrowlingson.github.io/hadleyverse/#5

# ���������� ������� ������ � ��������� ������� �� �������� �������� �� ������ ������� ������
# raw.df["time.group"] <- lapply(raw.df$timestamp, function(x){round(x, units="hours")})
# t <- raw.df$timestamp
# object.size(t)

# m <- lapply(raw.df$timestamp, function(x){round(x, units="hours")}) # ��� �� 130 �� �������� 35 ��, ���� ������������ round_date {lubridate}
# m <- lapply(t, function(x){round_date(x, unit = "hour")}) # ��� �������� 8�� !!!
# m <- round_date(t, unit = "hour") # ����� ������� � ���������� �������
# object.size(m)
# object.size(m[[2]])

# ������� �� ������� �������
t.df <- raw.df %>%
  filter(timestamp < lubridate::now()) %>%
  filter(timestamp > lubridate::now() - days(back_days)) %>%
  mutate(timegroup = round_date(timestamp, unit = "hour"))

avg.df <- t.df %>%
  group_by(location, timegroup) %>%
  summarise(value.mean = mean(value), value.sd = sd(value)) %>%
  ungroup() # �������� �����������

object.size(raw.df)
object.size(avg.df)


# ggplot(avg.df, aes(timegroup, value.mean)) +
#   geom_point() +
#   geom_smooth(method="loess", level = 0.99999)

p1 <-
  ggplot(avg.df, aes(timegroup, value.mean, colour = factor(location))) +
  # ggtitle("������ �����������") +
  geom_point() +
  geom_line() +
  #geom_boxplot() +
  ylim(0, NA) +
  theme_solarized() +
  scale_colour_solarized("blue") +
  theme(panel.border = element_rect(
    colour = "black",
    fill = NA,
    size = 2
  ))
# theme_solarized(light = TRUE) +
# scale_colour_solarized("blue")
# theme_hc() +
# scale_colour_hc()


# http://docs.ggplot2.org/current/geom_boxplot.html
# You can also use boxplots with continuous x, as long as you supply a grouping variable.
# http://stackoverflow.com/questions/23433776/change-thickness-of-the-whole-line-geom-boxplot
p2 <- ggplot(raw.df, aes(timestamp, value)) +
  # geom_point(shape = 1) +
  # geom_line() +
  geom_jitter(width = 0.2) +
  ylim(0, NA) +
  geom_boxplot(aes(group = cut_width(timestamp, 86400 / 5))) +
  geom_smooth(method = "loess", level = 0.99999)


p3 <-
  ggplot(t.df, aes(factor(timegroup), value)) +
  # ggtitle("������ �����������") +
  # geom_point() +
  geom_boxplot(outlier.colour = "red", outlier.shape = 20, outlier.size = 5, alpha = 0.5) +
  # ������ ���� ������ group = 1: http://stackoverflow.com/questions/16350720/using-geom-line-with-x-axis-being-factors
  # geom_line(data = avg.df, aes(x = factor(timegroup), y = value.mean, group=1)) +
  geom_smooth(data = avg.df, aes(x = factor(timegroup), y = value.mean, group=1), size = 1.5, method = "loess", se = FALSE) +
  ylim(0, NA)


plot_palette <- brewer.pal(n = 8, name = "Paired") 

my_label_format <- function(x){
  # ������ �������� ��������������
  # ��� ������ ����� ��������� ����, ��� ��������� �����, ������ �����
  label <- as.numeric(x)
  # date_format(format = "%d.%m, %H:%M", tz = "Europe/Moscow") 
  label
}

p4 <- ggplot(avg.df, aes(timegroup, value.mean)) +
  ggtitle("��������� �����") +
  # geom_line() +
  # ������ ����������� ��������
  geom_ribbon(aes(ymin = 70, ymax = 90), fill = plot_palette[3]) +
  geom_hline(yintercept = 70) +
  geom_hline(yintercept = 90) +
  geom_ribbon(
    aes(ymin = value.mean - value.sd, ymax = value.mean + value.sd),
    fill = plot_palette[5],
    alpha = 0.5
  ) +
  geom_point() +
  geom_smooth(size = 1.5, method = "loess", se = FALSE) +
  scale_x_datetime(labels = my_label_format(x),
                   breaks = date_breaks('1 day'),
                   minor_breaks = date_breaks('4 hours')) +
  ylim(0, NA) +
  xlab("����� � ���� ���������") +
  ylab("��������� �����, %") +
  theme_solarized() +
  scale_colour_solarized("blue")

p4