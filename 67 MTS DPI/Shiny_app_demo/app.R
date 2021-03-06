library(tidyverse)
library(lubridate)   # date manipulation
library(magrittr)
library(countrycode) # turn country codes into pretty names
library(scales)      # pairs nicely with ggplot2 for plot label formatting
# library(gridExtra)   # a helper for arranging individual ggplot objects
library(ggthemes)    # has a clean theme for ggplot2
library(viridis)     # best. color. palette. evar.
library(RColorBrewer)# best. color. palette. evar.
library(hrbrthemes)
library(extrafont)   # http://blog.revolutionanalytics.com/2012/09/how-to-use-your-favorite-fonts-in-r-charts.html
# library(forcats)
library(sna)
library(igraph)
library(intergraph) # http://mbojan.github.io/intergraph/
# library(ggpmisc)
library(ggnetwork)
library(Cairo)
library(shiny)
library(shinythemes) # https://rstudio.github.io/shinythemes/
library(futile.logger)

eval(parse("heatmap_func.R", encoding="UTF-8"))

# http://shiny.rstudio.com/gallery/plot-interaction-basic.html
# https://shiny.rstudio.com/articles/debugging.html
# https://blog.rstudio.org/2015/06/16/shiny-0-12-interactive-plots-with-ggplot2/

flog.appender(appender.file('app.log'))
flog.threshold(TRACE)
flog.info("Dashboard started")

# options(shiny.error=browser)
# options(shiny.reactlog=TRUE)
# options(shiny.usecairo=TRUE)

# первичная инициализация --------------------------

