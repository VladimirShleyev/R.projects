library(dplyr)
library(lubridate)
library(tidyr)
library(magrittr)
library(purrr)
library(stringr)
library(tibble)
library(readxl)


# ��� �� ���������� ����� �������
col_types <- readxl:::xlsx_col_types("merged_master_families_matrix_ver_0_13.xlsx")
col_types <- rep("text", length(col_types))
mmfm <- read_excel("merged_master_families_matrix_ver_0_13.xlsx", 
                   sheet = "merged_master_families_matrix", 
                   col_types = col_types)
# ����� ��������, ������� � NA ������ �����

# ����� ������ � ���� ��������������, �� ���������� ������ �� ����
# �������������� �������
df0 <- mmfm %>%
  repair_names(prefix = "repaired_", sep = "")

# ������ ������ �������, ������� ����� ������ ����� (NA)
df1 <- df0 %>%
  select(-starts_with("repaired_"))

# � ������ ���� ��������, ��������� �� ����� �� �����������, ���� ����, ���� ������ '20121231', 
# � excel ��� � ��� ����������� ���� � �����.
# � �����, �����, ������� ������ 10^7 �������� ������ �� �������������, 
# � ������� -- ���� � ��������� ���� excel
# � ��� ���� �����-�� ���������� ������ ����� (����� ���)
# ������������ na.omit() �� ����������, �� 450 ����� �������� 86, 
# ������� ������ ��, � ������� ���� �����������
df2 <- df1 %>%
  mutate(numpd = as.numeric(.[["Priority date"]])) %>%
  filter(!is.na(numpd)) # ������� ��� ������, ���������� ������ ������

# dput(ymd(20090122)) # ���� Date, � �� POSIXct! ������-��, ������� ������, ��� �� ����� ����� �� ������
# ��������� ���������, �� 

# ������������� � ������� ��������, ����� ��������� ������ mutate
parseDate <- Vectorize(function(x){
 if(x > 1e7) ymd(x) else as.Date(x, origin = "1899-12-30") # origin �� ������� as.Date
})

# ���-�� � ���� �������������� Date ������ ���� ����� � ������������ ������ � ����� �����
# ������������� ������ �����
df <- df2 %>%
  mutate(priority_date = as.Date(parseDate(numpd), origin = "1970-01-01"))
  
t <- df %>%
  select(priority_date)

# �� ������� as.Date
## Excel is said to use 1900-01-01 as day 1 (Windows default) or
## 1904-01-01 as day 0 (Mac default), but this is complicated by Excel
## incorrectly treating 1900 as a leap year.
## So for dates (post-1901) from Windows Excel
as.Date(35981, origin = "1899-12-30") # 1998-07-05
## and Mac Excel
as.Date(34519, origin = "1904-01-01") # 1998-07-05
## (these values come from http://support.microsoft.com/kb/214330)
  
  
#  mutate(priority_date = if_else(numpd > 1e7, ymd(.[["Priority date"]]),
#                                 as.POSIXct((numpd - 25569) * 86400, tz = "GMT", origin = "1970-01-01")))


stop()


# =========== ���������� 5.2.4 ����� 1.3 from r4ds
# Find all flights were operated by United, American, or Delta

library(nycflights13)
library(tidyverse)
library(stringr)

head(flights)

carrier_list <- airlines %>%
  filter(str_detect(name, '^United|^American|^Delta')) %>%
  '[['('carrier')


f1 <- flights %>%
  filter(str_detect(carrier, str_c(carrier_list, collapse='|')))
stop()

# ����� ������� �������
# d <- purrr::map(c(20090122, 20090123, 34890), pd)
# df2$priority_date <- purrr::map(c(20090122, 20090123, 34890), pd)

dput(df$priority_date)  

mutate(priority_date = if_else(numpd > 1e7, 0, numpd))

ymd(numpd) 

mutate(priority_date = if_else(numpd > 1e7, ymd(.[["Priority date"]]),
                               as.Date(numpd, origin = "1899-12-30")))



m <- as.numeric(mmfm[["Priority date"]])

#as.character(as.POSIXct(as.numeric(mmfm[["Priority date"]]) * (60*60*24), origin="1899-12-30", tz="GMT"), format = "%Y%m%d")

#mmfm[nchar(mmfm[["Priority date"]]) == 5, "Priority date"]

mmfm[nchar(mmfm[["Priority date"]]) == 5, "Priority date"] <- 
  as.character(as.POSIXct(as.numeric(mmfm[nchar(mmfm[["Priority date"]]) == 5, "Priority date"]) * (60*60*24)
    , origin="1899-12-30"
    , tz="GMT"), format = "%Y%m%d")

