library(tidyverse)
library(readxl)
library(fs)
library(stringi)

fname <- dir_ls("./data", regexp=".+/(?!~)[^/]+(?<!unprotected)\\.xls.?", 
                perl=TRUE) # ���������� ���� �������� ������ (c ~)

print(fname)

ws <- "������ - ��-���"
fname2 <- stri_conv(fname, from="UTF-8", to_raw=FALSE)
df <- read_excel(fname2[[1]], sheet=ws)
