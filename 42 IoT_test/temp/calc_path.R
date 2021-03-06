source("disk_funcs.R")
  

dfs <- readRDS("sensors_calulated.rds")
df.best <- optimize_path(dfs) %>% mutate(j = j.path)
disk_plot(df.best)

# ��������� ���������� ����� ���������
path <- df.best$j

# ���, ������-��, �� ����� ���������, ��������� ���� ������ ��������� ������� � ������� ������� 
# � ����� ����������� ���������� �� ������


## df.points <- data.frame(l = head(path, -1), r = tail(path, -1)) %>%
##   mutate(s = sqrt((df.best$x[l] - df.best$x[r])^2 + (df.best$y[l] - df.best$y[r])^2))
## sum(df.points$s)


r.min <- sapply(df.best$j, function(j.sensor){
  df.points <- df.best %>%
    mutate(x0 = x[j.sensor], y0 = y[j.sensor]) %>%
    mutate(r = sqrt((x - x0) ^ 2  + (y - y0) ^ 2)) %>%
    filter(j != j.sensor) # ����� �������� �������� ����������
 min(df.points$r)
})



stop()

seqsensor <- df.calc$j %>% .[. != n1]

# ����������� ������ ������������ ������������������� ������ ��������, ������������ � n1
routes <- lapply(1:5000, function(x){ c(n1, sample(seqsensor, length(seqsensor), replace = FALSE)) })
