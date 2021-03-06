rm(list=ls()) # ������� ��� ����������
library(tidyverse)
library(magrittr)
library(forcats)
library(lubridate)
library(stringi)
library(Cairo)
library(RColorBrewer)
library(futile.logger)
library(anytime)
library(tictoc)
library(digest)
library(rJava)
library(ReporteRs)
library(officer)
library(extrafont)
library(hrbrthemes)


#eval(parse("funcs.R", encoding="UTF-8"))
source("funcs.R")

# ������� ��� warnings():
assign("last.warning", NULL, envir = baseenv())

system.time(raw_df <- as_tibble(readRDS("./data/tvstream4.rds")))
raw_df %<>% mutate(title=readr::parse_factor(programId, levels=NULL))
raw_df %<>% mutate(serial_num=as.numeric(serial))

# ====================================================================
# �������������� ������������� ��� ������� ������� + ��������� ����������� �����  -------------
if (FALSE){
  system.time(raw_df <- readRDS("./data/tvstream3.rds"))
  
  # �������� ����������� ����������
  anytime(as.numeric(now()+days(1))*1.0005)

  # ������� ����� ������� ��������
  df <- raw_df %>%
    select(-data_date) %>% # data_date ������ ����� ����� NA
    filter(complete.cases(.)) %>% # �������� ������ � NA
    sample_frac(0.2) %>% # � ����� ��������� ������� ������ �����
    # mutate(t=as.POSIXct(date, origin='1970-01-01'))
    # mutate(t=anytime(date/1000, tz="Europe/Moscow"))
    # ������, ��� timestamp = date, ������ ������ ������. ������� �������, ����� ������ �� ��������
    mutate(timestamp = anytime(date / 1000, tz = "UTC")) %>%
    # ��� ������������� ����������� ������� ������ �� 10 ���� �����
    mutate(timestamp = anytime(as.numeric(now()-seconds(as.integer(runif(n(), 0, 10*24*60*60)))))) %>%
    mutate(timegroup = hgroup.enum(timestamp, min_bin = 60)) %>%
    select(-date) %>%
    mutate(segment=sample(c("IPTV", "DVB-C", "DVB-S"), n(), replace=TRUE))

  print(paste0("������ �������: ", round(as.numeric(object.size(df) / 1024 / 1024), digits = 1), "��"))
  
  system.time(saveRDS(df, "./data/tvstream4.rds", ascii = FALSE, compress = "gzip"))
  
  raw_df <- df
}

# �������� ������ �� ������ ---------------------
if (FALSE) {
  tic()
  # ��������� ���������� ���������� �������� � ��������
  dist_cols <- map_df(select(raw_df,-timestamp), n_distinct)
  # ��������� � ����������� ��������� ���������� ��������
  unq <- map(raw_df, unique) %>% map(sort, decreasing = T)
  # unq
  dist_cols
  toc()
}


# ====================================================================
# ��������� word ����� ��� �������� � ������� ������ ReporteRs
if(FALSE){
  doc <- docx(title='������� �������', template="./TV_report_template.docx" )
  s <- as_tibble(styles(doc)) %>% rownames_to_column()
  # browser()
  
  # doc <- addSection(doc, landscape=TRUE)
  doc <- addTitle(doc, '������ 80 ����� ������', level = 1)
  out_df <- raw_df[1:80, ] %>% select(timestamp, region, programId, segment)
  doc <- addFlexTable(doc, vanilla.table(out_df))
  
  # ������� �������� �������� ������� c ������� �������� �������
  reg_df <- raw_df %>%
    group_by(region) %>%
    summarise(duration=sum(duration), n=n()) %>%
    top_n(9, duration) %>%
    arrange(desc(duration))
  
  gp <- ggplot(reg_df, aes(fct_reorder(as.factor(region), duration, .desc=FALSE), duration)) +
    geom_bar(fill=brewer.pal(n=9, name="Greens")[4], alpha=0.5, stat="identity") +
    #geom_text(aes(label=order), hjust=+0.5, colour="red") + # ��� ������������
    # scale_x_discrete("��������", breaks=df2$order, labels=df2$channelId) +
    scale_y_log10() +
    theme_ipsum_rc(base_size=14, axis_title_size=12) +  
    theme(axis.text.x = element_text(angle=90)) +
    ylab("��������� ���������� �����") +
    xlab("������") +
    ggtitle("���������� �������������", subtitle="��� 9 ��������") +
    coord_flip()  

  # browser()
  
  doc <- addParagraph(doc, value="��������� ��������")# , stylename = "Normal")
  doc <- addPlot(doc, function(){print(gp)}, width=6)
  
  
  writeDoc(doc, file="word_report.docx")
}

