library(ggplot2) #load first! (Wickham)
library(lubridate) #load second!
library(dplyr)
library(tidyr)
library(tibble)
library(readr)
library(stringi)
library(stringr)
library(jsonlite)
library(magrittr)
library(curl)
library(httr)
library(jsonlite)
library(xml2)
library(rvest)
library(iterators)
library(foreach)
library(doParallel)
library(future)
library(RSelenium)
library(microbenchmark)
library(futile.logger)


common_log_name <- "FIPS.log"
output_fname <- "patents_list.csv"

# ==== functions definition
getAttr <- function(text, attrName) {
  res <- html_nodes(text, xpath=paste0("//div[@class='", attrName, "']")) %>% 
    magrittr::extract(-1) %>% # magrittr::extract(-1), ������� ������ ������, ��� ��������� �������
    # magrittr provides a series of aliases which can be more pleasant to use when composing chains using the %>% operator
    html_text() # ����� ��� �������
  # browser()
  # j <- res[[1]]
  # stri_encode(j, from="UTF-8", to="windows-1251", to_raw = FALSE)
  # browser()
  # iconv(from = "UTF8", to = "windows-1251")
  # m %>% html_nodes('div')
  res
}

# ======
flog.appender(appender.file(common_log_name))
flog.threshold(TRACE)
flog.info("============= Parsing started ===============")

# ����� ������ (�� �������): http://www1.fips.ru/wps/portal/IPS_Ru#1478591840047

# ���������� url ��� ���������� ����� (50 ��) ���������� �� ��� = G05B ����� �� ������ � �������� � �������� ��������� �������:
# http://www1.fips.ru/wps/portal/!ut/p/c5/jY7LDoIwFES_hS-4l2dhWYhpC4hgYhA2pCENYngYVBZ-vbByJTqznJyZgRIWD3JuG_lox0F2cIbSqYSgKY-Yjij2LlIvC0Pqu8h2-pIXThUwyi0SI7LkGKCwfMvgzDdQmP_Q-EUUf9D5-nZ7fc03-hM-9goKKMhn55AQD2lsRzpPXJN5NuSTuo_PqVaQ1bK-qFjNqktlo-DWn854JS9KNe0NbQg1dw!!/?beanMethod=doRestoreQuery&queryId=2737608&doSearch=true&pageNumber=2&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514
# ��� pagenumber �������� �� 0 �� 74 (����� ���������� 3743)
# � ����� �������� json, � �������� � ���� result -> hitlist ����� html �� ������� ����� ����������
# http://www.jsoneditoronline.org/
# http://codebeautify.org/jsonviewer

req_str1 <- "http://www1.fips.ru/wps/portal/!ut/p/c5/jY7LDoIwFES_hS-4l2dhWYhpC4hgYhA2pCENYngYVBZ-vbByJTqznJyZgRIWD3JuG_lox0F2cIbSqYSgKY-Yjij2LlIvC0Pqu8h2-pIXThUwyi0SI7LkGKCwfMvgzDdQmP_Q-EUUf9D5-nZ7fc03-hM-9goKKMhn55AQD2lsRzpPXJN5NuSTuo_PqVaQ1bK-qFjNqktlo-DWn854JS9KNe0NbQg1dw!!/?beanMethod=doRestoreQuery&queryId="
req_str3 <- "&doSearch=true&pageNumber="

# ��������� ��� = G05B (3738 ���������� �� 11.11.2016)
req_str2 <- "2737608"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = G06Q (2538 ���������� �� 11.11.2016)
req_str2 <- "2772556"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = H04W (2933 ���������� �� 14.11.2016, ���. 1-59), ��� ��������� ����������� �����������
req_str2 <- "2786932"
req_str4 <- "&selectedDBs=RUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = H04W (3032 ���������� �� 14.11.2016, ���. 1-61), ������ �������� ����������� �����������
req_str2 <- "2787104"
req_str4 <- "&selectedDBs=RUPATABRU&fromUserId=514"

# ��������� ��� = G06K (3690 ���������� �� 14.11.2016, ���. 1-74)
req_str2 <- "2788648"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = H03M (2436 ���������� �� 14.11.2016, ���. 1-49)
req_str2 <- "2789999"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = G06F3/00 or G06F13/00 or G06F12/00 or G06F5/00 or G06F9/00 or G06F11/00 or G06F21/00
# (3045 ���������� �� 14.11.2016, ���. 1-61)
req_str2 <- "2790898"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"

# ��������� ��� = G06F1/00 or G06F7/00 or G06F15/00 or G06F19/00
# (2667 ���������� �� 16.11.2016, ���. 1-54)
req_str2 <- "2813445"
req_str4 <- "&selectedDBs=RUPATABRU%3BRUPATAP%3BRUPAT_NEW%3BRUPMAB%3BRUPM_NEW%3BIMPIN&fromUserId=514"