# Define UI for application that draws a histogram
ui <- fluidPage(
  # Some custom CSS for a smaller font for preformatted text
  tags$head(
    tags$style(HTML("
                    pre, table.table {
                    font-size: smaller;
                    }
                    "))
    ),
  theme=shinytheme("united"), #("slate"),
  # shinythemes::themeSelector(),

  sidebarLayout(
    sidebarPanel(
      width = 2, # обязательно ширины надо взаимно балансировать!!!!
      radioButtons("plot_type", "Тип графика",
                   c("base", "ggplot2")),
      radioButtons("ehm_pal", "Палитра",
                   c("viridis", "brewer")),
      # Кнопка запуска расчетов event_heat_map
      actionButton ("ehm_btn", "Карта событий")
    ),

    mainPanel(
      width = 10, # обязательно ширины надо взаимно балансировать!!!!
      fluidRow(
        column(width=6, 
               plotOutput("plot1", 
                          click="plot_click",
                          dblclick="plot_dblclick",
                          hover="plot_hover",
                          brush="plot_brush")),
        column(width=3,
               verbatimTextOutput("click_info")),
        column(width=3,
               verbatimTextOutput("data_info"))
        ),
      fluidRow(
        #column(width=12, div(style = "height:200px;background-color: yellow;"), plotOutput("event_plot"))
        column(width=12, plotOutput("event_plot", click="ehm_click"))
      )
      )
    )  
  )

# Define server logic required to draw a network
server <- function(input, output, session) {
  
  attacks <- reactive({
    # специально завязали на кнопку
    flog.info(paste0("attacks invalidated ", input$ehm_btn))        

    attacks_raw <- req(read_csv("eventlog.csv", col_types="ccc", progress=interactive()) %>%
                         slice(1:20000))
    
    attacks <- attacks_raw %>%
      group_by(tz) %>%
      nest()
    
    attacks <- attacks %>%
      mutate(res=map2(data, tz, parseDFDayParts)) %>%
      unnest() %>%
      # превратим wkday в фактор принудительно с понедельника
      mutate(wkday=factor(wkday, levels=weekdays(dmy("13.02.2017")+0:6)))
    
  })
  
  wkd_attacks <- reactive({
    count(attacks(), wkday, hour)
  })
  
  net <- reactive({
    # определяем сетевой объект на уровне сессии пользователя
    g <- graph_from_literal(A-+B-+C, D-+A, C+-E-+D, E-+B)
    set.seed(123)
    g <- igraph::set_vertex_attr(g, "ip_addr", # "label"
                                 value=stringr::str_c("192.168.1.", sample(1:254, vcount(g), replace=FALSE)))
    # прошлись по граням
    val <- stringr::str_c("UP = ", sample(1:10, ecount(g), replace=FALSE))
    g <- igraph::set_edge_attr(g, "volume", value=val)
    g <- igraph::set_edge_attr(g, "type", value=sample(letters[24:26], ecount(g), replace=TRUE))
    lo <- layout_on_grid(g) # lo is a matrix of coordinates
    # !! из анализа github понял, что можно в качестве layout матрицу подсовывать!!
    net <- ggnetwork(g, layout=lo)
    
    net
  })
  
  output$plot1 <- renderPlot({
    if (input$plot_type == "base") {
      plot(mtcars$wt, mtcars$mpg)
    } else if (input$plot_type == "ggplot2") {
      gp <- ggplot(net(), aes(x=x, y=y, xend=xend, yend=yend)) +
        # geom_edges(aes(linetype=type, color=type, lwd=type)) +
        geom_edges(aes(linetype=type), color="grey75", lwd=1.2)+ #  , curvature = 0.1) +
        geom_nodes(color="gold", size=8) +
        # geom_nodelabel(aes(label=vertex.names), fontface="bold") +
        # geom_nodelabel_repel(aes(color=ip_addr, label=vertex.names), fontface = "bold", box.padding=unit(2, "lines")) +
        geom_nodelabel_repel(aes(label=ip_addr), fontface = "bold", box.padding=unit(2, "lines"), 
                             segment.colour="red", segment.size=1) +
        geom_edgetext_repel(aes(label=volume), color="white", fill="grey25",
                            box.padding = unit(1, "lines")) +
        theme_blank() +
        theme(axis.text = element_blank(),
              axis.title = element_blank(),
              panel.background = element_rect(fill = "grey25"),
              panel.grid = element_blank())
      
      gp
    }
  })

  output$event_plot <- renderPlot({
    fontsize <- session$clientData$output_event_plot_height/400 * 20
    #fontsize <- session$clientData$output_event_plot_width/1600 * 24
    flog.info(paste0("Font size recalculated. Size = ", fontsize, " pt"))
    flog.info(sprintf("H = %s px, W = %s px", 
                      session$clientData$output_event_plot_height, 
                      session$clientData$output_event_plot_width))
    gp <- createEventPlot(wkd_attacks(), palette=input$ehm_pal, fontsize)
    # ggsave("fig8.png", plot=gp)
    gp
  }, bg="transparent")

  output$click_info <- renderPrint({
    cat("input$ehm_click:\n")
    str(input$ehm_click)
  })
  
  output$hover_info <- renderPrint({
    cat("input$plot_hover:\n")
    str(input$plot_hover)
  })
  output$dblclick_info <- renderPrint({
    cat("input$plot_dblclick:\n")
    str(input$plot_dblclick)
  })
  output$brush_info <- renderPrint({
    # cat("input$plot_brush:\n")
    # str(input$plot_brush)
    # Get width and height of image output
    #w  <- session$clientData#$output_image_render_width
    #h <- session$clientData#$output_image_render_height
    #str(w, h)      
  })
  
  output$data_info <- renderPrint({
    # With base graphics, need to tell it what the x and y variables are.
    nearPoints(wkd_attacks(), input$ehm_click, threshold = 10, xvar="hour", yvar="wkday")
  })
  
}


shinyApp(ui, server)


# Run the application 
# shinyApp(ui=ui, server=server, display.mode="showcase") # так не рабоает, потому что не runApp
# см http://stackoverflow.com/questions/26291523/showcase-display-mode-for-published-app-in-shinyapps-io
# mode showcase включил через файл DESCRIPTION

