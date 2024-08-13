#clear workspace
rm(list = ls())



#clear memory
gc(reset = TRUE)



library(gridExtra); library(grid)
library(openxlsx); library(reshape2); library(dplyr); library(RMySQL); library(lubridate)
library(yaml);
library(mailR)
library(ggplot2); library(DT); library(data.table); library(RCurl); library(stringr)



source("~/r-tools/connect.r")
# source("~/aff-daily-run/db2_connect.R")
con = db_connect()
con_db2 = db2_connect()


file_in <- read.xlsx("~/janeka/os_account_search/os_acct_search.xlsx") %>%
  mutate(loan_num = trimws(loan_num))


loan_num = paste0(file_in$loan_num, collapse = "','")




os_search <- qry2(paste0("SELECT
                             MFMTACCT as loan_num,
                             MXDATE AS charge_off_date,
                             MLDATE AS last_payment_date,
                             MLPMT AS last_payment_amt
                           FROM KWLBASE
                           WHERE MFMTACCT IN ('", loan_num, "')
                          ")) 



write.xlsx(os_search, "~/janeka/os_account_search/os_acct_search_out.xlsx")
