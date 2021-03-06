# ����������� � ���������� ������ � sitewhere
#library(tidyr)
library(ggplot2) #load first! (Wickham)
library(lubridate) #load second!
library(dplyr)
library(tidyr)
library(readr)
library(jsonlite)
library(magrittr)
library(curl)
library(httr)
library(ggthemes)
library(ggdendro) # ��� ������ ����
#library(ggmap)
library(RColorBrewer) # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
library(scales)
library(gtable)
library(grid) # ��� grid.newpage()
library(gridExtra) # ��� grid.arrange()
library(arules)
library(iterators)
library(foreach)
library(futile.logger)

source("../46 PoC_dashboard/common_funcs.R") # ���� ������� ��� �������������� � ������������� �������

# ��������� ��� ������� � SiteWhere ------------------------------------------------------------------------
# �������� ���� ������
user_name = 'admin'
user_pass = 'password'
base_url = paste0('http://', user_name, ':', user_pass, '@10.0.0.207:28081/sitewhere/api/')
t_token = 'sitewhere1234567890'


get_tsdf_from_SW_json <- function(data, c_vars) {
  # ������� ������� ��������� �����, ���������� �� ��������� �� SiteWhere
  # ������� ������ (data) ������ ��������� � ��������� ������� (value - measurementDate �� ������ ������)
  # ����� �������\���������� ��� ������� ����������� � ���� ���������� ������� � ���������� c_vars
  # ��������, ���: c('humidity', 'temp', 'pressure')
  # 'data.frame':	3 obs. of  2 variables:
  # $ measurementId: chr  "min" "max" "soil_moisture"
  # $ entries      :List of 3
  # ..$ :'data.frame':	100 obs. of  2 variables:
  #   .. ..$ value          : num  2670304 2670304 2670304 2670304 2670304 ...
  #   .. ..$ measurementDate: chr  "2016-06-06T22:00:06.000+0300" "2016-06-06T22:30:06.000+0300" ...
  # ..$ :'data.frame':	100 obs. of  2 variables:
  #   .. ..$ value          : num  1053200 1053200 1053200 1053200 1053200 ...
  #   .. ..$ measurementDate: chr  "2016-06-06T22:00:06.000+0300" "2016-06-06T22:30:06.000+0300" ...
  # ..$ :'data.frame':	100 obs. of  2 variables:
  #   .. ..$ value          : num  2472880 2476032 2474992 2472880 2472880 ...
  #   .. ..$ measurementDate: chr  "2016-06-06T22:00:06.000+0300" "2016-06-06T22:30:06.000+0300" ...
  
  df0 <- spread(data, measurementId, entries)  # ��������� ������ �� ��������
  
  # ������� ������� � ����������� ----------------------------------------------------------
  # � ������ �������, ��� � ������ ��������� ������ ������ ����� ���� ������ �����: 
  # �� ���� �������� ������� ���� ����������� ������������ � ���������� ����� ����������
  # �������� ������ ����� � � ���� ������������ ��� �� ����� ������ �� ������������ �����������
  data.list <- lapply(c_vars,
                      function(x) {
                        d <- distinct(data.frame(
                          # ����� ����������� � POSIXct, ����� �� �������� ����� � �������� �������
                          # 2016-05-29T09:28:50.000+0300 --- local time-zone (+3), ��. https://www.w3.org/TR/NOTE-datetime
                          timestamp = with_tz(ymd_hms(df0[[x]][[1]]$measurementDate), tz = "Europe/Moscow"), 
                          value = df0[[x]][[1]]$value,
                          stringsAsFactors = FALSE
                        )) # ����� ������ ������������� ������
                        names(d)[2] <- x
                        d
                      })
  
  # , tz = "Europe/Moscow"
  # � ������ ��������� ��� ������
  # � ��� ��� ������� ��������, ��� ��������� ����� ����� ��������� � ��������� �� ���������� ��� ��������� ������!
  # ��������, ���� �� ������ �������� �����
  
  # ������� ������ ������
  # ��� ����������� POSIXct ������������ � numeric, ��� � ����� ���. ������� � ���������� ������� ���� ������
  df.time <- data.frame(timestamp = unique(unlist(lapply(data.list, 
                                                         function(x){getElement(x, "timestamp")}))), 
                        stringsAsFactors = FALSE) %>%
    mutate(timestamp = as.POSIXct(timestamp, origin='1970-01-01', tz = "Europe/Moscow"))
  
  df.join <- df.time
  for(i in 1:length(data.list))
  {
    df.join %<>% dplyr::left_join(data.list[[i]], by = "timestamp") #, copy = TRUE)
  }
  
  df.join
}

