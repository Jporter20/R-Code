#clear workspace
rm(list = ls())

#clear memory
gc(reset = TRUE)

library(gridExtra); library(grid)
library(openxlsx); library(reshape2); library(dplyr); library(RMySQL); library(lubridate)
library(yaml); library(jsonlite)
library(mailR); library(sqldf)
library(ggplot2); library(DT); library(data.table); library(RCurl); library(stringr)


source("~/r-tools/connect.r")

con = db_connect()
con_db2 = db2_connect()

###########################################################################################
sms_tran <- qry("SELECT sms_log.sent_date, COUNT(*) AS total_inbound_volume,
          count(outbound_date_time) as total_responded_to,
          MAX(outbound_date_time) AS maximum_response,
          -- SEC_TO_TIME(MAX(TIME_TO_SEC(difference))) AS maximum_response,
          SEC_TO_TIME(AVG(TIME_TO_SEC(difference))) AS avg_response_time
FROM (SELECT DISTINCT als.sent_date, als.source_number, 
                        CONCAT(als.sent_date, ' ', als.sent_time) as inbound_date_time, 
                        CONCAT(outb.sent_date, ' ', outb.sent_time) as outbound_date_time,
                        CASE WHEN CONCAT(als.sent_date, ' ', als.sent_time) >= CONCAT(outb.sent_date, ' ', outb.sent_time) THEN ABS(TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)))
                             WHEN CONCAT(outb.sent_date, ' ', outb.sent_time) >= CONCAT(als.sent_date, ' ', als.sent_time) THEN ABS(TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)))
                        ELSE ' '
                        END as difference,
                        -- TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)) as difference,  
                        als.message_text as inbound_message_text, outb.message_text
       FROM AFF.a_livevox_sms als
       LEFT JOIN
              (SELECT *
              FROM AFF.a_livevox_sms
              WHERE sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
              AND HOUR(sent_time) between 8 and 19
              AND source_number = '99788'
              AND message_text Not Like '%amfir%'
              AND message_text Not Like '%bit.ly%'
              AND message_text Not Like '%844%'
              and message_text Not Like '%Sorry we are closed%'
              GROUP BY destination_number, sent_date ORDER BY destination_number, sent_date, sent_time) outb 
       on als.source_number = outb.destination_number
        and als.sent_date = outb.sent_date
       WHERE als.sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
       AND HOUR(als.sent_time) between 8 and 19
       AND als.destination_number = '99788'
       AND als.message_text Not Like '%amfir%'
       AND als.message_text Not Like '%bit.ly%'
       AND als.message_text Not Like '%844%'
       and als.message_text Not Like '%Sorry we are closed%'
       GROUP BY als.sent_date, als.source_number) sms_log
    GROUP BY sms_log.sent_date
                ")


hourly_interval <- qry("SELECT sms_log.sent_date, HOUR(sms_log.sent_time) as HOUR, COUNT(*) AS total_inbound_volume,
          count(outbound_date_time) as total_responded_to,
          MAX(outbound_date_time) AS maximum_response,
          -- SEC_TO_TIME(MAX(TIME_TO_SEC(difference))) AS maximum_response,
          SEC_TO_TIME(AVG(TIME_TO_SEC(difference))) AS avg_response_time
FROM (SELECT DISTINCT als.sent_date, als.sent_time, als.source_number,
                        CONCAT(als.sent_date, ' ', als.sent_time) as inbound_date_time,
                        CONCAT(outb.sent_date, ' ', outb.sent_time) as outbound_date_time,
                        CASE WHEN CONCAT(als.sent_date, ' ', als.sent_time) >= CONCAT(outb.sent_date, ' ', outb.sent_time) THEN ABS(TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)))
                             WHEN CONCAT(outb.sent_date, ' ', outb.sent_time) >= CONCAT(als.sent_date, ' ', als.sent_time) THEN ABS(TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)))
                        ELSE ' '
                        END as difference,
                        -- TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)) as difference,
                        als.message_text as inbound_message_text, outb.message_text
       FROM AFF.a_livevox_sms als
       LEFT JOIN
              (SELECT *
              FROM AFF.a_livevox_sms
              WHERE sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
              AND HOUR(sent_time) between 8 and 19
              AND source_number = '99788'
              AND message_text Not Like '%amfir%'
              AND message_text Not Like '%bit.ly%'
              AND message_text Not Like '%844%'
              and message_text Not Like '%Sorry we are closed%'
              GROUP BY destination_number, sent_date ORDER BY destination_number, sent_date, sent_time) outb
       on als.source_number = outb.destination_number
        and als.sent_date = outb.sent_date
       WHERE als.sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
       AND HOUR(als.sent_time) between 8 and 19
       AND als.destination_number = '99788'
       AND als.message_text Not Like '%amfir%'
       AND als.message_text Not Like '%bit.ly%'
       AND als.message_text Not Like '%844%'
       and als.message_text Not Like '%Sorry we are closed%'
       GROUP BY als.sent_date, als.source_number) sms_log
    GROUP BY sms_log.sent_date, HOUR
                       ")


