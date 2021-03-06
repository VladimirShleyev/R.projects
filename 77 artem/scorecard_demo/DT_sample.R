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

raw_df <- read_excel(data_file)

# �������� ������ �� ������ ---------------------
if (TRUE) {
  tic()
  # ��������� ���������� ���������� �������� � ��������
  dist_cols <- raw_df %>% map_df(n_distinct)
  # ��������� � ����������� ��������� ���������� ��������
  unq <- map(raw_df, unique) %>% map(sort, decreasing = T)
  # unq
  dist_cols
  toc()
}

# ������� ������ �� ������, ������� ��� ��������� ��� scoreboard
pattern <- c("������ �� ���� ���", "�������� �� ����", "����� �� ����",
             "������ �� ���� ���", "�������� �� ����", "����� �� ����"
             ) %>%
  stri_replace_all_regex("(.+)", "($1)") %>%
  stri_join(collapse="|")

# pattern <- "(������ �� ���� ���)|(������ �� ���� ��� \\d.+��)|(����� �� (����)|(����))|(����� �� ����)|(�������� �� ����)|(�������� �� ����.+��)"
# pattern <- "(������ �� ���� ���)|(������ �� ���� ��� \\d.+��)|(����� �� ����|����)"
# stri_detect_regex("����������� ������ �� ���� ��� 3", pattern) # -- ���� TRUE

# stri_detect_regex("����������� ������ �� ���� ��� 3", pattern) # -- ���� TRUE

subset_df <- raw_df %>% 
  filter(stri_detect_regex(name, pattern=pattern)) %>%
  mutate_at(vars(docdate), as_date)

# �������� ������ �� ���������� ����
c_date <- dmy("10.09.2015") # current date

score_df <- subset_df %>%
  # ������� ��������� ���� ��� ���� ������� ����� �������
  mutate(skip=!stri_detect_regex(name, pattern="������ �� .+ ��� \\d$") & docdate!=c_date) %>%
  filter(!skip) %>%
  # ������� ������������������ �� �����, ����� �� �����
  mutate(coltype=case_when(
    docdate == c_date ~ "today",
    docdate == c_date-days(1) ~ "today_minus_1",
    docdate == c_date-days(2) ~ "today_minus_2",
    TRUE ~ as.character(NA)
  )) %>%
  mutate(coltype=case_when(
    stri_detect_regex(name, pattern="�������� .+% ��$") ~ "shipment_pcumm",
    stri_detect_regex(name, pattern="�������� .+ ��$") ~ "shipment_cumm",
    stri_detect_regex(name, pattern="�������� .+$") ~ "shipment",
    stri_detect_regex(name, pattern="����� .+") ~ "stock",
    stri_detect_regex(name, pattern="������ .+% ��$") ~ "output_pcumm",
    stri_detect_regex(name, pattern="������ .+ ��$") ~ "output_cumm",
    TRUE ~ coltype
  )) %>%
  # filter(complete.cases(.)) # ��� �� �������, ����� ���� �������� ��� ��� �������� �����������. ������ �����
  filter_at(vars(actualvalue, coltype), all_vars(!is.na(.)))
  
df <- score_df %>%
  unite(actualvalue, planvalue, col=values) %>%
  spread(coltype, values) %>%
  # ������ ���������� ��������� ������ � �������
  select(-firmcode, docnum, skip) %>%
  # 
#
  mutate("shipment"=today)


stop()

# ������� �������������� ����� �������
# �������� ������� ��������� �� ������� 2-4. 2-�� -- ������������, 3-� -- ��������������, 4-�� -- �����
# ���� �� ����� � ������������� �������, ������ ��������� ����� ������ 3, ��� ����������
# ��������� ���� join �� ��������, ��������� �� ����� �������� ��� ������, ��� ����������� �� ����������
# ������� �� ������ ������, ����� ���� �����
names_df <- raw_df %>%
  {tibble(name_c2=gather(.[2, ], key=name, value=v)$v,
          name_c3=gather(.[3, ], key=name, value=v)$v,
          name_c4=gather(.[4, ], key=name, value=v)$v)} %>%
  # http://www.markhneedham.com/blog/2015/06/28/r-dplyr-update-rows-with-earlierprevious-rows-values/
  # mutate(name_c2 = na.locf(name_c2)) %>%
  fill(name_c2) %>%
  # ���� name_c3 = NA, �� ��������� ����������� ����� ����� ����� NA, ��� ��� �� ����� ����������
  # replace_na(list(name_c3="")) %>%
  mutate(complex_name=if_else(is.na(name_c3),
                              stri_join(name_c4, name_c2, sep=": "),
                              stri_join(name_c4, name_c2, name_c3, sep=": ")))

