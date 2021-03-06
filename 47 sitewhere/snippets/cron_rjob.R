rm(list=ls()) # ������� ��� ����������

library(deployrUtils)
deployrPackage("ggplot2") #load first! (Wickham)
deployrPackage("lubridate") #load second!
deployrPackage("dplyr")
deployrPackage("tidyr")
deployrPackage("readr")
deployrPackage("reshape2")
deployrPackage("curl")
deployrPackage("httr")
deployrPackage("jsonlite")
deployrPackage("magrittr")
deployrPackage("arules")
deployrPackage("futile.logger")

# if (getwd() == "/home/iot-rus") {
#   # ������� �� �������
#   logfilename <- "/home/iot-rus/Rjobs/log/iot.log"
#   weatherfilename <- "/home/iot-rus/Rjobs/output/real_weather.json"
#   sensorfilename <- "/home/iot-rus/Rjobs/output/real_sensor.json"
# } else {
#   logfilename <- "./log/iot.log"
#   weatherfilename <- "./export/real_weather.json"
#   sensorfilename <- "./export/real_sensor.json"
# }

# ������ ������� �� ������� ����������, ��� ����������� cron
# ������� �������� ����������, ���� ��� �� ����������
if (!dir.exists('./log')) dir.create('./log')
if (!dir.exists('./output')) dir.create('./output')

# ���� ����� ������������� �� DeployR, �� �� ����� �������� ������ �������� ����� API

log_filename <- "./log/iot.log"
weather_filename <- "./output/real_weather.json"
sensorts_filename <- "./output/real_sensor_ts.json"
sensorslice_filename <- "./output/real_sensor_slice.json"
rain_filename <- "./output/rain.json"

# ������������� ----------------------------------------------
flog.appender(appender.file(log_filename))
flog.threshold(TRACE)
flog.info("Job started")
flog.info("Working directory: %s", getwd())
flog.info("Processing started")

source("../46 PoC_dashboard/common_funcs.R") # ���� ������� ��� �������������� � ������������� �������

# ��������� ��� ����������� � SiteWhere
user_name = 'admin'
user_pass = 'password'
base_url = paste0('http://', user_name, ':', user_pass, '@10.0.0.207:28081/sitewhere/api/')
t_token = 'sitewhere1234567890'


if(TRUE){

# ������ � ������������ ������ �� ������� (������� � �������) =====================================
raw_weather.df <- prepare_raw_weather_data()

# d <- dmy_hm("23-12-2015 4:19")
# str(date(dmy_hm("23-12-2015 4:19")))
dfw2 <- calc_rain_per_date(raw_weather.df)

flog.info("Rain history & forecast")
flog.info(capture.output(print(dfw2)))

# ����������� json � ������� ��� ���������� ���� ---------------------------------------------------
# http://arxiv.org/pdf/1403.2805v1.pdf  |   http://arxiv.org/abs/1403.2805
x <- jsonlite::toJSON(list(results = dfw2), pretty = TRUE)
write(x, file = rain_filename)

# ������ � ������������ ������ �� ������ ==========================================================
df <- get_weather_df(raw_weather.df, back_days = 7, forward_days = 3)

# http://stackoverflow.com/questions/25550711/convert-data-frame-to-json
df3 <- with(df, {
  data.frame(timestamp = round(as.numeric(timegroup), 0), 
             timestamp.human = timegroup,
             rain3h_av = rain3h_av,
             air_temp_past = ifelse(time.pos == "PAST", round(temp, 0), NA),
             air_temp_future = ifelse(time.pos == "FUTURE", round(temp, 0), NA),
             air_humidity_past = ifelse(time.pos == "PAST", round(humidity, 0), NA),
             air_humidity_future = ifelse(time.pos == "FUTURE", round(humidity, 0), NA)) %>%
    arrange(timestamp)
})
flog.info("Weather data")
flog.info(capture.output(summary(df3)))

# ����������� json � ������� ��� ���������� ���� ---------------------------------------------------
# http://arxiv.org/pdf/1403.2805v1.pdf  |   http://arxiv.org/abs/1403.2805
x <- jsonlite::toJSON(list(results = df3), pretty = TRUE)
write(x, file = weather_filename)

}
# ������ � ������������ ������ �� ������ �������� ==============================================
# raw.df <- load_github_field_data()
# if (!is.na(df)) { raw.df <- df}
#     name      lat      lon value work.status           timestamp   location
#    (chr)    (dbl)    (dbl) (dbl)       (lgl)              (time)      (chr)

raw.df <- get_github_field2_data()


# ������������ ���������� ���� �� �������� ---------------------------------------------------
# �������� ���������� �� ��������� �������, ���� ��������� ����������� ��������� ��� � ������� ����� �������
# ��������� ������ �� ������� ��������

# ��������� 7 ���� �����, 3 ������, ���������  �����������
# ����������� �� ��������� ����������
avg.df <- raw.df %>%
  filter(type == 'MOISTURE') %>% # ��������� ������ ���������
  mutate(timegroup = hgroup.enum(timestamp, time.bin = 1)) %>%
  filter(timegroup >= floor_date(now() - days(7), unit = "day")) %>%
  filter(timegroup <= ceiling_date(now() + days(3), unit = "day")) %>%  
  filter(work.status) %>%
  # ��������� ����������� � ��������
  mutate(value = value/3300) %>%
  group_by(location, timegroup) %>%
  summarise(value.min = round(min(value), 3), 
            value.mean = round(mean(value), 3), 
            value.max = round(max(value), 3)) %>%
  mutate(timestamp.human = timegroup) %>%
  mutate(timestamp = round(as.numeric(timegroup), 0)) %>%
  ungroup() # �������� �����������
  
  # ������� ���. ����� �� ������� ����
avg.df %<>% select(-location, -timestamp.human)

flog.info("Time-series data: file")
flog.info(capture.output(head(avg.df, n = 4)))

# ���������� ���������
moist_levs <- get_moisture_levels()
# ����� �������� �� ��������, � ������ �� � ������, � � data.frame
# / 3000 -- ���������� �� �����������
levs <- data.frame(low = head(moist_levs$category/3300, -1), up = tail(moist_levs$category/3300 , -1), 
                   name = moist_levs$labels)

jdata <- jsonlite::toJSON(list(soil_moisture = list(levels = levs, ts = avg.df)), pretty = TRUE)
write(jdata, file = sensorts_filename)

# � ������ ������� �� sitewhere
url <- paste0(base_url, "mt/assets/categories/fs-locations/assets/harry-dirt-pot/property/dashboard?tenantAuthToken=", 
              t_token)
resp <- PUT(url, body = jdata, encode = "json")
flog.info(paste0("Time-series data: SiteWhere PUT response code = ", resp$status_code))


# ������������ ���������� ����� � ������������ �� �������� ---------------------------------------------------
sensors.df <- prepare_sensors_mapdf(raw.df, slicetime = lubridate::now()) %>%
  mutate(timegroup = hgroup.enum(timestamp, time.bin = 1)) %>%
  mutate(timestamp.human = timestamp) %>%
  mutate(timestamp = round(as.numeric(timegroup), 0))

flog.info("Time-slice data")
flog.info(capture.output(head(sensors.df, n = 4)))

x <- jsonlite::toJSON(list(results = sensors.df), pretty = TRUE)
write(x, file = sensorslice_filename)

flog.info("Job finished")
