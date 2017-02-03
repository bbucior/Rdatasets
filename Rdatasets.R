library(R2HTML)
library(dplyr)

# Settings
EXPORT_DATA = FALSE
# BASE_URL = "https://raw.github.com/vincentarelbundock/Rdatasets/master"
BASE_URL = "."  # Could also update the URL to my gh-pages
ROW_MIN = 20  # Specs from ChE 395 syllabus
COL_MIN = 10

packages = c("datasets", "boot", "KMsurv", "robustbase", "car", "cluster", "COUNT", "Ecdat", "gap", "ggplot2", "HistData", "lattice", "MASS", "plm", "plyr", "pscl", "reshape2", "rpart", "sandwich", "sem",  "survival", "vcd", "Zelig", "HSAUR", "psych", "quantreg", "geepack", "texmex", "multgee", "evir", "lme4", "mosaicData", "ISLR","Stat2Data")
# Installed only packages that are not pre-installed.
# Credits: http://stackoverflow.com/a/9345167/756986
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.rstudio.com")
index = data(package=packages)$results[,c(1,3,4)]
index = data.frame(index, stringsAsFactors=FALSE)
index_out = NULL
size_out = NULL

# Load packages which store datasets
for (i in packages) {
        library(i, character.only=TRUE)
}

# Save datasets
for (i in 1:nrow(index)) {
    dataset = index$Item[i]
    package = index$Package[i]
    # Load data in new environment (very hackish)
    e = new.env(hash = TRUE, parent = parent.frame(), size = 29L)
    cmd = paste('data(', dataset, ', envir=e)', sep='')
    eval(parse(text=cmd))
    d = e[[dataset]]
    if(class(d) %in% c('data.frame', 'matrix', 'numeric', 'table', 'ts')){
        cat("Processing data set: ", dataset, "\n")
        if(class(d)=='ts'){
            d = data.frame(time(d), d)
            colnames(d) = c('time', dataset)
        }
        try(dir.create(paste('csv/', package, sep='')))
        try(dir.create(paste('doc/', package, sep='')))
        dest_csv = paste('csv/', package, '/', dataset, '.csv', sep='')
        dest_doc = paste('doc/', package, '/', dataset, '.html', sep='')
        if (EXPORT_DATA) {
          # Save data as CSV
          write.csv(d, dest_csv)
          # Save documentation as HTML
          help.ref = help(eval(dataset), package=eval(package))
          help.file = utils:::.getHelpFile(help.ref)
          tools::Rd2HTML(help.file, out=dest_doc)
        }
        # Add entry to index out
        index_out = rbind(index_out, index[i,])
        # Add entry to dimensions out
        size_d = dim(d)
        if (is.null(size_d)) size_d = c(length(d), 1)  # numeric vector
        size_out = rbind(size_out, data.frame(Rows=size_d[1], Cols=size_d[2]))
    }
}

# Size details
index_out = cbind(index_out, size_out)

# Filter based on dimensions required for the project
index_out %>% filter(Rows >= ROW_MIN) %>% filter(Cols >= COL_MIN) -> index_out

# CSV index
index_out$csv = paste(BASE_URL, '/csv/',
                      index_out$Package, '/', index_out$Item, '.csv', sep='')
index_out$doc = paste(BASE_URL, '/doc/',
                      index_out$Package, '/', index_out$Item, '.html', sep='')
write.csv(index_out, file='datasets.csv', row.names=FALSE)

# HTML index
index_out$csv = paste("<a href='", index_out$csv, "'> CSV </a>", sep='')
index_out$doc = paste("<a href='", index_out$doc, "'> DOC </a>", sep='')
unlink('datasets.html')
rss = '
<style type="text/css">
  tr:nth-child(even){
          background-color: #E5E7E5;
  }
</style>
<h1>Dataset options</h1>
<p>(selected with at least 10 variables and 20 instances.  Other comments can go here.)</p>
'
cat(rss, file='datasets.html')
HTML(index_out, file='datasets.html', row.names=FALSE, append=TRUE)

