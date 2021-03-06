library(tidyverse)

dict_df <- read_csv("rus, enu
                    ����, Table
                    �����, Hat", locale=locale("ru", encoding="windows-1251"), trim_ws=TRUE)

df <- read_csv("enu 
               Table 
               Wizdom", locale=locale("ru", encoding="windows-1251"), trim_ws=TRUE)

# ��� ������������� ��������� �������� NA
df0 <- df %>%
  left_join(dict_df, by="enu") %>%
  select(rus, enu) # �������� �������


df1 <- df0 %>%
  # �������, ��� ��� ������������ ������� �� ������� �������� ����������
  mutate(rus=if_else(is.na(rus), enu, rus))

df2 <- df0 %>%
  # �������, ��� ��� ������������ ������� �� ������� �������� ����������
  select(enu, rus) %>%
  mutate(enu=if_else(is.na(rus), enu, rus))


stop()
  # �������
  mutate(name_rus={map2_chr(.$name_rus, .$name_enu, 
                            ~if_else(is.na(.x), .y, .x))})
