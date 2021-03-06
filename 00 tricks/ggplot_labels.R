library(tidyverse)
library(reshape2)
library(forcats)
library(magrittr)
library(stringi)

med_dat_rat <- read.delim(text = "Sector,Resident,Nonresident
                          ��,43.43,56.57,
                          ��,59.44,40.56
                          ��,64.71,35.29
                          ��,61.07,38.93
                          ��,50.00,50.00
                          ��,57.14,42.86
                          ��,65.82,34.18
                          ���,57.48,42.52
                          ��,62.26,37.74
                          ��,63.31,36.69
                          ���,64.98,35.02
                          ��,62.87,37.13
                          ��,57.50,42.50", header = TRUE, sep = ",", stringsAsFactors=FALSE)

med_dat2_rat <- melt(med_dat_rat, id.vars = "Sector")
# ������� �� ���������� ��������� med_dat2 �������� str(med_dat2...) � ��� �����? ���� �������� ��� �����!!!

med_dat2_rat %<>%
  mutate(new_sector=stri_replace_all_regex(Sector, " +", ""))

str(med_dat2_rat)

ggplot(med_dat2_rat,
       aes(x=new_sector,
           y=value,
           fill=variable)) +
  geom_bar(stat="identity", width=0.2) +
  # geom_col(width=0.2) +
  scale_x_discrete(drop = FALSE) +
  labs(x = NULL, y = NULL)# +

  #guides(fill=FALSE)
  #theme_bw()
  #scale_y_continuous(limits = c(-10, 110)) +
  #scale_y_continuous(limits = c(-500, 2600)) +
  #scale_x_discrete(expand = c(0, 0)) +
  #theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  #theme(axis.text.x=element_text(vjust=1,hjust=0)) +
  #coord_polar(start = pi)