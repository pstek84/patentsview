## PatentsView Location with Geocoder (Pelias)

#.. preamble
setwd('~/patentsview') #Set working directory
library(RMySQL); dbname <- 'patentsview'; username <- 'user'; password <- 'password'; host <- 'localhost'
dl_url <- 'https://s3.amazonaws.com/data.patentsview.org/download/' #Set generic URL with PatentsView data

#.. download
tname <- 'location' #File name
download.file(paste0(dl_url, tname, '.tsv.zip'), paste0(fname, '.tsv.zip')) #Download file
unzip(paste0(fname, '.zip')) #Unzip

#.. load data and amend table
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
#dbListTables(con)
#dbRemoveTable(con, 'location')
dbSendQuery(con, 'CREATE TABLE location (id VARCHAR(128), city VARCHAR(128), state VARCHAR(2), country VARCHAR(2), latitude FLOAT, longitude FLOAT, county VARCHAR(60), state_fips VARCHAR(2), county_fips VARCHAR(6));')
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/location.tsv"  INTO TABLE location FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbSendQuery(con, 'ALTER TABLE location ADD COLUMN lat2 FLOAT,
            ADD COLUMN lon2 FLOAT,
            ADD COLUMN name VARCHAR(128),
            ADD COLUMN placetype VARCHAR(20),
            ADD COLUMN population INT,
            ADD COLUMN country2 VARCHAR(3);')
dbDisconnect(con); remove(con)

#.. geocoding
library(jsonlite)
gc_url <- 'http://localhost:3000/parser/search?text=' #URL for geocoding via Pelias, see: https://geocode.earth/blog/2019/almost-one-line-coarse-geocoding/
# "Turn on" in CMD: docker run -d -p 3000:3000 -v $(pwd)/data:/data pelias/placeholder

con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
ids <- dbFetch(dbSendQuery(con, 'SELECT id FROM location;'), n= -1) #select id list
for(n in ids$id){ #start with ids, use ids2 if crashed
  line <- dbFetch(dbSendQuery(con, paste0('SELECT * FROM location WHERE id = "', n, '"' )))
  
  adr_query <- ifelse(line$state == '', paste(line$city, line$country, sep= ", "),
                      paste(line$city, line$state, line$country, sep= ", "))
  print(adr_query)
  adr_sr <- as.data.frame(fromJSON(paste0(gc_url, URLencode(adr_query)), flatten= T))[1,]
  if(ncol(adr_sr) == 0){ next }
  adr_sr$population <- ifelse(is.null(adr_sr$population), 0, adr_sr$population)
  adr_sr$population <- ifelse(is.na(adr_sr$population), 0, adr_sr$population)
  dbSendQuery(con, paste0('UPDATE location SET 
              lat2 = ', adr_sr$geom.lat, ', 
              lon2 = ', adr_sr$geom.lon, ', 
              name = "', adr_sr$name, '", 
              placetype = "', adr_sr$placetype,'", 
              population = ', adr_sr$population, ', 
              country2 = "', adr_sr$lineage[[1]]$country.abbr, '" 
              WHERE id = "', n, '";'))
}
#check <- dbReadTable(con, 'location')
#which(ids$id == n) #on crash, check which ID
#ids2 <- as.data.frame(ids[which(ids$id == n):nrow(ids),]); names(ids2) <- 'id' #on crash, shorten ids list
dbDisconnect(con); remove(con)

#.. add indexes
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
dbSendQuery(con, 'CREATE INDEX id ON location (id);')
dbSendQuery(con, 'CREATE INDEX country ON location (country);')
dbDisconnect(con); remove(con)



