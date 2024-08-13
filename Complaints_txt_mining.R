# Install
install.packages("tm")  # for text mining
install.packages("SnowballC") # for text stemming
install.packages("wordcloud") # word-cloud generator 
install.packages("RColorBrewer") # color palettes

# Load
library("tm")
library("SnowballC")
library("wordcloud")
library("RColorBrewer")

source("~/r-tools/connect.r")
con = db_connect()
con_db2 = db2_connect()

#### pull in complaints data
complaints_descrip_data = qry("select category_value, description from complaints_report
                      where year(received_date) > 2019
                              and category_value IN ('Credit Bureau Reporting', 'Credit Reporting')")

##text <- readLines(complaints_descrip_data)

docs <- Corpus(VectorSource(complaints_descrip_data))

inspect(docs)

# Convert the text to lower case
docs <- tm_map(docs, content_transformer(tolower))

# Remove numbers
docs <- tm_map(docs, removeNumbers)

# Remove english common stopwords
docs <- tm_map(docs, removeWords, stopwords("english"))

# Remove your own stop word
# specify your stopwords as a character vector
#docs <- tm_map(docs, removeWords, c("blabla1", "blabla2")) 

# Remove punctuations
docs <- tm_map(docs, removePunctuation)

# Eliminate extra white spaces
docs <- tm_map(docs, stripWhitespace)

# get total of words
dtm <- TermDocumentMatrix(docs)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)
head(d, 10)

#wordcloud
set.seed(1234)
wordcloud(words = d$word, freq = d$freq, min.freq = 1,
          max.words=200, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))

#find associated words
findAssocs(dtm, terms = "reporting", corlimit = 0.3)
#head(d, 10)


#plot word frequencies
barplot(d[1:10,]$freq, las = 2, names.arg = d[1:10,]$word,
        col ="lightblue", main ="Most frequent words in Credit/ Credit Bureau Reporting Categories",
        ylab = "Word frequencies")
geom_text(aes(label=Number), position=position_dodge(width=0.9), vjust=-0.25)

     