sms_details <- qry("SELECT DISTINCT als.source_number, als.loan_num,
                        CONCAT(als.sent_date, ' ', als.sent_time) as inbound_date_time,
                        CONCAT(outb.sent_date, ' ', outb.sent_time) as outbound_date_time,
                        CASE WHEN CONCAT(als.sent_date, ' ', als.sent_time) >= CONCAT(outb.sent_date, ' ', outb.sent_time) THEN TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time))
                             WHEN CONCAT(outb.sent_date, ' ', outb.sent_time) >= CONCAT(als.sent_date, ' ', als.sent_time) THEN TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time))
                        ELSE ' '
                        END as difference,
                        -- TIMEDIFF(CONCAT(outb.sent_date, ' ', outb.sent_time), CONCAT(als.sent_date, ' ', als.sent_time)) as difference,
                        als.message_text as inbound_message_text, outb.message_text
       FROM AFF.a_livevox_sms als
       LEFT JOIN
              (SELECT *
              FROM AFF.a_livevox_sms
              WHERE sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
              -- AND HOUR(sent_time) between 8 and 19
              AND source_number = '99788'
              AND message_text Not Like '%amfir%'
              AND message_text Not Like '%bit.ly%'
              AND message_text Not Like '%844%'
              and message_text Not Like '%Sorry we are closed%'
              GROUP BY destination_number, sent_date ORDER BY destination_number, sent_date, sent_time) outb
       on als.source_number = outb.destination_number
        and als.sent_date = outb.sent_date
       WHERE als.sent_date BETWEEN DATE_FORMAT(SUBDATE(CURDATE(), 1), '%Y-%m-01') AND SUBDATE(CURDATE(), 1)
       -- AND HOUR(als.sent_time) between 8 and 19
       AND als.destination_number = '99788'
       AND als.message_text Not Like '%amfir%'
       AND als.message_text Not Like '%bit.ly%'
       AND als.message_text Not Like '%844%'
       and als.message_text Not Like '%Sorry we are closed%'
       GROUP BY als.source_number
                   ")




############################################################################################

hs = createStyle(textDecoration = "BOLD", fontColour = "#FFFFFF", fontSize = 12,
                 fontName = "Arial Narrow", fgFill = "#4F80BD")

wb = createWorkbook()

addWorksheet(wb, "MTD SMS transactions")
addWorksheet(wb, "Hourly SMS transactions")
addWorksheet(wb, "SMS transactions Details")

writeDataTable(wb, 1, sms_tran)
writeDataTable(wb, 2, hourly_interval)
writeDataTable(wb, 3, sms_details)

setColWidths(wb, sheet = 1, cols = 1:ncol(sms_tran), widths = 'auto')
setColWidths(wb, sheet = 2, cols = 1:ncol(hourly_interval), widths = 'auto')
setColWidths(wb, sheet = 3, cols = 1:ncol(sms_details), widths = 'auto')

out_file <- paste0("~/aff-daily-run/xlsx/sms_transactions_", Sys.Date(), ".xlsx")

saveWorkbook(wb, out_file, overwrite = TRUE)


notification_email(getQuote()
                   , out_file
                   , c("mquiroz@americanfirstfinance.com", "mbeasley@americanfirstfinance.com", "sbrady@americanfirstfinance.com", "eescobedo@americanfirstfinance.com", "jporter@americanfirstfinance.com")   # c("fzhang@americanfirstfinance.com")
                   , paste0("SMS transactions ", Sys.Date()))
