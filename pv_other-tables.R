## PatentsView Other Tables

#.. preambles
setwd('~/patentsview') #Set working directory
library(RMySQL); dbname <- 'patentsview'; username <- 'user'; password <- 'password'; host <- 'localhost'
dl_url <- 'https://s3.amazonaws.com/data.patentsview.org/download/' #Set generic URL with PatentsView data

#.. download and unzip
#CMD: cd ~/patentsview
#CMD: wget https://s3.amazonaws.com/data.patentsview.org/download/application.tsv.zip
#CMD: unzip application.tsv.zip application.tsv
#CMD: wget https://s3.amazonaws.com/data.patentsview.org/download/cpc_current.tsv.zip
#CMD: unzip cpc_current.tsv.zip cpc_current.tsv
#CMD: wget https://s3.amazonaws.com/data.patentsview.org/download/uspatentcitation.tsv.zip
#CMD: unzip uspatentcitation.tsv.zip uspatentcitation.tsv
#CMD: wget https://s3.amazonaws.com/data.patentsview.org/download/patent_assignee.tsv.zip
#CMD: unzip patent_assignee.tsv.zip patent_assignee.tsv
#CMD: wget https://s3.amazonaws.com/data.patentsview.org/download/patent_inventor.tsv.zip
#CMD: unzip patent_inventor.tsv.zip patent_inventor.tsv

#.. create tables
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
dbSendQuery(con, 'CREATE TABLE application (id VARCHAR(36), patent_id VARCHAR(20), type VARCHAR(2), number VARCHAR(64), country VARCHAR(2), date DATE, series_code VARCHAR(2));')
dbSendQuery(con, 'CREATE TABLE cpc_current (uuid VARCHAR(36), patent_id VARCHAR(20), section_id VARCHAR(10), subsection_id VARCHAR(20), group_id VARCHAR(20), subgroup_id VARCHAR(20), category VARCHAR(36), sequence INT(11));')
dbSendQuery(con, 'CREATE TABLE uspatentcitation (uuid VARCHAR(36), patent_id VARCHAR(20), citation_id VARCHAR(20), date DATE, name VARCHAR(64), kind VARCHAR(2), country VARCHAR(2), category VARCHAR(64), sequence INT(11));')
dbSendQuery(con, 'CREATE TABLE patent_assignee (patent_id VARCHAR(20), assignee_id VARCHAR(36), location_id VARCHAR(128));')
dbSendQuery(con, 'CREATE TABLE patent_inventor (patent_id VARCHAR(20), inventor_id VARCHAR(36), location_id VARCHAR(128));')
dbDisconnect(con); remove(con)

#.. load tables
#MySQL/MariaDB in sudo may need: SET GLOBAL local_infile=1;
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/application.tsv"  INTO TABLE application FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/cpc_current.tsv"  INTO TABLE cpc_current FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/uspatentcitation.tsv"  INTO TABLE uspatentcitation FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/patent_assignee.tsv"  INTO TABLE patent_assignee FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbSendQuery(con, 'LOAD DATA LOCAL INFILE "/home/user/patentsview/patent_inventor.tsv"  INTO TABLE patent_inventor FIELDS TERMINATED BY "\t" ENCLOSED BY "\\"" LINES TERMINATED BY "\n" IGNORE 1 LINES;')
dbDisconnect(con); remove(con)

#.. create indexes
con <- dbConnect(RMySQL::MySQL(), dbname= dbname, username= username, password= password, host= host)
tname <- 'application'
dbSendQuery(con, paste0('CREATE INDEX id ON ', tname, ' (id);'))
dbSendQuery(con, paste0('CREATE INDEX patent_id ON ', tname, ' (patent_id);'))
dbSendQuery(con, paste0('CREATE INDEX number ON ', tname, ' (number);'))
dbSendQuery(con, paste0('CREATE INDEX date ON ', tname, ' (date);'))
tname <- 'cpc_current'
dbSendQuery(con, paste0('CREATE INDEX uuid ON ', tname, ' (uuid);'))
dbSendQuery(con, paste0('CREATE INDEX subgroup_id  ON ', tname, ' (subgroup_id);'))
tname <- 'uspatentcitation'
dbSendQuery(con, paste0('CREATE INDEX citation_id  ON ', tname, ' (citation_id);'))
tname <- 'patent_assignee'
dbSendQuery(con, paste0('CREATE INDEX patent_id  ON ', tname, ' (patent_id);'))
dbSendQuery(con, paste0('CREATE INDEX assignee_id  ON ', tname, ' (assignee_id);'))
dbSendQuery(con, paste0('CREATE INDEX location_id  ON ', tname, ' (location_id);'))
tname <- 'patent_inventor'
dbSendQuery(con, paste0('CREATE INDEX patent_id  ON ', tname, ' (patent_id);'))
dbSendQuery(con, paste0('CREATE INDEX location_id  ON ', tname, ' (location_id);'))
dbDisconnect(con); remove(con)

