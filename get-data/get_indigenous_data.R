
options("scipen" = 999)
dir <- "~/workGit/coursera-developing-data-products/"
setwd(paste0(dir, "get-data/"))

# Set the library to download the files
require(RCurl)

# Dataset link
data.link <- "ftp://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Populacao_Indigena/tabelas_indigenas_XLS.zip"

# Download it and unzip the data
dir.create("./data/indigenous/", recursive = T)
download.file(data.link, "./data/tabelas_indigenas_XLS.zip", mode = "wb")
unzip("./data/tabelas_indigenas_XLS.zip", exdir = "./data/indigenous/")


require(data.table)
require(readxl)
# Read from the original source
indigenous <- read_excel("./data/indigenous/tabela1.xls", col_names = F, skip = 4, col_types = rep("text",13))

# I take only until the row 33th, the part that we are interested
indigenous <- indigenous[1:33, ]
Encoding(indigenous$X1) <- "UTF-8"

setDT(indigenous)

# Remove the space character in front of some strings from the worksheet
indigenous <- rbindlist(list(lapply(indigenous, 
                                    function(x) gsub(x, pattern = "^(\\s)*", replacement = "", perl = T))))

indigenous <- indigenous[!X1 %in% c("Total", "Norte", "Nordeste", "Centro-Oeste", "Sudeste", "Sul")]

# Change the '-' character by '0'
indigenous <- rbindlist(list(lapply(indigenous, 
                                    function(x) ifelse(x == "-", "0", x))))

# Allocate the referenced year's columns stacked by rows
indigenous <- rbindlist(list(copy(indigenous[, .SD, .SDcols = c(1, 2:5)])[, "year":="1991"], 
                             copy(indigenous[, .SD, .SDcols = c(1, 6:9)])[, "year":="2000"], 
                             copy(indigenous[, .SD, .SDcols = c(1, 10:13)])[, "year":="2010"]))

# Set new columns names
setnames(indigenous, c("state", "total", "non_indigenous", "indigenous", "non_declared", "year")) 

# Delete the '.' and what comes after, because on the worksheet they aren't a intenger number.
indigenous <- rbindlist(list(lapply(indigenous, 
                                    function(x) gsub(x, pattern = "\\.(\\w)*$", replacement = "", perl = T))))


# Transform the population quantity classes into numeric
indigenous[, total := as.numeric(total)]
indigenous[, indigenous := as.numeric(indigenous)]
indigenous[, non_declared := as.numeric(non_declared)]
indigenous[, non_indigenous := as.numeric(non_indigenous)]


write.csv(indigenous, file = "../shiny_app/data/brazil_indigenous_population.csv", quote = T, row.names = F)

# Check if the data is set correctly
require(data.table)
indigenous <- fread("../shiny_app/data/brazil_indigenous_population.csv")