# ====================================================================
# ��������� word ����� ��� �������� � ������� ������ officer
if(TRUE){
  # ������� ������ ��� ������� -----------------------------------
  # ������� �������� �������� ������� c ������� �������� �������
  reg_df <- raw_df %>%
    group_by(region) %>%
    summarise(duration=sum(duration), n=n()) %>%
    top_n(9, duration) %>%
    arrange(desc(duration))
  
  gp <- ggplot(reg_df, aes(fct_reorder(as.factor(region), duration, .desc=FALSE), duration)) +
    geom_bar(fill=brewer.pal(n=9, name="Greens")[4], alpha=0.5, stat="identity") +
    #geom_text(aes(label=order), hjust=+0.5, colour="red") + # ��� ������������
    # scale_x_discrete("��������", breaks=df2$order, labels=df2$channelId) +
    scale_y_log10() +
    theme_ipsum_rc(base_size=14, axis_title_size=12) +  
    theme(axis.text.x = element_text(angle=90)) +
    ylab("��������� ���������� �����") +
    xlab("������") +
    ggtitle("���������� �������������", subtitle="��� 9 ��������") +
    coord_flip()  

  out_df <- raw_df[1:80, ] %>% select(timestamp, region, programId, segment)
  
  # ������� ���� ------------------------------------------
  doc <- read_docx() %>% # read_docx(path="./TV_report_template.docx") %>%
    body_add_par(value='������ 80 ����� ������', style="heading 1") %>%
    body_add_table(value=out_df, style="table_template") %>% 
    body_add_par(value="��������� ��������", style="heading 1") %>%
    body_add_gg(value=gp, style = "centered") %>%
    print(target = "word_report_officer.docx")
}


# ====================================================================
# ����� �1: "������� �������" --------------------
if (FALSE) {
  tic()
  df0 <- raw_df %>%
    mutate(name_hash = map_chr(programId, digest::digest, algo = "xxhash64"))
  # ��� 250 ���. ����� �� �������� ��� ��������� ~25 ���
  toc()
  
  print(paste0("������ �������: ", round(as.numeric(object.size(df0) / 1024 / 1024), digits = 1), "��"))
  
  # ��������� ���������� ���������� �������� � ��������
  dist_cols <- map_df(select(df0, name_hash, programId), n_distinct)
}

# ��������� ���������� ���������� �������� � ��������
dist_cols <- map_df(select(raw_df, programId, serial, serial_num), n_distinct)

# ====================================================================
# ������������� ������������ �� ��������� ���������� ---------------------
if (FALSE){
gc()
tic("unique string") # ~1.9 ���
microbenchmark::microbenchmark(
df0 <- raw_df %>%
  group_by(programId) %>%
  summarise(unique_box=n_distinct(serial)) %>%
  arrange(desc(unique_box)), times=10)
toc()
  
# � ������ ����� �������
gc()
tic("unique factors") # ~1.9 ���
microbenchmark::microbenchmark(
  df0 <- raw_df %>%
  group_by(title) %>%
  summarise(unique_box=n_distinct(serial)) %>%
  arrange(desc(unique_box)), times=10)
toc()

# � ������ � ������� ������ �����
gc()
tic("unique factors + serial_num") # ~0.1 ���
microbenchmark::microbenchmark(
  df0 <- raw_df %>%
    group_by(title) %>%
    summarise(unique_box=n_distinct(serial_num)) %>%
    arrange(desc(unique_box)), times=10)
toc()
}