load_SW_field_data <- function(siteToken, moduleId, assetId) {
  # ------------------------------------------------------------------------
  
  # http://10.0.0.207:28081/sitewhere/api/mt/assets/modules/fs-locations/assets/harry-dirt-pot/assignments/?siteToken=c08a662e-9bbb-4193-a17f-96e0c760e1c3&tenantAuthToken=sitewhere1234567890
  # ���������� ������ ��� ��������� ��������� �� assignment
  
  # location ����� = 'fs-locations', asset ���� ����� = 'harry-dirt-pot'.
  # 1. ���������� ������ ������ (assignments) �� asset-�,
  # 2. �������� ��, ������� �������� ������� ���������
  # 3. ������� ��������� ��� ���������, ��������������� ����� �������
  # 4. ��������� ��������������� ������ ��������� (location, lon, lat)
  
  url <- paste0(base_url, "mt/assets/modules/", moduleId,
                "/assets/", assetId, 
                "/assignments/?siteToken=", siteToken, 
                "&tenantAuthToken=", t_token)
  resp <- curl_fetch_memory(url)
  write(rawToChar(resp$content), file="./temp/resp.txt")
  data <- fromJSON(rawToChar(resp$content))
  # ���� assignments � sensor_type = soil_moisture

  a <- data$results$assignment
  # error: 'names' attribute [9] must be the same length as the vector [1]
  # http://stackoverflow.com/questions/14153092/meaning-of-ddply-error-names-attribute-9-must-be-the-same-length-as-the-vec
  # ������ ��������� ������������� ������ �� �������������� �����
  b <- select(a, -state, -metadata) # ������ View(b) ��������
  
  # �������� ���������� �� ���� assignments
  d <- data$results$specification
  
  # d1 <- d %>% select(-metadata, -deviceElementSchema)
  # d2 <- d$metadata
  g <- bind_cols(d %>% select(-metadata, -deviceElementSchema), d$metadata)
  
  # ������� ������������ ������� �������
  tmp <- data$results
  m <- data.frame(assetId = tmp$assignment$assetId,
                  assignment.token = tmp$assignment$token,
                  deviceId = tmp$device$hardwareId, 
                  specification.token = tmp$device$specificationToken,
                  specification.name = tmp$specification$name,
                  stringsAsFactors = FALSE)
  
  tm1 <- tmp$specification$metadata
  names(tm1) <- paste0("specification.", names(tm1))
  tm2 <- tmp$device$metadata
  names(tm2) <- paste0("device.", names(tm2))
  g <- bind_cols(m, tm1) %>%  bind_cols(tm2)
  
  sensors.df <- g %>%
    filter(specification.sensor_type == 'soil_moisture')

  # � ������ ����������� ��� time-series �� ������������ assignment
  # http://10.0.0.207:28081/sitewhere/api/assignments/<token>/measurements/series?tenantAuthToken=sitewhere1234567890

  ## �������� ������ ��� ������������ � foreach �� ��������� ����� ����
  # s0 <- sensors.df; s0$assetId <- "new sensor"; s0$deviceId <- "mt-sn-soilmoisture-000002"
  # s.df <<- sensors.df %>% bind_rows(s0) # ������������ "��� ��" ��� ������


  # str(sensors.df)
  # !!!!!!!!!!!!!!!!!!!!!!! 
  # ������������� ����� ��� ����������� ������������
  # �� ������ ����������� ���, �������� ��������� �������, �� ������ ���������� data.frame � ������������ ���������� ������
  # ����������� �� �������� data.frame
  # http://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
  df.join <- foreach(it = iter(s.df, by='row'), .combine = rbind) %dopar% {
    # ������ �������� �� ������� �������
    # cat("----\n"); str(it);
    url <- paste0(base_url, "assignments/", it$assignment.token, "/measurements/series?tenantAuthToken=", t_token)
    resp <- curl_fetch_memory(url)
    ts.raw <- fromJSON(rawToChar(resp$content)) # ������ ������� �������� �� "resp2 <- GET(url)" �������
    # ������� ������� � ����������� ----------------------------------------------------------
    df <- get_tsdf_from_SW_json(ts.raw, c('soil_moisture', 'min', 'max'))
    # ��������� ��������������� �������� ���������
    df$name = it$deviceId
    
    df
  }

  # ��������� ��������������� ������ ��������� c ������ ������������� ������� (location, lon, lat) ------------------------

  # �������� ��������� ������ �� ��������� id. ������� ������ location
  url <- paste0(base_url, "assets/categories/", moduleId,
                "/assets/", assetId, 
                "/?siteToken=", siteToken, 
                "&tenantAuthToken=", t_token)
  
  # ����� curl ��������� �������� � ���������� �������, ����� ������������ �� ����� ��������-��������������� ������ httr
  # resp <- curl_fetch_memory(url)
  # data <- fromJSON(rawToChar(resp$content))
  resp <- GET(url)
  asset <- content(resp)

  df.join %<>%
    rename(value = soil_moisture) %>%
    mutate(measurement = value) %>%
    mutate(lon = asset$longitude) %>%
    mutate(lat = asset$latitude) %>%
    mutate(type = 'MOISTURE') %>%
    # ��� as.character ��������� ������ "unsupported type for column 'location' (NILSXP, classes = NULL)"
    mutate(location = as.character(asset$name)) %>% 
    select(-min, -max)
  
  df.join
}

