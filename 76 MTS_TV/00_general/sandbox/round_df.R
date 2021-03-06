library(tidyverse)
# ������� ��� warnings():
assign("last.warning", NULL, envir = baseenv())


# ��������� �������, ������� �������� ���������, �� �� ������ � ������
df <- tribble(
  ~text, ~val, ~dic_val, ~tdata,
  "������ 1", 1.7, 1.5, "f",
  "������ 2", 2.7, 2.5, "g"
  )

# ��������� ��� ���������� � ��������
myFun <- function(x)
{
  dput(x)
  print(is.numeric(x))
  TRUE
}

df0 <- df %>%
  mutate_if(myFun, as.character)

# ��������� ��������� �������-��������������
vlist <- c("val", "tdata")

myFun2 <- function(x, val)
{
  # ���� ������� ������ ������� � �������, ���������� ���������
  dput(x)
  print(is.numeric(x))
  if(is.numeric(x)) as.character(x) else "3"
}

df1 <- df %>%
  mutate_at(vars(vlist), myFun2, val="���. ��������")

# ������ ����������
df2 <- df %>%
  mutate_at(vars(vlist), ~{if(is.numeric(.x)) as.character(.x) else "3"})

identical(df1, df2)