# � ������ � ������� ������ �����
gc()
tic("unique factors + serial_num") # ~0.1 ���
df0 <- raw_df %>%
  group_by(title) %>%
  summarise(unique_box=n_distinct(serial_num), 
            total_time=sum(duration),
            watch_events=n()) %>%
  arrange(desc(unique_box))
toc()


stop()



# ��������� ���-5 ������� ��� ���-9 �������� =============

# top_n ����������� ��� ������ ������, ������� �������  ���������� ���������� ��� N �� ��������
# ������� �������� �������� ������� c ������� �������� �������
reg_df <- df %>%
  group_by(region) %>%
  summarise(duration=sum(duration), n=n()) %>%
  top_n(9, duration) %>%
  arrange(desc(duration))

# � ������ ������� �� ��������� ��������� ������ ������, ���������� ���� ��� N ��������
df1 <- df %>%
  semi_join(reg_df, by="region") %>%
  group_by(region, channelId) %>%
  summarise(duration=sum(duration)) %>%
  ungroup() %>%
  # ����������� ������� ���� ����� �� ������������ ��������� ������������
  group_by(region) %>%
  mutate(total_duration=sum(duration)) %>%
  # top_n(5, duration) %>% # ��� ������ �� ��������
  ungroup() %>%
  arrange(desc(total_duration), desc(duration)) %>%
  # 3. Add order column of row numbers
  mutate(order=row_number())

windowsFonts(robotoC="Roboto Condensed")

# To change the order in which the panels appear, change the levels
# of the underlying factor.

# ������������ ����������� ��� ����������� ����������� ������ facet
# https://drsimonj.svbtle.com/ordering-categories-within-ggplot2-facets
df2 <- df1 %>% 
  group_by(region) %>% 
  top_n(5, duration) %>%
  ungroup() %>%
  arrange(desc(total_duration), desc(duration)) %>%
  # mutate_at(vars(channelId, region), as.factor) %>%
  mutate(order=row_number())
  
# ������� ��� warnings():
assign("last.warning", NULL, envir = baseenv())

# ����������� ���-5 �������� �� ��������� �������� ====================================
# 45 ����� � 34 ������� �� ���������!
# gp <- ggplot(df2, aes(fct_reorder(channelId, duration, .desc=TRUE), duration)) +
# gp <- ggplot(df2, aes(order, duration)) +
gp <- ggplot(df2, aes(fct_reorder(as.factor(order), order, .desc = TRUE), duration)) +
# gp <- ggplot(df2, aes(x=fct_reorder(channelId, order, .desc = TRUE), y=duration)) +  
  geom_bar(fill=brewer.pal(n=9, name="Blues")[4], alpha=0.5, stat="identity") +
  # geom_text(aes(label=order), vjust=-0.5, colour="red") + # ��� ������������
  geom_text(aes(label=order), hjust=+0.5, colour="red") + # ��� ������������
  scale_x_discrete("��������", breaks=df2$order, labels=df2$channelId) +
  #scale_x_discrete("��������", labels=df2$channelId)
  #scale_x_manual("��������", values=df2$channelId)
  # scale_x_discrete(labels=channelId)) +
  #facet_wrap(~fct_reorder(CP, n, .desc=TRUE), scales = "free_y") +
  #facet_wrap(~CP_order, scales = "free_y") +
  facet_wrap(~fct_reorder(region, total_duration, .desc = TRUE), scales = "free") +
  theme_ipsum_rc(base_size=14, axis_title_size=12) +  
  theme(axis.text.x = element_text(angle=90)) +
  ylab("��������� ���������� �����") +
  ggtitle("���������� �������������", subtitle="��� 5 ������� ��� ��� 9 ��������") +
  coord_flip()


gp


