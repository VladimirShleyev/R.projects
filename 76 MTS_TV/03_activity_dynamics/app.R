# Single-file Shiny apps (http://shiny.rstudio.com/articles/single-file.html)
# Обязательно в кодировке UTF-8
rm(list=ls()) # очистим все переменные
gc()

library(tidyverse)
library(lubridate)
library(scales)
library(forcats)
library(readxl)
library(magrittr)
library(stringi)
library(stringr)
library(futile.logger)
library(jsonlite)
library(Cairo)
library(RColorBrewer)
library(extrafont)
library(hrbrthemes)
library(DBI)
library(RPostgreSQL)
library(config)
library(shiny)
library(shinyjqui)
library(shinythemes) # https://rstudio.github.io/shinythemes/
library(shinyBS)
library(shinyjs)
library(shinycssloaders)
library(config)
library(anytime)
library(tictoc)
library(digest)
library(officer)

options(shiny.usecairo=TRUE)
options(shiny.reactlog=TRUE)
options(spinner.type=4)

source("clickhouse.R")
eval(parse("funcs.R", encoding="UTF-8"))

# очистим все warnings():
assign("last.warning", NULL, envir = baseenv())

# ================================================================
ui <- 
  navbarPage("DVT IoT",
  # title=HTML('<div><a href="http://devoteam.com/"><img src="./img/devoteam_176px.png" width="80%"></a></div>'),
  title = "Статистика телесмотрения",
  tabPanel("Динамика пользовательской активности", value="general_panel"),
  tabPanel("About", value="about"),
  # windowTitle="CC4L",
  # collapsible=TRUE,
  id="tsp",
  # theme=shinytheme("flatly"),
  theme=shinytheme("yeti"),
  # shinythemes::themeSelector(),
  # includeCSS("styles.css"),

  # http://stackoverflow.com/questions/25387844/right-align-elements-in-shiny-mainpanel/25390164
  tags$head(tags$style(".rightAlign{float:right;}")), 

  # titlePanel("Статистика телесмотрения"),
  # ----------------
  conditionalPanel(
    # general panel -----------------------
    condition = "input.tsp == 'general_panel'",
    fluidRow(
      tags$style(type='text/css', '#cweather_text {white-space:pre;}')
      # tags$style(type='text/css', 'div {background-color: #000с00;}'), 
      
      #column(6, h2("Типовая форма"), h3(textOutput("cweather_text", inline=TRUE))),
      #column(6, h2("Заполнитель"))
      ),
    fluidRow(
      column(2, dateRangeInput("in_date_range",
                               label="Диапазон дат",
                               start=Sys.Date()-1, end=Sys.Date(),
                               # на время отладки
                               # start="2017-06-28", end="2017-06-30",
                               # min = Sys.Date() - 10, 
                               max = Sys.Date(),
                               separator = " - ", format = "dd/mm/yy",
                               startview = "month", language = 'ru', weekstart=1)
      ), 
      column(1, selectInput("history_depth", "История", 
                            choices = c("1 месяц"=30, "2 недели"=14,
                                        "1 неделя"=7, "3 дня"=3, "1 день"=1), selected=1)),
      #column(1, selectInput("min_watch_time", "Мин. время",
      #                      choices = c("5 сек"=5, "10 сек"=10, 
      #                                  "20 сек"=20, "30 сек"=30), selected = 10)),
      #column(1, selectInput("max_watch_time", "Макс. время",
      #                      choices = c("1 час"=1, "2 часа"=2, 
      #                                  "3 часа"=3, "4 часа"=4), selected = 2)),
      column(3, uiOutput("choose_region")),
      column(3, uiOutput("choose_channel")),
      column(1, selectInput("segment_filter", "Сегмент",
                            choices = c("Все"="all",
                                        "DVB-C"="DVB-C", 
                                        "IPTV"="IPTV", 
                                        "DVB-S"="DVB-S"), selected="all")),
      column(1, selectInput("top_num", "Кол-во в ТОП", 
                            choices=c(3, 5, 7, 10, 20), selected=5)),
      column(1, selectInput("time_bin", "Агрегация", 
                            choices=c("1 час"=60, "1 сутки"=24*60), selected=60))
    ),
    fluidRow(
      column(10, actionButton("set_test_dates_btn", "Вкл. демо дату", class = 'rightAlign')),
      column(2, actionButton("process_btn", "Применить", class = 'rightAlign'))
    ),

    #tags$style(type='text/css', "#in_date_range { position: absolute; top: 50%; transform: translateY(-80%); }"),
    tabsetPanel(
      id = "panel_id",
      selected="table_tab",
      tabPanel("Таблица", value = "table_tab",
               fluidRow(
                 p(),
                 column(12, div(checkboxInput("long_wide_cbx", "Long форма", TRUE), 
                                class='rightAlign'))
               ),
               fluidRow(
                 column(12, div(withSpinner(DT::dataTableOutput('stat_table'))), style="font-size: 90%")
               ),
               p(),
               fluidRow(
                 column(8, {}),
                 column(2, downloadButton("csv_download_btn", label="Экспорт (Excel)", class = 'rightAlign')),
                 column(2, downloadButton("word_download_btn", label="Экспорт (Word)", class = 'rightAlign'))
               )
      ),
      tabPanel("График", value = "graph_tab",
               fluidRow(
                 p(),
                 jqui_sortabled(
                   div(id='top10_plots',
                 column(6, div(withSpinner(plotOutput('top10_left_plot', height="500px")))),
                 column(6, div(withSpinner(plotOutput('top10_right_plot', height="500px"))))
                 )))
               )
      )
    #,
    #fluidRow(
    #  column(6, textOutput('info_text'))
    #)
    
  ),
  shinyjs::useShinyjs()  # Include shinyjs
)


