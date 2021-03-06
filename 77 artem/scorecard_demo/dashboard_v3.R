# ��������� ������ ���������� �������
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
library(DT)


df <- tribble(
  ~C0, ~C1, ~C2, ~C3, ~C4, ~C1.status, ~C2.status,
  "���-1", 92, 86, 95, NA, 1, 0,
  "���-2", 83, 72, 83, NA, 0, 1,
  "����", NA, NA, NA, 68, NA, 0,
  "���", NA, NA, NA, 68, NA, NA,
  "����", NA, NA, NA, 68, NA, 0
)

DT::datatable(df, class='cell-border stripe',
              options=list(
                columnDefs=list(list(targets=c(6,7), visible=FALSE)))) %>%
  formatStyle(
    "C1", "C1.status",
    backgroundColor=styleInterval(c(-0.001, 0.999), c('gray', 'green', 'red'))
  ) %>%
  formatStyle(
    "C2", "C2.status",
    backgroundColor=styleInterval(c(-0.001, 0.999), c('gray', 'green', 'red'))
  )

