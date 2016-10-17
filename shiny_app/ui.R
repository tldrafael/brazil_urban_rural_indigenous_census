require(shiny)
require(rCharts)

shinyUI(
  navbarPage("Brazil Census",
      tabPanel("Plot",
            sidebarPanel(
              uiOutput("sb_states"),
                 actionButton("sb_states_all", label="Select All"),
                 actionButton("sb_states_none", label="Unselect All")
              ),
              mainPanel(
                tabsetPanel(
                  tabPanel(p(icon("indigenous"), "Indigenous"),
                      column(10, 
                          sidebarLayout(
                               sidebarPanel(radioButtons("indg_analysis", "Show:",
                                                c("Total of Indigenous Population"="0", "Indigenous Percentage of the State Population (%)"="1"),
                                                      inline=F, selected = "0"),
                                            radioButtons("indg_myYear", "Year:",
                                              c("2010"="2010", "2000"="2000", "1991"="1991"), inline=F, selected="2010")
                           ),
                           mainPanel(
                               h4(textOutput("indg_title"), align="center"),
                               htmlOutput("indg_geochart", align="center")
                            )
                           )
                        ),
                        column(12, offset = 1,
                             mainPanel( 
                             #  h3(textOutput("sb_statex")),
                               br(),
                               br(),
                               h4("Indigenous Population Along the Years", align="left"),
                               showOutput("indg_stackchart", lib="nvd3")
                               )
                        )   
                  ),
                  tabPanel("Urban-Rural Population",
                       column(10, 
                              sidebarLayout(
                                sidebarPanel(radioButtons("pop_analysis", "Show:",
                                                          c("Urban Population"="0", "Rural Population"="1", "Total Population"="2"),
                                                          inline=F),
                                             radioButtons("pop_myYear", "Year:",
                                                          c("2010"="2010", "2000"="2000", "1991"="1991","1980"="1980", "1970"="1970", "1960"="1960"), inline=F)
                                ),
                                mainPanel(
                                  h4(textOutput("pop_title_geochart"), align="center"),
                                  htmlOutput("pop_geochart", align="center")
                                )
                              )
                       ),
                       column(12, offset = 1,
                              mainPanel( 
                                br(),
                                br(),
                                h4(textOutput("pop_title_stackchart"), align="left"),
                                showOutput("pop_stackchart", lib="nvd3")
                              )
                       )   
                    )                   
                )
            )
      ),
      tabPanel("About",
        mainPanel(
          includeMarkdown("README.md")
       )
    )
  
  )
)