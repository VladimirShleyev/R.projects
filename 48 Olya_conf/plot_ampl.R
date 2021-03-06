# ���������� �������� ����� ��� ������� ����������
#library(tidyr)
library(ggplot2) #load first! (Wickham)
library(ggdendro) # ��� ������ ����
library(lubridate) #load second!
library(ggrepel)
library(dplyr)
library(readr)
library(scales)
library(colorRamps)
library(RColorBrewer)
library(arules)
library(iterators)
library(foreach)

# ������ ������ �������, ����� �������� ������ "In is.gtable(x) : reached elapsed time limit"
setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE) 

n_ampl <- 1 # ����� ��� �� ������� ������� ��������� [1, 2]
# ������ ������
getwd()
# ����������� �������� ��������� �� ���� (0.02 k+0.01 ��� � �� 0 �� 78).
angles <- seq(from = 0.01, to = 1.57, by = 0.02)

read_data <- function(angle, n_ampl){
  #cat(n_ampl)
  read_delim(paste0("./ampl/ampl", n_ampl, "(angle=", angle, ").csv"), delim = ";", quote = "\"",
             # ���������; ����; ��������
             col_names = c(
               "harm",
               "ampl"
             ),
             col_types = "dd",
             locale = locale("ru", encoding = "windows-1251", tz = "Europe/Moscow"), # ��������, � ��������, ����� ���������� �����
             progress = interactive()
  ) # http://barryrowlingson.github.io/hadleyverse/#5
}

# http://brianmannmath.github.io/blog/2014/01/20/using-lapply-to-import-files-to-r/
# df <- lapply(angles, read_data)
# ����������� �� �������� data.frame
# http://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
if(TRUE){
  df <- foreach(it = iter(angles), .combine = rbind) %dopar% {
  # cat("----\n"); str(it);
  temp.df <- read_data(it, n_ampl)
  problems(temp.df)
  temp.df$angle = it
  
  temp.df
  }
}

df <- df %>% filter(complete.cases(.)) %>% # ������� NA ������
  # ������� ��� ��������� �������� ������� ������ �����. �� �������� � ���������� �������� ����
  mutate(submarker = as.factor(harm %% 4)) %>% 
  mutate(source_harm = harm) %>%
  mutate(harm = harm / (2 * pi * 10)) %>%
  mutate(round_harm = round(harm, 0))


summary(df)

#levs <- list(categories = seq(from = min(df$harm), to = max(df$harm), length.out = 11))
levs <- list(categories = seq(from = 0, to = max(df$harm), length.out = 11))
levs$labels <- paste0(head(ceiling(levs$categories), -1), ' - ', tail(floor(levs$categories), -1))

# ������� ��������
df1 <- df %>%
  mutate(marker = discretize(harm, method = "fixed",
                             categories = levs$categories,
                             labels = levs$labels)) %>%
  #mutate(submarker = as.factor(round(harm) %% 4)) %>% # ������� ��� ��������� �������� ������� ������ �����
  # � ������ ��������� ������ ����� �������� (1-3, 4-7, 8-11)
  filter(harm < 12) %>%
  filter(ampl > 8) %>% # ��������� ����� �����
  arrange(marker, angle)

# http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
plot_palette <- brewer.pal(n = 11, name = "Set3")
# plot_palette <- rep( brewer.pal(n = 9, name = "Oranges")[c(3, 7)]) +
plot_palette <- colorRampPalette(brewer.pal(9, "Set1"))

# ����� ������
pp.base <- ggplot(df1, aes(x = angle, y = ampl, colour = as.factor(round_harm))) +
  # guides(colour = FALSE) + # ������� �������
  # geom_point( shape = 21, alpha = 0.6) +
  # geom_point(size = 1, shape = 21, alpha = 0.6) +
  geom_point(size = 2, shape = 16, alpha = 1) + # ����������� ������
  # geom_text_repel(aes(label = harm)) +
  # scale_colour_gradientn(colours = rev(brewer.pal(11, "Spectral")), guide = TRUE) +
  # scale_colour_manual(values = plot_palette) +
  # http://novyden.blogspot.ru/2013/09/how-to-expand-color-palette-with-ggplot.html
  scale_colour_manual(values = colorRampPalette(brewer.pal(9, "Set1"))(12),
                      name = "# ���������")+
  # geom_line(lwd = 0.5) +
  scale_x_continuous(breaks = c(0, pi/4, pi/2), 
                     labels = c("0", expression(paste(pi, "/4")), expression(paste(pi, "/2")))) +  
  xlab(expression(paste(alpha))) +
  ylab("���������") + 
  theme_bw()

pp <- pp.base +
  facet_wrap( ~ marker, scales="free", ncol = 5)


pp

ggsave(paste0("_ilya_ampl", n_ampl, "_facet.png"), plot = pp, width = 30, height = 15, units = 'cm', dpi = 300)

write.table(
  df1,
  file = paste0("_ilya_ampl", n_ampl, "_joined.csv"),
  sep = ",",
  row.names = FALSE,
  qmethod = "double"
)

