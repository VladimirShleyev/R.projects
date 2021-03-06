rm(list=ls()) # ������� ��� ����������
library(tibble)
library(rjson)
library(XML)
library(foreach)
library(debug)
library(doParallel)
library(futile.logger)

common_log_name <- "trace.log"

flog.appender(appender.file(common_log_name))
flog.threshold(TRACE)
flog.info("============= Classification started ===============")



Cluster_Id <- c("50494", "50494", "50494", "50494", "50494", "50494", "50494", "50494", "50494", "50863", "50863", 
"50863", "50863", "50863", "50863", "50863", "50863", "50863", "50863", "51073", "51073", "51073", 
"51073", "51073", "51073", "51073", "51073", "51073", "51300", "51300", "51300", "51300", "51300",
"51300", "51300", "51300", "51473")
Adr <-
  c(
    "�������� �������, �. ��������, ��. ������, �. 166",
    "�������� �������, �. ��������, ��. ������, �. 166",
    "�.��������, ��.������, �.166",
    "�.��������, ��.������, �.166, �������� ���.",
    "�.��������, ��.������, �.166 2",
    "�. ��������,��. ������, �.166",
    "�.��������, ��.������, �.166",
    "�.��������, ��.������, �.166, �������� ���.",
    "�.��������, ��.������, �.166 2",
    "�.�����, ��.��������, �.104",
    "�.����������, ��� � �������, �.29",
    "���������� �������, ���������� �����, �. ����������, ���. �������, ��� 29",
    "���������� �������, ���������� �����, �. ����������, ���. �������, ��� 29",
    "��, �.�����, ��.��������, �.104",
    "���������� �������, ���������� �����, ������� ����������, ��� � �������, �.29",
    "�.�����, ��.��������, �.104",
    "�.�����, ��.��������, �.104",
    "�.�����, ��.��������, �.104",
    "�.����������, ��� � �������, �.29",
    "�.������, ��.����������������, �.1",
    "�. ������, ���������������� �����, �. 1",
    "�. ������, ��. ����������������, �. 1",
    "�.������, ��. ����������������, �.1",
    "�.������, ��.����������������, �.1",
    "�. ������, ��. ����������������, �. 1",
    "�.������, ��.����������������, �.1",
    "�. ������, ���������������� �����, �. 1",
    "�.������, ��.����������������, �.1",
    "��, ����������� �����, �. ���������",
    "��, ����������� �����, �. ���������",
    "�.���������, �.�.�������",
    "�.���������, �.�.�������",
    "����������� � �, �.���������",
    "����������� � �, �.���������, �.�.�������",
    "����������� � �, �.���������",
    "���������� �������, ����������� � �, �.���������",
    "���������� � �, �.��������, �������"
  )
#### ��������########
# ���������� �������� � ����� - �� 25 000




geoYandex <- function(location, IsAddressFilter = TRUE){
  flog.info(paste0("==> function geoYandex, location = ", location))
  
  stopifnot(is.character(location))
  loc <- location
  if (IsAddressFilter == T) {
    IsAddress <- FALSE
    if (grepl(pattern = "\\b���[��]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\bobl\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\bg\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�[����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b��[��]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[�������]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b��[���]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\bul\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[���]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�[��]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b��[�����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[�����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b��[������]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\bpr\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�-�\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�����\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�[���]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�[������]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�[����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b���[����]*\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b�-�\\b", x = loc))
      IsAddress <- TRUE
    if (grepl(pattern = "\\b\\d{1,4}\\b", x = loc))
      IsAddress <- TRUE
    if (IsAddress == FALSE) {
      return (
        tibble(
          request = loc,
          AdminAreaName = "IsAddress==F",
          LocalityName = "IsAddress==F",
          precision = "IsAddress==F",
          text = "IsAddress==F",
          name = "IsAddress==F",
          pos = NA,
          lon = NA,
          lat = NA
        )
      )
      # break
    }
  }
  
  location <- gsub(",", "", location)
  location <- gsub(" ", "+", location)
  url_string <- paste("http://geocode-maps.yandex.ru/1.x/?geocode=",
                      location,
                      sep = "")
  url_string <- URLencode(url_string)
  xmlText <- paste(readLines(url_string), "\n", collapse = "")
  data <- xmlParse(xmlText, asText = TRUE)
  xml_data <- xmlToList(data)
  AdminAreaName <-
    xml_data$GeoObjectCollection$featureMember$GeoObject$metaDataProperty$GeocoderMetaData$AddressDetails$Country$AdministrativeArea$AdministrativeAreaName
  LocalityName <-
    xml_data$GeoObjectCollection$featureMember$GeoObject$metaDataProperty$GeocoderMetaData$AddressDetails$Country$AdministrativeArea$SubAdministrativeArea$Locality$LocalityName
  precision <-
    xml_data$GeoObjectCollection$featureMember$GeoObject$metaDataProperty$GeocoderMetaData$precision
  text <-
    xml_data$GeoObjectCollection$featureMember$GeoObject$metaDataProperty$GeocoderMetaData$text
  name <- xml_data$GeoObjectCollection$featureMember$GeoObject$name
  pos <- xml_data$GeoObjectCollection$featureMember$GeoObject$Point$pos
  lon <-
    as.numeric(gsub(
      pattern = "(.+)\\s+(.+)",
      replacement = "\\1",
      x = pos
    ))
  lat <-
    as.numeric(gsub(
      pattern = "(.+)\\s+(.+)",
      replacement = "\\2",
      x = pos
    ))
  return (
    tibble(
      request = loc,
      AdminAreaName = AdminAreaName,
      LocalityName = LocalityName,
      precision = precision,
      text = text,
      name = name,
      pos = pos,
      lon = lon,
      lat = lat
    )
  )
}

### ������� ���� ####
# system.time(l <- lapply(Adr, geoYandex, IsAddressFilter = T))

#### ������� ������������� ####
# ���������� � ������������� �������
gc()
nworkers <- detectCores() - 1
registerDoParallel(nworkers)
getDoParWorkers()

# ������������ ��������� ������ �� �����������
# http://stackoverflow.com/questions/38828344/how-to-log-when-using-foreach-print-or-futile-logger
loginit <- function(logfile) flog.appender(appender.file(logfile))
foreach(input=rep(common_log_name, nworkers),
        .packages='futile.logger') %do% loginit(input)


mtrace(geoYandex)
z <- Adr
system.time(
  l <- foreach(
                x = z,
                .combine = list,
                .multicombine = TRUE,
                .packages = c("rjson", "XML", "tibble")
              ) %do% {
                res <- geoYandex(x, IsAddressFilter = T)
                flog.info(paste0("address = ", x, " result = ", capture.output(str(res))))
                res
              })
mtrace.off()
# ����������� ���������
registerDoSEQ() # http://stackoverflow.com/questions/25097729/un-register-a-doparallel-cluster
