#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(promises)
library(future)
plan(multiprocess)

# Define UI for application that draws a histogram
ui <- fluidPage(
    
    # Application title
    titlePanel("Old Faithful Geyser Data"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Number of bins:",
                        min = 1,
                        max = 50,
                        value = 30)
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    
    val <- reactiveVal(NULL)
    
    observeEvent(input$bins, {
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2] 
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        print("generating bins")
        future({ Sys.sleep(2); bins }) %...>%
            val()
        
        # val(bins)
    })
    
    observeEvent(val(), {
        print("bins are generated")
    })
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        req(val())
        x    <- faithful[, 2] 
        # bins <- seq(min(x), max(x), length.out = input$bins + 1)
        
        bins <- val()
        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

