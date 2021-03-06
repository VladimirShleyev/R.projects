hgroup.enum <- function(date, time.bin = 4){
  # ����������� ��� ���������, ������� ������ � ���������� [0, t] � ����� ���������. 
  # ����� ��������� ����� ���� ������ 1, 2, 3, 4, 6, 12 �����, ������������ time.bin
  # ������ ��������� ���� � 0:00
  
  # �������� ��� �����������. ��� ����������� ������ ���� ����������� ��������� ����� ������ 1
  # 0.5 -- ��� � �������.0.25 -- ��� � 15 �����
  
  tick_time <- date
  if (time.bin < 1 & !(time.bin %in% c(0.25, 0.5))) time.bin = 1
  n <- floor((hour(tick_time)*60 + minute(tick_time))/ (time.bin * 60))
  floor_date(tick_time, unit = "day") + minutes(n * time.bin *60)
}


date_format_tz <- function(format = "%Y-%m-%d", tz = "UTC") {
  function(x)
    format(x, format, tz = tz)
}