library(tidyverse)
library(readxl)
library(magrittr)

eval(parse("funcs.R", encoding="UTF-8"))
# Key - oip, value - ss1 or ss2 or ss3

old_df <- read_excel("./data/old.xlsx")
new_df <- read_excel("./data/new.xlsx")
  
# �����, �������, ������������ �������� ����� �������� file.choose()

key_name <- "oip"
val_name <- "ss2"

diff_df <- cmpExcelCols(old_df, new_df, key_name, val_name)




stop()

# 2. ������� ����� � ����������� ������������� ����������
diff_df %<>% 
  # ����� ���������� ����������, ��������� ����� ������������ ������� �������� 
  # ��� ���������� �� �������� ���������
  filter_(lazyeval::interp(~ new!=old, 
                           new=as.name(values$new),
                           old=as.name(values$old))) %>%
  # 3. ��������� ������ ������������ �������
  # ������������, ��� ���������� ����������, ���� ������������� ������, ������� ������ ��� NSE
  select(oip, one_of(unlist(values)))





# ������� ����������� ��� SE\NSE ======================================================

  
  filter_(lazyeval::interp(~ new==old, 
                           new=as.name(paste0(val_name, "_new")),
                           old=as.name(paste0(val_name, "_old"))))

  
  
  filter_(lazyeval::interp(~ new==old, 
                           new=paste0(as.name("val_name"), "_new"),
                           old=paste0(as.name("val_name"), "_old")))

  filter_(lazyeval::interp(~ new==old, 
                           new=as.name(paste0(val_name, "_new")),
                           old=as.name(paste0(val_name, "_old"))))
  

# ======================================================
  filter_(lazyeval::interp(~ new==old, 
                           .values=list(new=as.name(paste0(val_name, "_new")),
                                        old=as.name(paste0(val_name, "_old")))))
# ������ by=key_name -- ��������, �� ����� ��������������� ����� full_join

# ����������� ����� ������� �������, ������� ����������, ��������� ��� ��������

# select(one_of(c(key_name, val_name))) %>%
  