# ����������� �������
names(raw_df) <- names_df$complex_name

#  [1] "1: �� �.�."                                         "2: � ���������, ��������� �����"                   
#  [3] "3: �����������: ��� ���� ���"                       "4: �����������: ��� ���"                           
#  [5] "5: �����������: ��� ���� ����"                      "6: �����������: ��� ����"                          
#  [7] "7: �����������: ����� ����� ���"                    "8: �����������: ��� ���� ������"                   
#  [9] "9: ������������ ��"                                 "10: �������� ����������: ��.���."                  
# [11] "11: �������� ����������: ���-��"                    "12: ������� ���������, ���.: ������������ ������"  
# [13] "13: ������� ���������, ���.: ��������� ������"      "14: ������� ���������, ���.: ������������"         
# [15] "15: ������� ���������, ���.: ������ ������"         "16: ������� ���������, ���.: �����"                
# [17] "17: �������� �����"                                 "18: ���������(������������, �������, ����� � �.�.)"
# [19] "19: ���� ���� ��"  


# ������ ������� ����������� ��� �������, ������� ����� ������������ � ������� � ������� ������� �����
df0 <- raw_df %>% 
  rename_at(c(3, 4, 5, 6, 7), 
            funs(c("oks_type", "oks_code", "ossr_type", "ossr_code", "ssr_chap"))) %>%
  # ������� ������� ��� ����������� �������
  rename_at(12:16, 
          funs(c("������������ ������", "��������� ������", "������������", "������ ������", "�����"))) %>%
  rename_at(12:17, funs(c("12", "13", "14", "15", "16", "internal_id"))) %>%
  rename_at(8, funs(c("cost_element"))) %>%  
  slice(6:n())

# ������������� � �������� --------------------
# ������ ������� ��������� �� ���������� ���� � ���, �.� ��� ��� � ��� ���� ������� �� "0000", 
# ���� ���� ��� � ���� = "0000" �� ��� ������� ���������, ��� ��������� �� ������ � ����� 
# � �� ����� ������������ �� ��������� ������� ��� ��������������� ���� ������ ������.

# ������������������ �������� ��������������, ��������� ���� ��������� �� ��������
clean_df <- df0 %>%
  # �������� �������� ������ �����
  # ������� "����� (����� 16)" �������� �����������, ������� �� ��������
  # ��������� ������ � �������� ������� (internal_id), ���� ������ ���������� �� �����
  # select(-(16:19)) %>%
  # ��������� ��� ������
  # mutate(indirect_cost=if_else(oks_code=="0000" & ossr_code=="000", TRUE, FALSE)) # %>%
  mutate(indirect_cost=(oks_code=="0000" & ossr_code=="000")) %>%
  # ������� ��� ���� ������, ����� ����� � �������� �������� ������������ ��� ������
  gather(12:15, key="est_cost_entry", value="est_cost") %>%
  select(oks_type, oks_code, ossr_code, ssr_chap, indirect_cost, 
         est_cost_entry, est_cost, "9: ������������ ��", cost_element, internal_id) %>%
  # �������� ��� ���� ���� ������ (cost_element) �������� �������������� ����������, �� ���� ���� ���������
  # �� ����� ��������� ������, ���� ������� �������� ��������� �������
  # filter(complete.cases(.)) %>% 
  mutate_at(vars(est_cost), as.numeric) %>%
  mutate_at(vars(est_cost_entry), as.integer) %>%
  # �������� ������� ������� � ������������� ��������
  # filter_at(vars(est_cost, cost_element), any_vars(is.na(.))) %>%
  filter(est_cost != 0) %>%
  # ����������� ������ ���� ������ � ������ �������� �����
  filter_at(vars(cost_element, internal_id), all_vars(!is.na(.)))


# ��������� ������ ������� �� ������ � �� ������ ---------
direct_df <- clean_df %>%
  filter(!indirect_cost) %>%
  filter((ssr_chap %in% stri_split_fixed("02,03,04,05,06,07", ",", simplify=TRUE))) %>%
  group_by(ssr_chap, est_cost_entry) %>%
  summarise(total_cost=sum(est_cost)) %>%
  ungroup() %>%
  # mutate_at(vars(est_cost_entry), as.character)#  %>%
  spread(key=est_cost_entry, value=total_cost)

# ��������� ��������� ������� �� ������ --------
calc_cost <- function(chap, df){
  print(paste0("����� ", chap))
  # ���� ������� ������ ���������� ��� ������ ����� ��������
  calc_rules <- list("01"=12:15, "08"=12:15,
                     "09"=12:15, "10"=12:15, "12"=12:15)
  res <- df %>%
      filter(est_cost_entry %in% calc_rules[[chap]]) %>%
      summarise(res=sum(est_cost)) %>%
      pull(res)
  print(res)    
  res
}
  
