# Load R packages
library(abind)
library(clustMixType)
library(dashboardthemes)
library(dplyr)
library(GGally)
library(plotly)
library(rcompanion)
library(rvest)     # web scraping
library(shiny)
library(shiny)
library(shinyalert)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyjs)
library(shinythemes)
library(shinyWidgets)
library(tidyverse) # clean and tidy the data
library(timeDate)
library(visNetwork)
library(wordcloud2)
library(xml2)      # read the html page

if (interactive()) {
    # Basic dashboard page template
    library(shiny)
    shinyApp(
        ui = dashboardPage(
            dashboardHeader(title = "AKEX"),
            dashboardSidebar(numericInput("end", "End Page", value = 100, min=100, max=1000, step = 100),
                             textInput("Initial_page", "Indeed Link"),
                             tags$small("you must use apost"), br(),
                             h1("you must use apost")),
            dashboardBody(tabsetPanel(
                tabPanel("Years of Experience",plotOutput("PLOTYEAR"),
                         splitLayout(tableOutput("headcompany"),
                                     tableOutput("headcount"))),
                tabPanel("Word Cloud Corpus",
                         splitLayout(textOutput("corpuscomplete"),
                                     wordcloud2Output("wordcloudfin"))),
                tabPanel("Similar Words", plotOutput("Similarwords"),
                         splitLayout(textOutput("x_value"))),
                tabPanel("MDS Plot",
                         splitLayout(plotlyOutput("glove_euc"), plotOutput("glove_cos"))))
                )),
        server = function(input, output,session) {
            observe({


            })


            library(extrafont)
            df <- read.csv("C:/Users/Eveline/Downloads/Portfolio/job-description-nlp-master/Automated-Keywords-Extraction-of-Data-Analyst-Job-Descriptions-from-Indeed-using-NLP/df_Dublin.csv")
            library(tm)
            df$job_description = tolower(df$job_description)
            # remove stop words
            df$job_description = removeWords(df$job_description, stopwords("english"))
            df$job_description = removePunctuation(df$job_description)
            df$job_description = removeNumbers(df$job_description)

            Colors <- function(n) {
                hues = seq(390, 850, length = n + 1)
                hcl(h = hues, l = 85, c = 70)[1:n]}

            plotYearsExp <- function(text){
                library(stringr)
                # Function to extract numbers from text
                numextract <- function(string){
                    str_extract(string, "\\-*\\d+\\.*\\d*")}
                # Extract numbers
                years = numextract(text)
                # Remove NAs
                years <- as.numeric(years[!is.na(years)])
                # Relevant limit of years
                years <- years[(years < 10) & (years %% 1 == 0) & (years >= 0)]
                # Colors selection
                colors = Colors(1)

                library(ggpubr)
                p <- gghistogram(data.frame(years),
                                 x = "years",
                                 fill = colors[1],
                                 color = colors[1],
                                 alpha=0.75,
                                 binwidth = 1,
                                 size=1.5, ylim=c(0,20))

                ggpar(p, xlab = "Years", ylab = "Frequency",
                      title = "Work Experience Suggested",
                      font.x = c(13,"bold"),
                      font.y = c(13,"bold"),
                      font.title = c(18,"bold"),
                      font.subtitle = 16,
                      font.family = "Arial",
                      font.tickslab = 12, xticks.by = 1,
                      orientation = c("vertical", "horizontal", "reverse"),
                      ggtheme = theme_pubr())+ font("title", hjust=0.5)

            }
            #Out1
            output$PLOTYEAR <- renderPlot(plotYearsExp(unlist(df)))
            library(dplyr)
            library(ggplot2)
            library(tidytext)

            # Counting tokens
            count = df %>%
                unnest_tokens(output = "word",
                              token = "words",
                              input = job_description) %>%
                count(word, sort = TRUE)

            #Out2
            output$headcount<- renderTable(head(count,10))

            #tidytext representation
            company_words <- df %>%
                unnest_tokens(output = "word", token = "words",
                              input = job_description) %>%
                anti_join(stop_words) %>%
                count(company_name, word, sort = TRUE)

            #Out3
            output$headcompany<- renderTable(head(company_words,10))


            preprocessing <- function(text){
                library(tm)
                # Create the toSpace content transformer
                toSpace <- content_transformer(function(x, pattern) {return (gsub(pattern," ", x))})
                # Perform necessary operations to corpus
                corpus <- Corpus(VectorSource(text))
                corpus <- tm_map(corpus, toSpace, "/")
                corpus <- tm_map(corpus, toSpace, "-")
                # Convert to lowercase
                corpus <- tm_map(corpus, content_transformer(tolower))
                # Remove punctuation
                corpus <- tm_map(corpus, removePunctuation)
                # Strip whitespace
                corpus <- tm_map(corpus, stripWhitespace)
                # Remove stopwords
                corpus <- tm_map(corpus, removeWords, stopwords("english"))
                # Remove numbers
                corpus <- tm_map(corpus, removeNumbers)
                # Stem the corpus
                corpus <- tm_map(corpus, stemDocument, "english")
                # Create document term matrix (dtm)
                dtm <- DocumentTermMatrix(corpus)
                # Removes terms with sparsity >=  99%
                dtm <- removeSparseTerms(dtm, 0.99)
            }

            # Load the job descriptions
            text.summary <- df$job_description
            # Create document-term matrices for the summaries
            dtm.summary <- preprocessing(text.summary)
            # Combine respective DTMs into collective matrix
            dtm <- c(dtm.summary)
            set.seed(1111)

            plotWordcloud <- function(dtm){
                m <- as.matrix(t(dtm))
                v <- sort(rowSums(m),decreasing = TRUE)
                d <- data.frame(word = names(v),freq=v)
                # Wordcloud of 200 most frequently used words
                library(wordcloud2)
                set.seed(123)
                wordcloud2(d)}

            #Out4
            output$wordcloudfin<- renderWordcloud2(plotWordcloud(dtm.summary))

            library(text2vec)
            # Use itoken to form vocabulary
            iteration = itoken(df$job_description,
                               preprocessor = tolower,
                               tokenizer = word_tokenizer)
            # We need uni and bi-grams
            vocab <- create_vocabulary(iteration, ngram = c(1L, 2L))
            vocab <- prune_vocabulary(vocab,
                                      # retain words whose frequencies > 15
                                      term_count_min = 15,
                                      doc_proportion_min = 0.001)
            # Vectorize the vocab
            vectorizer <- vocab_vectorizer(vocab)
            # Use window size of top for context words (captures most document lengths)
            tcm <- create_tcm(iteration, vectorizer, skip_grams_window = 10L)
            set.seed(123)
            # GloVe model
            glove <- GloVe$new(rank = 50, x_max = 10)
            main <- glove$fit_transform(tcm, n_iter = 50, verbose = FALSE)
            context <- glove$components
            # final combination
            complete <- t(main) + context

            corpus<-colnames(complete)

            #Out5
            output$corpuscomplete <- renderText(corpus)

            plotSimilarWords <- function(word1, word2, complete){
                colors = Colors(2)
                # Finds most similar terms given a target vector among all word vectors
                findSimilarWords <- function(word,word_vectors){
                    library(text2vec)
                    target = word_vectors[,word,drop=FALSE]
                    cos_sim = sim2(t(word_vectors),t(target),method='cosine',norm='l2')
                    similar = head(sort(cos_sim[,1], decreasing = TRUE), 11)
                    similar = similar[-1]
                }
                library(dplyr)
                library(tibble)
                query1 = data.frame(Similarity = findSimilarWords(word1,complete))
                query2 = data.frame(Similarity = findSimilarWords(word2,complete))
                query <- query1 %>%
                    rownames_to_column("Term") %>%
                    mutate(Selected = word1) %>%
                    bind_rows(query2 %>% rownames_to_column("Term") %>%
                                  mutate(Selected = word2)) %>%
                    group_by(Selected) %>%
                    arrange(Selected,desc(Similarity)) %>%
                    ungroup()
                head(query,10)
                plot1 <- ggdotchart(query[1:10,], x = "Term", y = "Similarity",
                                    shape = 18, dot.size = 8, color = colors[1],
                                    add = "segments", add.params = list(size=2),
                                    rotate = TRUE, sorting = "descending")
                parplot1 <- ggpar(plot1, title = paste("\"",word1,"\"",sep = ""),
                                  legend = "none", font.x = c(14,"bold"), font.y = c(14,"bold"),
                                  font.title = 16, font.family = "Arial",
                                  font.xtickslab = c(12), font.ytickslab = c(14),
                                  ggtheme = theme_bw())+ font("title",hjust=0.5) + rremove("xylab")
                plot2 <- ggdotchart(query[11:20,], x = "Term", y = "Similarity",
                                    shape = 18, dot.size = 8, color = colors[2],
                                    add = "segments", add.params = list(size=2),
                                    rotate = TRUE, sorting = "descending")
                parplot2 <- ggpar(plot2, title = paste("\"",word2,"\"",sep = ""),
                                  legend = "none", font.x = c(14,"bold"), font.y = c(14,"bold"),
                                  font.title = 16, font.family = "Arial",
                                  font.xtickslab = c(12), font.ytickslab = c(14),
                                  ggtheme = theme_bw())+ font("title",hjust=0.5)  + rremove("xylab")
                figure <- ggarrange(parplot1, parplot2, ncol = 2, labels = c("(A)","(B)"), label.x = 0.1)
                annotate_figure(figure,
                                top = text_grob(paste("Which word vectors are most similar to \"",
                                                      word1, "\" or \"", word2,"\"?", sep = ""),
                                                hjust = 0.5, family = "Arial",
                                                face = "bold", size = 18))
            }

            #Out6
            output$Similarwords<- renderPlot(plotSimilarWords("business_analyst","data_analyst",complete))

            # MDS with Euclidean distance
            set.seed(123)
            vectordata = dist(scale(t(complete)))
            mds.euc <- data.frame(cmdscale(vectordata))

            # Label each point with corresponding word and color according to frequency
            words <- colnames(complete)
            Freq_logtrans <- log10(vocab$term_count)

            plotGlove <- function(mdsout,words,Freq_logtrans,metric){
                colors = Colors(2)
                library(ggplot2)
                library(plotly)
                ggplot(mdsout, aes(x = X1, y = X2, size=14, color=Freq_logtrans)) +
                    geom_label(aes(label = words, fontface = "bold"))+
                    theme_bw()+
                    theme(axis.line = element_line(size=1, colour = "black"),
                          panel.grid.major = element_line(colour = "#d3d3d3"),
                          panel.grid.minor = element_blank(),
                          panel.border = element_blank(), panel.background = element_blank(),
                          plot.title = element_text(family="Arial", size = 18, face = "bold", hjust=0.5),
                          axis.text.x=element_text(colour="black", size = 12),
                          axis.text.y=element_text(colour="black", size = 12),
                          text=element_text(family="Arial", size = 10))+
                    guides(size=FALSE)+ geom_point(aes(text=words),size = Freq_logtrans)+
                    scale_color_gradient(low=colors[2],high=colors[1])+
                    labs(title=paste("MDS of Word Vectors (", metric, ")",sep=""))
            }

            output$glove_euc <- renderPlotly({
                print(
                    ggplotly(plotGlove(mds.euc,words,Freq_logtrans,"Euclidean Distance")))})

            #Out8
            # MDS with Cosine Distance
            set.seed(123)
            set.seed(123)
            vectordata = dist(scale(t(complete)))
            mds.euc <- data.frame(cmdscale(vectordata))

            # Label each point with corresponding word and color according to frequency
            words <- colnames(complete)
            Freq_logtrans <- log10(vocab$term_count)

            plotGloveC <- function(mdsout,words,Freq_logtrans,metric){
                colors = Colors(2)
                library(ggplot2)
                library(plotly)
                ggplot(mdsout, aes(x = X1, y = X2,size=14)) +
                    geom_label(aes(label = words, fill = Freq_logtrans, fontface = "bold"))+
                    theme_bw()+
                    theme(axis.line = element_line(size=1, colour = "black"),
                          panel.grid.major = element_line(colour = "#d3d3d3"),
                          panel.grid.minor = element_blank(),
                          panel.border = element_blank(), panel.background = element_blank(),
                          plot.title = element_text(family="Arial", size = 18, face = "bold", hjust=0.5),
                          plot.caption = element_text(family="Arial", size = 12, face ="bold", hjust=0.5),
                          axis.text.x=element_text(colour="black", size = 12),
                          axis.text.y=element_text(colour="black", size = 12),
                          text=element_text(family="Arial", size = 14))+
                    guides(size=FALSE)+
                    scale_fill_gradient(low=colors[2],high=colors[1])+
                    labs(title=paste("MDS of Word Vectors (", metric, ")",sep=""),
                         caption="*Based on the Indeed job summary corpus", fill="Frequency")
            }

            cosdata = 1-sim2(t(complete),t(complete),method="cosine",norm = "l2")
            mds.cos <- data.frame(cmdscale(cosdata))

            #Out9
            output$glove_cos<-renderPlot(plotGloveC(mds.cos,words,Freq_logtrans,"Cosine Distance"))



        }
    )
}
