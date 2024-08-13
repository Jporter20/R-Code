#clear workspace
rm(list = ls())



#clear memory
gc(reset = TRUE)



library(gridExtra); library(grid)
library(openxlsx); library(reshape2); library(dplyr); library(RMySQL); library(lubridate)
library(yaml)
library(mailR)
library(ggplot2); library(DT); library(data.table); library(RCurl); library(stringr)



source("~/r-tools/connect.r")
# source("~/aff-daily-run/db2_connect.R")
con = db_connect()
con_db2 = db2_connect()

# start the query
note <- qry2("select DISTINCT hl.HCUST AS customer_id
              	-- , jhllhjlk
              	  ,  hl.HACCT AS account_seq
              	 -- ,  hl.HDATE AS noteDate 
              	 -- ,  trim(hn.NLINE) AS note
              FROM KWHNOTE hn
              INNER JOIN KWHLOAN hl
              ON hn.HDATE = hl.HDATE
              	AND hn.HSEQ = hl.HSEQ
              WHERE (hn.NLINE LIKE '%lost job%' OR hn.NLINE LIKE '%unemployed%')
              	AND hn.HDATE > CURDATE() - 3 MONTH")

#write to the table
dbWriteTable(con, "unemployment_note", note, overwrite = TRUE, row.names = FALSE)
stmt("CREATE INDEX ca ON unemployment_note (customer_id, account_seq)")