# ����������� �� ���������, ������� � 0 � �� n-1
all_patents <-
  foreach(n = iter(0:53), .packages = 'futile.logger', .combine = rbind) %do% {
    ur1 <- str_c(req_str1, req_str2, req_str3, n, req_str4, collapse = "")
    # browser()
    # resp <- try(curl_fetch_memory(url))
    # ��������� �� httr: https://cran.r-project.org/web/packages/httr/vignettes/quickstart.html
    # ��������� exception ���� �� ��������
    resp <- GET(ur1)
    
    # �������� ��������� ��������
    flog.info(paste0("Parsing page ", n, " HTTP Status Code = ", resp$status_code))
    
    htext <- fromJSON(content(resp, "text"))
    # browser()
    
    ht <- htext$result$SearchResult$hitList
    # j3 <- stri_encode(ht, from = "UTF-8", to = "cp1251")
    # browser()
    m <- read_html(ht, encoding = "UTF-8")
    # m2 <- read_html(ht, encoding = "windows-1251")
    # guess_encoding(m)
    # browser()
    
    
    # ������ �������� ��� �� ������ � data.frame
    dvIndex <- getAttr(m, "dvIndex") %>% stri_replace_all_fixed(".", "") # ������ ����� ����� ������
    dvNumDoc <- getAttr(m, "dvNumDoc")
    dvDatePubl <- getAttr(m, "dvDatePubl")
    dvTitle <- getAttr(m, "dvTitle")
    
    # browser()
    # ��������� ������������� ���������
    docID <- html_nodes(m, xpath="//a[@class='hitListRow']") %>% html_attr("id")
    
    
    # browser()
    elem <- tibble(
      dvIndex=as.numeric(dvIndex),
      dvNumDoc=dvNumDoc,
      dvDatePubl=dvDatePubl,
      docID=docID, 
      dvTitle=dvTitle
    )
    # Encoding(dvTitle)
    
    elem
  }


write_csv(all_patents, output_fname, append=FALSE)
flog.info("Output file generated")

stop()

# === ������� �������� �������� ������� �� ��� id
# ������ ��������� �� ������: http://www1.fips.ru/wps/portal/!ut/p/c5/jY7LDoIwFES_hS-4l2dhWYhpC4hgYhA2pCENYngYVBZ-vbByJTqznJyZgRIWD3JuG_lox0F2cIbSqYSgKY-Yjij2LlIvC0Pqu8h2-pIXThUwyi0SI7LkGKCwfMvgzDdQmP_Q-EUUf9D5-nZ7fc03-hM-9goKKMhn55AQD2lsRzpPXJN5NuSTuo_PqVaQ1bK-qFjNqktlo-DWn854JS9KNe0NbQg1dw!!/?beanMethod=getDocument&queryId=2760601&documId=dae8d132a3b82a6abef5bab3de50c234&checkBoxes=&fromUserId=514


m <- iconv(dvTitle, from="UTF8", to="windows-1251")
j3 <- stri_encode(j, from="UTF-8", to="cp1251")

# ������� �������������� ����������
id <- html_nodes(m, xpath="//a[@class='hitListRow']") %>% html_attr("id")
# ���� ������ �������� ����� �� ������ url:
# http://www1.fips.ru/wps/portal/IPS_Ru#docNumber=13&docId=dae8d132a3b82a6abef5bab3de50c234
ur <- paste0("http://www1.fips.ru/wps/portal/IPS_Ru#docNumber=13&docId=", id[[1]])
resp <- GET(ur)
cc <- content(resp, "text")
str(content(resp, "text"), nchar.max=5000)
write(cc, "resp.txt", append=FALSE)

# ����� ����� Selenium
remDrv <- remoteDriver()
remDrv$open()
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 5555, browserName = "internet explorer")
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 9515, browserName = "chrome")
remDr <- remoteDriver(browserName = "internet explorer")
remDr <- remoteDriver(browserName = "chrome")
remDr$open()

# === ��������� �������� ����� Selenium
# Selenium ���������� ��������� �������
# remDrv <- remoteDriver()
remDrv <- remoteDriver(browserName = "chrome")
# remDrv <- remoteDriver(browserName = "internet explorer")
remDrv$open()

ur2 <- "http://www1.fips.ru/wps/portal/IPS_Ru#docNumber=13&docId=dae8d132a3b82a6abef5bab3de50c234"

remDrv$navigate(ur1)
Sys.sleep(2)
remDrv$navigate(ur2)