indirect_df <- clean_df %>%
  filter(indirect_cost) %>%
  # filter(!is.na(cost_element)) %>% # ��� ��������� ����
  filter((ssr_chap %in% c("01", "08", "09", "10", "12"))) %>%
  arrange(ssr_chap) %>%
  group_by(ssr_chap) %>%
  nest() %>%
  # ��������� ���� ������������� � ����������� �� ����� ���
  mutate(chap_indirect_�ost=purrr::map2_dbl(ssr_chap, data, ~calc_cost(.x, .y))) %>%
  select(-data)

# ������������ ��������� ������� �� ������ � ����������� �� ����� ��� -------------
final_df <- clean_df %>%
  filter(!indirect_cost) %>%
  filter((ssr_chap %in% stri_split_fixed("02,03,04,05,06,07", ",", simplify=TRUE))) %>%
  select(-indirect_cost, -cost_element, -internal_id)

# ������������� ���������� � �������������
if(FALSE){
# ������������ ������������� �� ������ 1, 8, 9
t1 <- final_df %>% 
  group_by(ssr_chap) %>%
  filter(est_cost_entry %in% c(12, 13)) %>%
  summarise(s=sum(est_cost)) %>%
  # ������� ���������
  mutate(`01`=s/sum(s), `08`=`01`, `09`=`01`) %>%
  select(-s)

# ������������ ������������� �� ������ 10, 12
t2 <- final_df %>% 
  group_by(ssr_chap) %>%
  filter(est_cost_entry %in% c(12, 13, 14, 15)) %>%
  summarise(s=sum(est_cost)) %>%
  # ������� ���������
  mutate(`10`=s/sum(s), `12`=`10`) %>%
  select(-s)

tr <- left_join(t1, t2, by="ssr_chap") %>% 
  gather(`01`,`08`,`09`, `10`, `12`, key=indirect_chap, value=ratio) %>%
  # ����������� ��������� ������� �� �����
  left_join(indirect_df, by=c("indirect_chap"="ssr_chap")) %>%
  mutate(cost_raise=ratio*chap_indirect_�ost) %>%
  arrange(ssr_chap)# %>%
  # spread(indirect_chap, cost_raise)
}

# ������ � "���"
# ��������� ���� ������������� ��� ���� 2-7

base_cost <- list(s1213=c(12, 13), s1215=c(12, 13, 14, 15)) %>%
  map(~sum(final_df %>% filter(est_cost_entry %in% .x) %>% pull(est_cost)))
s1213 <- base_cost[["s1213"]]
s1215 <- base_cost[["s1215"]]

v <- indirect_df$chap_indirect_�ost %>% set_names(indirect_df$ssr_chap)

final_df %<>% group_by(ssr_chap) %>%
  mutate(ch1=if_else(est_cost_entry %in% c(12, 13), est_cost, 0)/s1213 * v[["01"]]) %>%
  mutate(ch8=if_else(est_cost_entry %in% c(12, 13), est_cost, 0)/s1213 * v[["08"]]) %>%
  mutate(ch9=if_else(est_cost_entry %in% c(12, 13), est_cost, 0)/s1213 * v[["09"]]) %>%
  mutate(ch10=if_else(est_cost_entry %in% c(12, 13, 14, 15), est_cost, 0)/s1215 * v[["10"]]) %>%
  mutate(ch12=if_else(est_cost_entry %in% c(12, 13, 14, 15), est_cost, 0)/s1215 * v[["12"]]) %>%
  mutate(overcost=round(ch1+ch8+ch9+ch10+ch12, 2)) %>%
  select(-ch1, -ch8, -ch9,-ch10, -ch12) %>%
  ungroup()

# ���������
# final_df %>% summarise_at(c("ch1", "ch8", "ch9", "ch10", "ch12"), sum)
# final_df %>% summarise_at(vars(ch1, ch8, ch9, ch10, ch12), sum)

write_csv(final_df, "task2.txt")

# ��������� ����� 2, "������ ������� ��������� � ������� �������� ���"
df <- final_df %>%
  group_by(oks_code, ossr_code) %>%
  mutate(direct_cost=sum(est_cost), indirect_cost=sum(overcost))

# 
oks_dict <- tibble(oks_code=c("0001", "0002"), oks_name=c("���.2�", "����.2�"))

df <- final_df %>%
  group_by(oks_code) %>%
  summarise(direct_cost=sum(est_cost), indirect_cost=sum(overcost)) %>%
  left_join(oks_dict)