get_SW_field_data <- function(siteToken, moduleId, assetId) {
  df0 <- load_SW_field_data(siteToken, moduleId, assetId) # �������� ������ � SiteWhere
  df1 <- postprocess_ts_field_data(df0) # �������� �������������� ������, ��������� ����������� ����
  df1
}

# main() --------------------------------------------------

# ��������� ��� ������� TimeSeries ------------------------------------------------------------------------
# �� ���� �������� siteToken, location, assetId
siteToken = 'c08a662e-9bbb-4193-a17f-96e0c760e1c3'
moduleId = 'fs-locations'
assetId = 'harry-dirt-pot'


github.df <- get_github_field2_data() # ��������� �������� ����, ��� ����� �������� 
sw.df <- get_SW_field_data(siteToken, moduleId, assetId)

join.df = inner_join(github.df %>% select(-name, -type, -lon, -lat, -pin, -location), 
                     sw.df %>% select(-name, -lon, -lat, -location), by = "timestamp")

# ������� ������������ data.frame ��� ���������� ������ �����������

# ��������� ������� ������ ������
mem.df <- data.frame(obj = ls(), stringsAsFactors = FALSE) %>% 
  mutate(size_in_kb = unlist(lapply(obj, function(x) {round(object.size(get(x)) / 1024, 1)}))) %>% 
  arrange(desc(size_in_kb))
print(paste0("Total size = ", round(sum(mem.df$size_in_kb)/1024, 1), "Mb"))

stop()



stop()

# �������� ������������ ������ � Sitewhere ==================================================================
# write(wh_json, file="./export/wh_json.txt")
getwd()
data <- fromJSON("./data/sitewhere_history.json")

df.join <- get_tsdf_from_SW_json(ts.raw, c('humidity', 'temp', 'pressure'))
df.res <- df.join %>%
  mutate(humidity = round(humidity, 0),
         # temp = round(temp - 273.15, 1), # ������������� �� ��������� � ������� �������
         pressure = round(pressure * 0.75006375541921, 0) # ������������� �� ������������� (hPa) � �� ��. ������
  )

object.size(df.res)


stop()

d <- toJSON(list(var1 = 34, var2 = c('rr', 'mm')), pretty = TRUE, auto_unbox = TRUE)

url <- paste0(base_url, "mt/assets/categories/fs-locations/assets/harry-dirt-pot/property/soil_moisture_ts?tenantAuthToken=", 
              t_token)
resp <- curl_fetch_memory(url)




stop()

resp <- curl_fetch_memory("http://admin:password@10.0.0.207:28081/sitewhere/api/assets/categories/fs-locations/assets?tenantAuthToken=sitewhere1234567890")
# wrecs <- rawToChar(resp$content)
data <- fromJSON(rawToChar(resp$content))


# ��� POST() ��. ���: https://cran.r-project.org/web/packages/httr/vignettes/quickstart.html


d <- toJSON(list(var1 = 34, var2 = c('rr', 'mm')), pretty = TRUE, auto_unbox = TRUE)
url <- "http://admin:password@10.0.0.207:28081/sitewhere/api/assets/categories/fs-locations/locations/harry-dirt-pot?tenantAuthToken=sitewhere1234567890"
body <- list(id = "harry-dirt-pot", properties = list(worksite.id = d))

r <- PUT(url, body = body, encode = "json")
stop()

url <- "api.openweathermap.org/data/2.5/"   
MoscowID <- '524901'
APPID <- '19deaa2837b6ae0e41e4a140329a1809'
resp <- GET(paste0(url, "weather?id=", MoscowID, "&APPID=", APPID))

stop()

# http://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
# ����������� �� �������� data.frame
s.df
d <- data.frame(x=1:10, y=rnorm(10))
# s <- foreach(m = iter(d, by='row'), .combine=rbind) %dopar% {str(m); cat("----"); m}


stop()

# ����������� �� �������� data.frame
# http://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
res <- foreach(it = iter(s.df, by='row'), .combine = rbind) %dopar% {
  # ������ �������� �� ������� �������
  cat("----\n"); str(it);
  url <- paste0(base_url, "assignments/", it$assignment.token, "/measurements/series?tenantAuthToken=", t_token)
  resp <- curl_fetch_memory(url)
  ts.raw <- fromJSON(rawToChar(resp$content)) # ������ ������� �������� �� "resp2 <- GET(url)" �������
  df.join <- get_tsdf_from_SW_json(ts.raw, c('soil_moisture', 'min', 'max'))
  df.join$name = it$deviceId
  
  df.join
  }


