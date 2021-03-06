library(tidyverse)
library(lubridate)
library(magrittr)
library(forcats)
library(ggrepel)
library(stringi)
library(stringr)
library(shiny)
library(jsonlite)
#library(DBI)
#library(RPostgreSQL)
library(anytime)
library(tictoc)
library(profvis)
library(microbenchmark)
library(Cairo)
library(RColorBrewer)
library(extrafont)
library(hrbrthemes)
# library(debug)
library(config)



rm(list=ls()) # ������� ��� ����������
df0 <- jsonlite::fromJSON("data_dict.json", simplifyDataFrame=TRUE)

# �� ������ ������ ��������� �� ������, ����� ������ �� ���������� ���� internal_name
if (!"internal_name" %in% names(df0)) df0$internal_name <- NA

dict_df <- df0 %>%
  as_tibble() %>%
  # ���� ���� ���� � ��, � ���������� ������������� �� ������, �� ��������� �����������
  mutate(internal_name={map2_chr(.$db_field, .$internal_name, ~if_else(!is.na(.x) & is.na(.y), .x, .y))})



m <- separate_rows(data_model_df, aggr_ops, sep="[,;[:space:]]+")


  

dict_df <- dplyr::union(var_model_df %>% select(name_enu=internal_name, name_rus=visual_var_name),
                       group_model_df %>% select(name_enu=internal_name, name_rus=visual_group_name))

#data <- as.list(df2$query_name)
#names(data) <- df2$visual_name


stop()

data <- setNames(as.list(var_model_df$internal_name), var_model_df$visual_var_name)

# �������� ������ ���������� � ����� SELECT
data_model %>%
  {purrr::map2_chr(.$ch_query_name, .$col_name, ~str_c(.x, " AS ", .y))} %>%
  stri_join(sep="", collapse=", ")

# ������ �������� ��������� ������ � ������. � �����������
# updateSelectizeInput(session, 'foo', choices=data, server=TRUE)


# ���� ��� ������������� � ���������� ����� �����
df <- jsonlite::fromJSON("datamodel.json", simplifyDataFrame=TRUE) %>%
  select(-col_name, -col_runame_office) %>%
  rename(human_name_rus=col_runame_screen) %>%
  arrange(db_field) %>%
  select(db_field, human_name_rus, can_be_grouped, aggr_ops, everything())

df <- jsonlite::fromJSON("datamodel.json", simplifyDataFrame=TRUE) %>%
  mutate(select_string={map2_chr(.$internal_name, .$db_field, 
                                 ~if_else(is.na(.x), .y, stri_join(.y, " AS ", .x)))}) %>%
  mutate(internal_name={map2_chr(.$internal_name, .$db_field, ~if_else(is.na(.x), .y, .x))})
  # select(-visual_name, -query_name)
  # mutate(can_be_grouped=FALSE) 
  # rename(visual_var_name=visual_name, visual_group_name=can_be_grouped)

model_json <- jsonlite::toJSON(df, pretty=TRUE)
write_lines(model_json, "datamodel_new.json") # ��������� � UTF

# write_json(df, "datamodel_new.json") #, sep = "\t", fileEncoding="utf-8")


# df1 <- separate_rows(df, aggr_ops)

stop()
# ��������� �������� json �������
rm(list=ls()) # ������� ��� ����������
df <- tribble(
  ~col_name, ~col_runame_screen, ~col_runame_office, ~col_label, 
  "region", "������", "������","�������� �������, ���������� � ���������� STB",
  "unique_stb", "���-�� ����. STB", "���-�� ����. STB", "���������� ���������� STB � �������",
  "total_unique_stb", "����� ����. STB", "����� ����. STB", "����� ���������� ���������� STB �� ���� ��������",
  "total_duration", "��������� �����, ���",	"��������� �����, ���",	"��������� ����� ��������� ������ ����� STB",
  "watch_events", "���-�� ����������", "���-�� ����������", "��������� ���������� ������� ������������� � �������",
  "stb_ratio", "% ����. STB", "% ����. STB", "����������� STB � ������� � ������ ���������� STB",
  "segment", "�������", "�������", "��������� (segment)",
  "channelId", "����� (ID)", "�����  (ID)", "��������� (channelId)",
  "channelName", "�����", "�����", "�������� ����������",
  "channel_duration", "��������� �����, ���", "��������� �����, ���", "��������� ����� ������������� ����� STB � �������",
  "mean_duration", "��. ����� ���������, ���", "��. ����� ���������, ���", "������� ����� ���������� ��������� ������",
  "watch_ratio", "% ����. ���������", "% ����. ���������", "��������� ������� ��������� ������ � ������ ������� �������������",
  "duration_per_stb", "��. ����� �����. 1 STB �� ������, ���", "��. ����� �����. 1 STB �� ������, ���", "������� ����� ���������� ��������� ������ ����� ���������� �� ��������� ������",
  "date", "����", "����", "��������� (date)",
  "timestamp", "�����", "�����", "��������� (timestamp)",
  "timegroup", "������", "������", "��������� (timegroup)"
) %>%
  mutate(db_field=col_name) %>%
  select(db_field, internal_name=col_name, human_name_rus=col_runame_screen, 
         -col_runame_office, col_label)
  

dic_json <- jsonlite::toJSON(df, pretty=TRUE)
write_lines(dic_json, "dic_temp.json") # ��������� � UTF



