## Only run examples in interactive R sessions
if (interactive()) {

    ui <- fluidPage(
        textInput("controller", "Controller"),
        textAreaInput("inText2", "Input textarea 2")
    )

    server <- function(input, output, session) {
        observe({
            # We'll use the input$controller variable multiple times, so save it as x
            # for convenience.
            x <- input$controller
            # Can also set the label, this time for input$inText2
            updateTextAreaInput(session, "inText2",
                                label = paste('"',x,'"'),
                                value = paste('"',x,'"'))
        })
    }

    shinyApp(ui, server)}