# �������� ������ � ��������� �� ������� ����
df0 <- final_df %>%
  filter(oks_code=="0002") %>%
  group_by(ossr_code) %>%
  summarise(direct_cost=sum(est_cost), indirect_cost=sum(overcost)) %>%
  mutate(total_cost=direct_cost+indirect_cost) %>%
  # ������� ���� ������
  gather(indirect_cost, direct_cost, key=type, value=cost) %>%
  mutate(label=format(cost, big.mark=" "))
  
# brewer.pal(n=9, name="Greens")[4]
gp <- ggplot(df0, aes(fct_reorder(as.factor(ossr_code), total_cost, .desc=FALSE), cost)) +
  scale_fill_brewer(palette="Dark2") +
  geom_bar(aes(fill=type), alpha=0.5, stat="identity", position="stack") +
  # geom_text(aes(label=label), hjust=+1.1, colour="blue") + # ��� ������������
  # geom_label(aes(label=label), fill="white", colour="black", fontface="bold", hjust=+1.1) +
  geom_label(aes(label=label), position = position_stack(vjust = 0.5), 
             fill="white", colour="black", fontface="bold", hjust=.5) +
  # geom_text_repel(aes(label=label), fontface = 'bold', color = 'blue', nudge_y=0) +
  # scale_x_discrete("��������", breaks=df2$order, labels=df2$channelName) +
  theme_ipsum_rc(base_size=20,
                 subtitle_size=14,
                 axis_title_size=18) +
  theme_solarized(light=FALSE) +
  # theme(axis.text.x = element_text(angle=90)) +
  ylab("�������, ���") +
  xlab("����� ����") +
  ggtitle("��������� ������", subtitle="� ������� ������� ����")
  # coord_flip() 

gp

stop()
# ������������� ������ ���������� ������
# 1. ��������� ������, ������� �������� NA
# m1 <- clean_df %>% filter_all(any_vars(is.na(.)))
# m2 <- clean_df %>% filter_at(vars(est_cost, cost_element), any_vars(is.na(.)))
total_direct_cost <- clean_df %>% 
  filter(!indirect_cost) %>% 
  summarise(s=sum(est_cost)) %>% 
  pull(s)

total_indirect_cost <- sum(indirect_df$chap_indirect_�ost)
# !!! ����� �� ������
print(sprintf("%.2f (������) + %.2f (���������) = %.2f. ������ ����� �� ������� = %.2f", 
              total_direct_cost, total_indirect_cost, (total_direct_cost + total_indirect_cost),
              sum(clean_df$est_cost))) 

# ������, ��� ������ �� ���, ������ � ��������� �������� �������� ������ �����
ss <- clean_df %>% 
  filter(indirect_cost) %>%
  filter(!(ssr_chap %in% c("01", "08", "09", "10", "12"))) %>%
  arrange(ssr_chap)
  

# ����������� ��������� ������� �� ������ 2-7 --------
# ��� ����� ��������� ����������� ��������� ������ � �� ���� �������� ��� ��������
raise_coeff <- 1+sum(indirect_df$chap_indirect_�ost)/total_direct_cost

final_df <- clean_df %>%
  mutate(should_raise=ssr_chap %in% c("02","03","04","05","06","07")) %>%
  mutate(raised_cost=est_cost*should_raise*raise_coeff)

object_size(final_df)

# ����� �� ��������� "�����"
clean_df %>% 
  filter(est_cost_entry %in% c("����� 16")) %>%
  summarise(raw=sum(est_cost))

# ����� �� ��������������
final_df %>% 
  summarise(raw=sum(raised_cost))


# �������� ��������� �������

stop()
# ��������� �� ������ -----------------
tic("Analysis")
# ��������� ���������� ���������� �������� � ��������
dist_cols <- map_df(select(df1, everything()), n_distinct)
# ��������� � ����������� ��������� ���������� ��������
unq <- map(df1, unique) %>% map(sort, decreasing=T)
toc()


dist_cols
unq
distinct(df1) # ��������� �� ��������� ����������



stop()


# ��������� �� ������
m <- raw_df[2, ] %>% flatten_chr()

names <- stri_join(raw_df[2, ] %>% replace_na(replace=list()), " : ", raw_df[3, ], ignore_null=TRUE)

# , locale=locale("ru", encoding="windows-1251"), col_types="ccccccccc")
# ��������� ������ ��������������, �� ������������� ������� ��� � ������ ��� ����������� ������ ���������
print(problems(raw_df), n=Inf)

# ��������������


stop()

write_csv(df1, "clean_xdr.csv")

df <- df1

