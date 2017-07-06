require(googleVis)
require(shiny)
require(rCharts)
require(markdown)
require(data.table)
require(reshape2)

indigenous <- fread("./data/brazil_indigenous_population.csv")
indigenous[, "perc_in_state":=round(indigenous*100/(non_indigenous+indigenous+non_declared),2), by=year]
Encoding(indigenous$state) <- "UTF-8"

pop_urban_rural <- fread("./data/census_population_by_area.csv")
Encoding(pop_urban_rural$state) <- "UTF-8"

br_states <- pop_urban_rural[order(state), unique(state)]


shinyServer(function(input, output, session){
  
  
  # Define general sidebar of and states
  output$sb_states <- renderUI({
    checkboxGroupInput("sb_states", "Choose States:", choices=br_states, selected=br_states)
  })

  output$sb_statex <- reactive({input$sb_states})
  
  # Update the sidebar with unselect all
  observeEvent(input$sb_states_none, 
         updateCheckboxGroupInput(session=session, inputId="sb_states", 
                  choices=br_states, selected=NULL)
  )
  
  # Update the sidebar with select all
  observeEvent(input$sb_states_all, 
         updateCheckboxGroupInput(session=session, inputId="sb_states", 
              choices=br_states, selected=br_states)
  )  
  
  
  
  ### INDIGENOUS SESSION
  # separate data in order of the selected states
  indg_data_states <- reactive({indigenous[state%in%input$sb_states]})
  
  # separete what value is to be plotted
  indg_data <-reactive({
    switch(input$indg_analysis,
      "0"={indg_data_states()[, "value":=indigenous][]},
      "1"={indg_data_states()[, "value":=perc_in_state][]}
      )
    
  })
  
  # the rendered title
  output$indg_title <- renderText({
    switch(input$indg_analysis,
      "0"={ paste("Total Indigenous Population in", input$indg_myYear)},
      "1"={ paste("Indigenous Percentage of the State Population in ", input$indg_myYear, " (%)")}
    )  
  
    
  })

  # take unique year to plot in geomap
  indg_data_geochart <- reactive({indg_data()[year==input$indg_myYear][]})
  output$indg_geochart <- renderGvis({
      gvisGeoChart(data= indg_data_geochart(),
                 locationvar="state", colorvar="value",
                 options=list(region="BR", displayMode="regions", 
                              resolution="provinces",
                              datalessRegionColor="black",
                              colorAxis="{minValue: 0, colors:['#ffffff','#8080ff','#0000ff','#000080']}",
                              backgroundColor="{fill:'black', stroke:'black', strokeWidth:10}",
                              legend="{textStyle:{color:'black', fontSize:16, bold:'True'}, numberFormat:''}",
                              keepAspectRatio="True",
                              tooltip="{ignoreBounds:'true'}"))


  })

  
  # lineplot of population along the years
  output$indg_stackchart <- renderChart2({
    n <- nPlot(data=indg_data(), value ~ year, group="state", type="stackedAreaChart")
    n$chart(margin=list(left=100))
    n$xAxis(axisLabel="Year", width=80)
    return(n)
    
  })  
  
  
  ### URBAN-RURAL  SESSION
  # separate the data of the selected states
  pop_data_states <- reactive({pop_urban_rural[state%in%input$sb_states]})
  
  # separate the for the area type
  pop_data_states_type <-reactive({
    switch(input$pop_analysis,
           "0"={pop_data_states()[area=="urban"]},
           "1"={pop_data_states()[area=="rural"]},
           "2"={pop_data_states()[area=="both"]}
    )
  })
  
  # separate data to the geo plot
  pop_data_states_type_year <- reactive({
    switch(input$pop_myYear,
           "2010"={pop_data_states_type()[, "value":=`2010`]},
           "2000"={pop_data_states_type()[, "value":=`2000`]},
           "1991"={pop_data_states_type()[, "value":=`1991`]},
           "1980"={pop_data_states_type()[, "value":=`1980`]},
           "1970"={pop_data_states_type()[, "value":=`1970`]},
           "1960"={pop_data_states_type()[, "value":=`1960`]}
    )       
  })
  
  # plot the demographic map
  output$pop_geochart <- renderGvis({
      gvisGeoChart(data= pop_data_states_type_year(),
                 locationvar="state", colorvar="value",
                 options=list(region="BR", displayMode="regions", 
                              resolution="provinces",
                              datalessRegionColor="black",
                              colorAxis="{minValue: 0, colors:['#ffffff','#8080ff','#0000ff','#000080']}",
                              backgroundColor="{fill:'black', stroke:'black', strokeWidth:10}",
                              legend="{textStyle:{color:'black', fontSize:16, bold:'True'}, numberFormat:''}",
                              keepAspectRatio="True",
                              tooltip="{ignoreBounds:'true'}"))
  })
  
  
  # separate data to the stacked chart, melt data to show the population growth along the years
  pop_stackchart_data <- reactive({
    melt(pop_data_states_type(), id.vars="state", 
         measure.vars = c("1960", "1970","1980", "1991","2000", "2010"),
         value.name = "population", variable.name = "year")
  })
  
  # plot the population growth along the years
  output$pop_stackchart <- renderChart2({
      n <- nPlot(data=pop_stackchart_data(), population ~ year, group="state", type="stackedAreaChart")
      n$chart(margin=list(left=100))
      n$xAxis(axisLabel="Year")
      return(n)
  })
  
  # mount the plot titles
  pop_title_aux <- renderText({
    switch(input$pop_analysis,
                 "0"={"Urban"},
                 "1"={"Rural"},
                 "2"={"Total"})
      })
  
  output$pop_title_geochart <- renderText({paste0(pop_title_aux()," Population in ", input$pop_myYear)})
  output$pop_title_stackchart <- renderText({paste0(pop_title_aux()," Population Along the Years ")})
  
})