# ================================================================
server <- function(input, output, session) {
  # статические переменные ------------------------------------------------
  log_name <- "app.log"
  
  flog.appender(appender.tee(log_name))
  flog.threshold(TRACE)
  flog.info("App started")

  # создание параметров оформления для различных видов графиков (screen\publish) ------
  font_sizes <- list(
    "screen"=list(base_size=20, axis_title_size=18, subtitle_size=15),
    "word_A4"=list(base_size=14, axis_title_size=12, subtitle_size=11)
  )
  
  # создаем коннект к инстансу CH -----------
  if (Sys.info()["sysname"] == "Linux") {
    # CTI стенд
    con <- dbConnect(clickhouse(), host="172.16.33.74", port=8123L, user="default", password="")
  }else{
    # MT стенд
    con <- dbConnect(clickhouse(), host="10.0.0.44", port=8123L, user="default", password="")
  }      
  
  # подгрузим таблицу преобразования транслита в русские названия городов -------
  cities_df <- {
    flog.info("Loading cities translit table")
    # подгрузим ограниченный список городов
    city_subset <- read_csv("region.csv")
    
    df <- req(dbGetQuery(con, "SELECT * FROM regnames")  %>%
                mutate_if(is.character, `Encoding<-`, "UTF-8") %>%
                filter(translit %in% pull(city_subset)))
    flog.info(paste0("Cities translit table loaded ", nrow(df), " rows"))
    # dbDisconnect(con)
    df
  }

  
  # подгрузим таблицу преобразования идентификатора канала в русское название ----
  progs_df <- jsonlite::fromJSON("./channels.json", simplifyDataFrame=TRUE) %>% 
    select(channelId, channelName=name)
  
  # реактивные переменные -------------------
  raw_df <- reactive({
    input$process_btn # обновлять будем вручную
    
    isolate({
      top_num <- input$top_num
      # regions <- c("Moskva", "Barnaul")
      # browser()
      regions <- input$region_filter
      # browser()
      flog.info(paste0("Applied time filter [", input$in_date_range[1], "; ", input$in_date_range[2], "]"))
      flog.info(paste0("Applied region filter [", regions, "]"))
      # сначала запрашиваем ТОП 20 каналов
      r <- buildReqGetTop(begin=input$in_date_range[1], end=input$in_date_range[2],
                          regions=regions, segment=input$segment_filter, top=top_num)
      flog.info(paste0("DB request: ", r))
    
      # запрос Топ-N каналов
      tic()
      temp_df <- dbGetQuery(con, r) %>%
        as_tibble()
      flog.info(paste0("Query for Top ", top_num, " channels: ", capture.output(toc())))
      flog.info(paste0("Table: ", capture.output(head(temp_df, 2))))
      flog.info(paste0("Loaded ", nrow(temp_df), " rows"))
      
      # если каналов вообще нет, выбрасываем NULL
      # if(nrow(temp_df)<=0) return(NULL)

      # вытаскиваем каналы, выборку подрезать на изменяемую глубину будем потом
      channels <- temp_df %>% 
        # исключим возможные несисмвольные типы, например, logical(0)
        mutate(channelId=as.character(channelId)) %>%
        # filter(row_number()<=5) %>% 
        pull(channelId)
    
      # запрос конкретных данных
      r <- buildReqDynamic(begin=input$in_date_range[1], end=input$in_date_range[2],
                           regions=regions, 
                           interval=as.numeric(input$time_bin), 
                           channels=channels, 
                           segment=input$segment_filter)
      flog.info(paste0("DB request: ", r))    

      tic()
      # browser()
      temp_df <- dbGetQuery(con, r) %>%
          as_tibble()
      flog.info(paste0("Query by specific Top ", top_num, " channels: ", capture.output(toc())))
      flog.info(paste0("Table: ", capture.output(head(temp_df, 2))))
      flog.info(paste0("Loaded ", nrow(temp_df), " rows"))    
    })
    

    # df <- NULL
    df <- temp_df %>%
      # время смотрения, мин
      mutate(channel_duration=round(as.numeric(channel_duration), 0)) %>%
      # превращаем временной маркер в POSIX
      mutate(timegroup=anytime(as.numeric(timegroup), tz="UTC")) %>%
      as_tibble()
    
    df
  })  

  cur_df <- reactive({
    df <- req(raw_df()) %>%
      mutate_at(vars(channelId), as.character) %>%
      left_join(progs_df, by=c("channelId")) %>%
      # санация
      mutate(channelName=if_else(is.na(channelName), 
                                 str_c("_", channelId, "_"), 
                                 channelName))
    
    # а теперь делаем агрегацию по русскому имени канала. 
    # именно из-за неоднозначности мапирования name-channelId возникает дублирование записей в таблице и пила на графике
    # browser()
    df %<>%
      mutate_at(vars(channel_duration, watch_events), as.numeric) %>%
      group_by(timegroup, channelName) %>%
      summarise(channel_duration=sum(channel_duration), watch_events=sum(watch_events)) %>%
      ungroup() %>%
      select(channelName, timegroup, everything())
    
    df # channelId & timestamp здесь потерялись
  })
  
  msg <- reactiveVal("")

  # таблица с выборкой по регионам ----------------------------
  output$stat_table <- DT::renderDataTable({
    df <- req(cur_df())
    
    # проверяем форму представления и модифицируем, если надо
    if(!input$long_wide_cbx){
      df %<>% select(-channel_duration) %>%
        spread(timegroup, watch_events)
    }
    
    colnames_df <- getRusColnames(df)
    # https://stackoverflow.com/questions/39970097/tooltip-or-popover-in-shiny-datatables-for-row-names
    colheader <- htmltools::withTags(
      table(class = 'display',
            thead(
              tr(colnames_df %>%
                   {purrr::map2(.$col_label, .$col_runame_screen, ~th(title=.x, .y))})
              )))
    
    # browser()
    # https://rstudio.github.io/DT/functions.html
    dt <- DT::datatable(df,
                  rownames=FALSE,
                  filter='bottom',
                  # только после жесткой фиксации колонок
                  container=colheader,
                  options=list(dom='fltip', pageLength=7, lengthMenu=c(5, 7, 10, 15),
                               order=list(list(1, 'asc')), # нумерация с 0
                               # columnDefs=list(list(width="160px", targets="_all"),
                               #                 list(className='dt-center', targets="_all")),
                  #autoWidth=TRUE,
                  #scrollCollapse=TRUE,
                  scrollX=TRUE
                  )
                  )
    
    # проверяем форму представления и модифицируем, если надо
    if(input$long_wide_cbx){
      dt %<>% DT::formatDate("timegroup", method="toLocaleString")
      }
      dt
    })
  
  # левый график  -------------
  output$top10_left_plot <- renderPlot({
    shiny::validate(
      need(!is.null(cur_df()), "NULL value can't be renederd"),
      need(nrow(cur_df())>0, "0 rows -- nothing to draw") 
    )
    plotAreaplotActivity(cur_df(), publish_set=font_sizes[["screen"]], 
                      ntop=as.integer(input$top_num))
  })
  
  # правый график --------------
  output$top10_right_plot <-renderPlot({
    shiny::validate(
      need(!is.null(cur_df()), "NULL value can't be renederd"),
      need(nrow(cur_df())>0, "0 rows -- nothing to draw") 
    )
    plotLineplotActivity(cur_df(), publish_set=font_sizes[["screen"]], 
                 ntop=as.integer(input$top_num))
  })  

  # динамическое управление диапазоном дат ---------
  observeEvent(input$history_depth, {
    # $history_depth получаем как строку
    date <- Sys.Date()-as.numeric(input$history_depth)
    flog.info(paste0("Start date changed to  ", date))
    # updateDateRangeInput(session, "in_date_range", start=date)
   }
  )

  # фиксим даты на демо диапазон ---------  
  observeEvent(input$set_test_dates_btn, {
    updateDateRangeInput(session, "in_date_range", start="2017-06-28", end="2017-06-30")
    }
  )
  
  # управляем визуализацией кнопок выгрузки ----- 
  observe({
    # browser()
    if(!is.null(cur_df()) & nrow(cur_df())>0) {
      shinyjs::enable("csv_download_btn")
      shinyjs::enable("word_download_btn")
    } else {
      shinyjs::disable("csv_download_btn")
      shinyjs::disable("word_download_btn")
    }
  })  
  
  # служебный вывод ---------------------  
  output$info_text <- renderText({
    msg()
  })


  # динамический выбор региона ---------
  output$choose_region <- renderUI({
    
    data <- as.list(cities_df$translit)
    names(data) <- cities_df$russian
    
    # browser()
    
    # создадим элемент
    selectInput("region_filter", 
                paste0("Регион (", length(data), ")"),
                multiple=TRUE,
                choices=data, width = "100%")
  })

  # динамический выбор канала ---------
  output$choose_channel <- renderUI({
    
    # имена каналов могут быть одинаковыми для разных ID, которые включают и название сегмента
    df <- progs_df %>% distinct(channelName) %>% arrange(desc(channelName)) 
    data <- as.list(df$channelName)
    names(data) <- df$channelName
    # distinct(df) %>% group_by(channelName) %>% summarise(n=n()) %>% arrange(desc(n))
    
    # browser()
    
    # создадим элемент
    selectInput("channel_filter", 
                paste0("Канал (", length(data), ")"),
                multiple=TRUE,
                choices=data, width = "100%")
  })
  
  
  # обработчики кнопок выгрузки файлов --------------------------------------------------
  # выгрузка таблицы в CSV -----------------------  
  output$csv_download_btn <- downloadHandler(
    filename = function() {
      paste0("user_dynamics_data-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      cur_df() %>%
        # сделаем вывод в формате, принимаемым Excel
        write.table(file, na="NA", append=FALSE, col.names=TRUE, 
                    row.names=FALSE, sep=";", fileEncoding="windows-1251")
    }
  )
  
  # выгрузка таблицы в Word -----------------------
  output$word_download_btn <- downloadHandler(
    filename = function() {
      name <- paste0("user_dynamics_report-", Sys.Date(), ".docx", sep="")
      flog.info(paste0("Word report: '", name, "'"))
      name
    },
    content = function(file) {
      doc <- cur_df() %>% # select(-total_unique_stb) %>% # пока убираем, чтобы была консистентная подстановка
        gen_word_report(publish_set=font_sizes[["word_A4"]])
      print(doc, target=file)  
    }
  )  
  
}

shinyApp(ui = ui, server = server)
