#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DBI)
library(plotly)
library(lubridate)
library(leaflet)
library(dplyr)


meteo_db_5m <- dbConnect(RSQLite::SQLite(),dbname = "db_archive\\meteo_db_5m")
meteo_comune <- dbReadTable(meteo_db_5m,"meteo_comune_5m")

comuni_db <- dbConnect(RSQLite::SQLite(),dbname = "db_archive\\comuni_db")
comuni_lomb <- dbReadTable(comuni_db,"comuni_db")

join <- inner_join(meteo_comune,comuni_lomb)


# Use a fluid Bootstrap layout
ui <- fluidPage(    

        
    # Give the page a title
    titlePanel("Previsioni meteo sui comuni della Lombardia"),
    
    # Generate a row with a sidebar
    sidebarLayout(     
        
        # Define the sidebar with two input
        sidebarPanel(
            helpText("Scegli la provincia e il 
                     comune per visualizzare il 
                     meteogramma"),
            selectInput("prov","Provincia:",
                        choices = unique(meteo_comune$Provincia)),
            selectInput("comune", "Comune:", 
                        choices=NULL),
            hr(),
            h4("Tabella dati - T (", iconv("\xb0C", "latin1", "UTF-8"), "), Prec (mm)"),
            DT::dataTableOutput("table")
            #tableOutput("table")
        ),
        
         mainPanel(
             leafletOutput(outputId = "mymap"),
             hr(),
             plotlyOutput("meteogram2"),
             plotlyOutput("meteogram3"),
             plotlyOutput("meteogram"),
             plotlyOutput("meteogram4")
             #cum_days()
             #h4("Statistiche"),
             #tableOutput("stats")
         )
        
    )
)

server <- function(input, output,session){
    
    observeEvent(input$prov,{
        updateSelectInput(session,'comune',
                          choices=unique(meteo_comune$Comune[meteo_comune$Prov==input$prov]))
    })
    
    base_provincia <- reactive({
    dplyr::filter(meteo_comune,meteo_comune$Prov==input$prov)    
    })
    
    base_comune <- reactive({
    dplyr::filter(meteo_comune,meteo_comune$Comune==input$comune)
    })
    
    base_coordinate <- reactive({
    dplyr::filter(join,join$Comune==input$comune)
    })
    
    data <- reactive({
        df <- base_comune()
        aggregate.data.frame(list(mm = as.double(df$Precipitazioni)), by=list(Giorno= factor(day(df$Orario),levels = unique(day(df$Orario)))), FUN=sum ) %>%
        rbind(as.character(df$Giorno),df$mm)   
        #base_comune() %>%
        #group_by(day(base_comune()$Orario)) %>%
        #summarise(somma = sum(as.double(base_comune()$Prec)))
        #base_comune[,list(cum_days=sum(as.double(base_comune()$Prec))),by=day(base_comune()$Orario)]
    })
    

    #data_sigma_minus <- reactive({
     #   median(as.double(base_comune()$Temperatura)) - 3*sd(as.double(base_comune()$Temperatura))
    #})
    #data_sigma_plus <- reactive({
     #   median(as.double(base_comune()$Temperatura)) + 3*sd(as.double(base_comune()$Temperatura))
    #})
    
    #data_sigma_plus_prec <- reactive({
    #    median(as.double(base_comune()$Prec)) + 3*sd(as.double(base_comune()$Temperatura))
    #})
    
    #data_sigma_plus_vv <- reactive({
    #    (min(as.double(base_comune()$VV)))
        
    #})
    
    output$stats <- renderTable({
        data()
    })
    
    #Create a map with points on Lombardy
    output$mymap <- renderLeaflet({
        leaflet(data) %>% 
            setView(lng = 9.7, lat = 45.5, zoom = 7)  %>% #setting the view over ~ center of Lombardy
            addTiles() %>% 
            addMarkers(data = join, lat = base_coordinate()$Latitudine , lng = base_coordinate()$Longitudine, popup = as.character(input$comune))
    })
    #####Temporary#######
    #Create a table with data of selected choice 
    output$table <- DT::renderDataTable({
    df <- data.frame(Orario = base_comune()$Orario,T = base_comune()$Temperatura,Prec =  base_comune()$Precipitazioni)
    
    #}, striped = TRUE, bordered = TRUE, spacing = 'xs', colnames = TRUE)
    DT::datatable(df,options = list(searching = FALSE, pageLength= 24, lengthMenu = list(c(24,48,-1),c("24","48","72"))))
    }
    )
    #####Temporary_END#######
    
    # Creation of plots (Meteograms) with the selected choice
    output$meteogram <- renderPlotly({
        meteogram <- plot_ly(meteo_comune, x = ymd_hm(base_comune()$Orario), y = round(as.double(base_comune()$Precipitazioni),digits = 0), type = 'bar',
                             marker = list(color = 'rgb(158,202,225)',
                                           line = list(color = 'rgb(8,48,107)',
                                                       width = 1.5))) %>%
            add_annotations(x = 0.5, y = 1, xref = "paper", yref = "paper", text = paste("Giorno ",as.character(data()$Giorno[1]),"=",as.character(data()$mm[1])," mm",sep=""), showarrow = F) %>%
            add_annotations(x = 0.5, y = 0.95, xref = "paper", yref = "paper", text = paste("Giorno ",as.character(data()$Giorno[2]),"=",as.character(data()$mm[2])," mm",sep=""), showarrow = F) %>%
            add_annotations(x = 0.5, y = 0.9, xref = "paper", yref = "paper", text = paste("Giorno ",as.character(data()$Giorno[3]),"=",as.character(data()$mm[3])," mm",sep=""), showarrow = F) %>%
                  layout(title = paste("Precipitazioni a ",input$comune," (",input$prov,")",sep=""),
                  yaxis = list(title = "Precipitazioni (mm)", range = c(0,2*max(as.double(base_comune()$Precipitazioni)))))
        
        
    })
    
    output$meteogram2 <- renderPlotly({
        meteogram2 <- plot_ly(meteo_comune, x = ymd_hm(base_comune()$Orario), y = as.double(base_comune()$Temperatura), type = 'scatter',
                             mode = 'lines+markers', line = list(color = 'green',width = 3), marker = list(color = 'green', size = 8) ) %>%
            layout(title = paste("Temperatura a ",input$comune," (",input$prov,")",sep=""),
                   yaxis = list(title = "Temperature (\u00B0C)"))
    })
    
    output$meteogram3 <- renderPlotly({
        meteogram3 <- plot_ly(meteo_comune, x = ymd_hm(base_comune()$Orario), y = round(as.double(base_comune()$Copertura.del.cielo),digits = 0), type = 'bar',
                             marker = list(color = 'rgb(192,192,192)', alpha = 0.5,
                                           line = list(color = 'rgb(128,128,128)',
                                                       width = 1.5))) %>%
            layout(title = paste("Nuvolosita' a ",input$comune," (",input$prov,")",sep=""),
                   yaxis = list(title = "Nuvolosita' (ottavi)", range = c(0,8)))
    })
    
    output$meteogram4 <- renderPlotly({
        meteogram2 <- plot_ly(meteo_comune, x = ymd_hm(base_comune()$Orario), y = as.double(base_comune()$VV), type = 'scatter',
                              mode = 'lines+markers', line = list(color = 'red',width = 3), marker = list(color = 'red', size = 8) ) %>%
            layout(title = paste("Velocita' e direzione del vento a ",input$comune," (",input$prov,")",sep=""),
                   yaxis = list(title = "Velocita' vento (m/s)", range = c(0,2*max(as.double(base_comune()$VV)))), annotations = list(x = ymd_hm(base_comune()$Orario),
                        y = as.double(base_comune()$VV), font = list(color = "black", size = 12),
                        arrowcolor = "black", ax=(as.double(base_comune()$u10)*10), ay=(as.double(base_comune()$v10)*10), arrowsize = 3, arrowwidth = 1, arrowhead = 1)
            )
    })
    

}
dbDisconnect(meteo_db_5m)
dbDisconnect(comuni_db)
# Run the application
options(shiny.host = '0.0.0.0')
options(shiny.port = 8803)
shinyApp(ui = ui, server = server)


