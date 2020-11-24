# Automated Keyword Extraction of Data Analyst Job Descriptions from Indeed using NLP

### Introduction 

I was a business analyst and I have been thinking about how we can make a better business decision based on the data. In 2019, I started my masters in data and computational science. Then in September 2020, my job-seeking journey started. 

In reviewing various job descriptions of a data analyst from LinkedIn, Indeed and Glassdoor; 
I found myself questioning about: 

>***"how many years of experience that I need?"***

>***"what is the KEYWORDS of the job summaries?***

In order to answer these questions, I used natural language processing (NLP) techniques and GloVe Algorithm to analyze the keywords in job summaries/description (I will use both interchangeably) for a data analyst. 

### About the Data Set
We will **get** the datas set from Indeed. I decided to use Indeed because it has a straight-forward structure and it is the best job search website in Ireland.

You can check this link: <https://www.betterteam.com/job-posting-sites-ireland> for 2020 version. 

*How we Get the Data Set from Indeed?*

We will do a simple scrape with *rvest* library with R. 
This is the preview of my first indeed page:

![](./image/indeed_summ.JPG)

Okay, here is the section where we should tailoring the url. Since, I am looking for the data analyst position in Ireland, I used ie.indeed and "Data analyst" keyword which gave me this link:<https://ie.indeed.com/jobs?q=Data+Analyst> as my first page result. 

**Step 1.** My first page link

**Step 2.** After installing selector gadget, it will show up on your chrome addins

**Step 3.** Selecting the area that you want

**Step 4.** Copy the ".summary" for your html_nodes code.

Full technical explanation is inside the R code. 

The whole project in brief, I detected the pattern on indeed's link pages, scraped all of the informations, stored the them onto a data frame and grouped the data with Dublin location since I have an interest to analyze the job summaries in Dublin, Ireland.  I also plotted the years of experience for the numeric values in the scraped job summaries. Finally, I transformed the corpus by removing stopwords, punctuation, and numbers, and converted it to lowercase as the preprocessing process before I applied GloVe Algorithm into the data set. 

## Exploratory Data Analysis & Preprocessing

I will use the a basic NLP technique (bag of words) that constructs features based on term/word (I will use both interchangeably) frequencies. I made use of these features to train the classifier given a collection of texts, known as a *corpus*. 

To answer the first question **"how many years of experience that I need?"**, we will see how the years of experience were distributed in Dublin data set. Most of the time, the summary will list the number of years of experience desired. I scraped the websites on October and November 2020.

![](./image/yearsofexp.JPG)

From the plots, it is clear that the number of job postings are decreasing since the companies are slowing down by the end of year. But most of data analyst positions need the candidates with two or three years of experience. The distributions of Oct and Nov are both skewed left distributions. 

Now, let's see the top 10 most frequent words from November Data Set:

![](./image/count10.JPG)

Word "data" on the first place follows by "experience", if we accumulate all words contain "analy" we will have it on the second place. Which make senses since this is a job description for "data analyst" position. We can ignore "will" and we can conclude that based on the frequent words: **to become a data analyst, you should have experience**.

Let's take a look about the company. Based on the data, the top three companies are recruitment agencies in Ireland. 
The companies listed below have many job listings with word "data" in it. 
![](./image/companycount.JPG)

### Bag of Words Visualization

Before proceeding to classification, I visualized term frequencies and associations. First, I produced word clouds that depicted the 200 most frequent terms weighted by their frequency.

**Wordcloud of October Data Set**
<p align="center">
<img src="./image/wordcloudoct.JPG"/>
</p>

**Wordcloud of November Data Set**
![](./image/wordcloud.gif)

**Data** and **analyst** were the most frequent terms in the overall corpus of both data set. We notice that some of the terms represent stemmed versions of proper English words (i.e. **experi** instead of **experience**). We can see a similar visualization of both wordclouds. 

### Vectorization of Job Summary Corpus using GloVe Algorithm
The *bag-of-words* approach has a pitfall, it is a quick but dirty scheme to capture the keywords available. It does not always capture the meaning in the appropriate context. That is the main reason that I applied the GloVe algorithm into the job summary corpus, examining both single terms and also pair of consecutive terms (uni and bi-grams). 
The example of unigram is "analyst" while the example of bigram is "data_analyst". We will explore more about them in this section. 

This is the job summary corpus based on October data set. 

![](./image/oct.jpg)

There are 135 terms and we have more technical terms in the job summary based on November data set compare to the previous data set.

![](./image/nov.jpg)

The plots below show the similarity analysis for both data set. 

![](./image/BA_DA_OCT.JPG)

![](./image/BA_DA.JPG)

### Plot GloVe Word Vectors using Multidimensional Scaling

Plot a vector with 100 dimensions would not be informative, thus we used Multidimensional Scaling (MDS) to ease the interpretation. MDS seeks to preserve the distance between vectors. Since vector distances within GloVe encode some semantic meaning, it would be ideal to preserve the relative term topology. We applied MDS with Euclidean distances between these word vectors.  

![](./image/oct.jpg)

![](./image/nov.jpg)

***What we got from the visualization?***

1. 

I expected terms close to each other in this reduced vector space to be semantically similar, meaning they are commonly found within the same context and are transposable within the corpus. There are some clear and evident trends from this figure:

1.  The terms seem to be stratified primarily by frequency. 
- Higher frequency terms are more separated and isolated. These terms be placed within the multidimensional space in a location that depicts its distinct meaning. 
- Low frequency terms tend to aggregate around each other, often overlapping to show how close they are. These terms cannot be determined as precisely, so their encodings tended to settle closely to each other without much differentiation. 

## Conclusions

> Semantic distinction is a function of term frequency. 

GloVe provides a distributed word representation model that learns context iteratively. Terms that are synonymous with each other within corpora can be easily identified and targeted for further analysis. GloVe trains relatively fast on small data set, so I could scale the algorithm to larger corpora that takes advantage of more nuanced job descriptions. MDS can reveal groupings of words into broader subject areas that highlight the inherent disparities of word embeddings. I would look to expand this analysis to peripherally related jobs, like data scientist and data engineer. Possible extensions include topic modeling, document summarization, and possibly, resume matching with prospective job descriptions.  
