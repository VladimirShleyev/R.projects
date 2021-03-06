library(tidyverse)
library(lubridate)
library(forcats)
library(readr)
library(readxl)
library(stringi)
library(profvis)
library(anytime)
library(config)
library(tictoc)
library(pryr)
library(hrbrthemes)
library(ggthemes)
library(wrapr)
library(openxlsx)
# library(config)
packageVersion("dplyr")

# �������� � ��������� ������� �������� ������ -------------------
data_file <- "./data/KPI_example.xls"
getwd()

raw_df <- read_excel(data_file) %>%
  mutate_at(vars(docdate), as_date)

# �������� ������ �� ������ ---------------------
if (FALSE) {
  tic()
  # ��������� ���������� ���������� �������� � ��������
  dist_cols <- raw_df %>% map_df(n_distinct)
  # ��������� � ����������� ��������� ���������� ��������
  unq <- map(raw_df, unique) %>% map(sort, decreasing = T)
  # unq
  dist_cols
  toc()
}

subset_df <- raw_df %>% 
  mutate(deparse=stri_replace_all_regex(name, "(.+\\s��)\\s+(����|����)\\s?(���\\s\\d)?\\s?(.*)", 
                                        "$1_$2_$3_$4")) %>%
  separate(deparse, into=c("operation", "group", "material", "kpi"), sep="_") %>%
  # ������� ������ ������������ ��������
  filter(operation %in% c("������ ��", "����� ��", "�������� ��")) %>%
  # � ������� ���� ��������� ����
  select(-id, -unit, -firmcode, -docnum)

# �������� ������ �� ���������� ����
c_date <- dmy("10.09.2015") # current date

# ���� ����� �������� ���� ��� �����
df0 <- subset_df %>%
  filter(docdate>=c_date-days(2) & docdate<=c_date) %>%
  filter(material!="" & kpi=="")

# ���� ����� ������������ � �������� ���� ��� "�����"
df1 <- df0 %>%
  group_by(docdate, kpi) %>%
  summarise(actualvalue=sum(actualvalue), planvalue=sum(planvalue), material="�����") %>%
  ungroup()

score_df <- bind_rows(df0, df1) %>%
  # filter(docdate>=c_date-days(2) & docdate<=c_date) %>%
  # filter(material!="" & kpi=="") %>%
  mutate(status=as.factor(if_else(is.na(planvalue), TRUE, actualvalue>planvalue))) %>%
  mutate(label=format(actualvalue, big.mark=" "))

ggplot(score_df, aes(x=docdate, y=actualvalue)) +
  geom_bar(aes(fill=status), stat="identity") +
  scale_fill_manual(
    values=c("FALSE"="brown1", "TRUE"="chartreuse4"),
    # breaks=c("4", "6", "8"),
    # ������ ����������, ���������� �� ��������
    labels=c("��������", "� �����")
  ) +
  # �������� �������� �������� ������
  geom_point(aes(y=planvalue), colour="blue", shape=16, size=3) +
  geom_label(aes(label=label), position = position_stack(vjust = 0.5), 
             fill="white", colour="black", fontface="bold", hjust=.5) +
  facet_wrap(~material, nrow=1)


