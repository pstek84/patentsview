## PatentsView Assignee with Triple Helix Classification

#.. download assignee zip
setwd('~/patentsview') #Set working directory
library(RMySQL); dbname <- 'dbname'; username <- 'username'; password <- 'password'; host <- 'localhost'
dl_url <- 'https://s3.amazonaws.com/data.patentsview.org/download/' #Set generic URL with PatentsView data

fname <- 'assignee.tsv' #File name
download.file(paste0(dl_url, fname, '.zip'), paste0(fname, '.zip')) #Download file
unzip(paste0(fname, '.zip')) #Unzip
data <- read.csv(fname, sep='\t')

#.. write to assignee table in database
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
#dbListTables(con)
#dbRemoveTable(con, 'location')
dbSendQuery(con, 'CREATE TABLE assignee (id VARCHAR(36), type INT(2), name_first VARCHAR(96), name_last VARCHAR(96), organization VARCHAR(256));')
dbSendQuery(con, 'CREATE INDEX id ON assignee (id);')
#dbSendQuery(con, 'SET GLOBAL local_infile=1;') #may have to do this as sudo user in MySQL command line
dbWriteTable(con, 'assignee', data, row.names= FALSE, overwrite= FALSE, append= TRUE)
#check <- dbReadTable(con, 'assignee')
dbDisconnect(con); remove(con)

#.. update assignee table structure (add columns)
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
dbSendQuery(con, 'ALTER TABLE assignee ADD COLUMN th VARCHAR(1);')
dbSendQuery(con, 'CREATE INDEX th ON assignee (th);')
dbDisconnect(con); remove(con)

#.. triple helix actor detection
#university-identifying word list from https://repository.tudelft.nl/islandora/object/uuid:7596fcac-cb22-40b2-8351-ca1138272445?collection=research
library(stringi)
uniwords <- c('ecole', 'polytechn', 'universit', 'hochschule', 'universid', 'institute of technology', 'school', 'college', 'georgia tech', 'academ', 'penn state', 'k.u. leuven', 'politec', 'higher education', 'univ.', 'rwth aachen', 'eth z', 'kitasato', 'institute of medical', 'k.u.leuven', 'cornell', 'purdue', 'institute for cancer', 'institute of cancer', 'acadaem', 'univerz', 'karlsruher institut', 'technion', 'cancer institut', 'des sciences appliq', 'alumni', 'educational fund', 'hoger onderwijs', 'postech', 'politechn', 'institute of science', 'virginia tech', 'eth-z', 'yeda research', 'hadasit', 'board of regents', 'instituto cientifico', 'ntnu technology', 'tudomanyegyetem', 'uceni technick', 'universt', 'alumini', 'suny', 'ucla', 'yliopisto', 'doshisha', 'insitute of technology', 'univsers', 'kaist', 'szkola', 'egyetem', 'univerc', 'skola', 'korkeakoulu', 'unversit', 'instituto superior')
uniwords <- paste(uniwords, collapse= '|')

con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
ids <- dbFetch(dbSendQuery(con, 'SELECT id FROM assignee;'), n= -1) #select id list

for(n in ids$id){
  line <- dbFetch(dbSendQuery(con, paste0('SELECT * FROM assignee WHERE id = "', n, '"' )))
  if(line$organization == ''){ next }
  
  print(line$organization)
  orgname <- tolower(stri_trans_general(str= line$organization, id = "Latin-ASCII")) #clean organization name  
  unicheck <- grepl(uniwords, orgname) & !grepl('universal', orgname) #check if it is a university, removes common 'universal' false-positive
  
  line$type <- ifelse(is.na(line$type), 0, line$type) #catch error with NA entry
  
  if(unicheck == TRUE){
    th <- 'U' #university
  } else if(line$type == 6 | line$type == 7 | line$type == 8 | line$type == 9 | line$type == 16 | line$type == 17 | line$type == 18 | line$type == 19) {
    th <- 'G' #government
  } else if(line$type == 2 | line$type == 3 | line$type == 12 | line$type == 13) {
    th <- 'I' #industry 
  } else {
    th <- 'X' #unknown
  }

  dbSendQuery(con, paste0('UPDATE assignee SET 
              th = "', th, '" 
              WHERE id = "', n, '";'))
}
#check <- dbReadTable(con, 'assignee')
dbDisconnect(con); remove(con)