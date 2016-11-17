getOksData <- function(filename, sheetname = "") {
  # ��� �� ���������� ����� �������
  col_types <- readxl:::xlsx_col_types(filename)
  
  #col_types <- rep("text", length(col_types))
  raw <- read_excel(filename,
                    col_types=col_types,
                    col_names=FALSE, 
                    skip = 1) # � ������ ������ ������ �������� "�������� �����"
  
  # ����� ��������, ������� � NA ������ �����
  # ����� ������ � ���� ��������������, �� ���������� ������ �� ����
  # �������������� �������
  df0 <- raw %>%
    repair_names(prefix = "repaired_", sep = "")
  
  # ������ ������� ���������� �������� �������
  # �������� ������� ��������� �� ������� 1-3. 
  # 1-�� -- ������������, 2-� -- ��������������, 3-� -- ������� ��������� (� ������ ������� ��� ����� �������)
  # ���� �� ����� � ������������� �������, ������ ��������� ����� ������ 3, ��� ����������
  names_df <- tibble(name_c1=tidyr::gather(df0[1, ], key=name, value=v)$v,
                     name_c2=tidyr::gather(df0[2, ], key=name, value=v)$v,
                     name_c3=tidyr::gather(df0[3, ], key=name, value=v)$v) %>%
    # http://www.markhneedham.com/blog/2015/06/28/r-dplyr-update-rows-with-earlierprevious-rows-values/
    mutate(name_c1_ext=na.locf(name_c1, na.rm=FALSE)) %>% # � ������ ������� ��������� ����� ���� � 3-�� ������
    mutate(name_c2_ext=na.locf(name_c2, na.rm=FALSE))
  
  cnames <- names_df %>% 
    mutate(name.fix=str_c(str_replace_na(name_c1_ext, ""), # �������� NA �� "", �� ���� �� str_c
                          str_replace_na(name_c2_ext, ""), 
                          str_replace_na(name_c3, ""), sep = ":: ")) %>%
    mutate(name.fix=str_replace_all(name.fix, "\\r|\\n", " ")) %>% # ������� ������
    mutate(name.fix=str_replace_all(name.fix, "\\s+", " ")) %>% # ����� ��������
    mutate(name.fix=str_replace_all(name.fix, "^(:: )+|(:: )+$", "")) # NA ����� � ������ ��� �����
  
  # dput(cnames$name.fix)
  # write(cnames$name.fix, "name_fix.txt", append=FALSE)
  
  # �������� ������ �����, �����
  cnames %>% 
    group_by(name.fix) %>% 
    filter(n()>1)
  
  # ��������� ���������� ����� �� �������� � ����������� �������
  df1 <- df0
  repl.df <- frame_data(
    ~pattern, ~replacement,
    "����������� �������(���)", "oip_full",
    "���� ����� ��", "date",
    "��������� ������� �� �� � ������� �����:: ����� ���������:: * 1 RUB", "pd_cost",
    "��������� ������� �� �� � ������� �����:: ��������� ������, � �.�. ���������:: * 1 RUB", "smp_cost",
    "��������� ������� �� �� � ������� �����:: ������������:: * 1 RUB", "plant_cost"
  )
  
  names(df1) <- stri_replace_all_fixed(cnames$name.fix,
                                       pattern = repl.df$pattern,
                                       replacement = repl.df$replacement,
                                       vectorize_all = FALSE)
  df1 %<>% repair_names(prefix = "repaired_", sep = "")
  
  # �������� ������ ������������ �������
  df2 <- df1 %>% select(oip_full, date, pd_cost, smp_cost, plant_cost) %>%
    #filter(row_number() > 6) %>% # ������� ���� ������� ����
    # filter(complete.cases(.)) %>% # ������� ������, ���������� ������ ������
    # �������� ������ ��������� �������, ��������� �������� ��� ��������� � ��.
    # http://stackoverflow.com/questions/22850026/filtering-row-which-contains-a-certain-string-using-dplyr
    filter(str_detect(oip_full, '\\d{3}-\\d{7}\\.\\d{4}')) %>% # 022-2000791.0250
    separate(oip_full, into=c("oip", "sub_oip"), sep="[.]", remove=FALSE) %>%
    mutate(year=year(dmy(date, quiet=TRUE))) %>% # ������ ���� ������������ � NA, �� � �������
    replace_na(list(pd_cost='0', smp_cost='0', plant_cost='0', year=2015)) %>%
    #http://stackoverflow.com/questions/27027347/mutate-each-summarise-each-in-dplyr-how-do-i-select-certain-columns-and-give
    mutate_each(funs(as.numeric), pd_cost, smp_cost, plant_cost) %>%
    distinct() # ������ ���������� �������
  
  df2
}