
options("scipen" = 999)
dir <- "~/workGit/coursera-developing-data-products/"
setwd(paste0(dir, "get-data/"))

# Set the library to download the files
require(RCurl)

# Dataset link
data.link <- "ftp://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Sinopse/Brasil/sinopse_brasil_tab_1_8.zip"

# Download it and unzip the data
dir.create("./data/urban-rural/", recursive = T)
download.file(data.link, "./data/sinopse_brasil_tab_1_8.zip", mode = "wb")
unzip("./data/sinopse_brasil_tab_1_8.zip", exdir = "./data/urban-rural")

# I decide to use the `tab1_8.xls`, which it is the sheet about the population estimation of Brazil's states.
require(readxl)
require(data.table)

# Get table, transform in data.table, exclude NULL rows
data = read_excel("./data/urban-rural/tab1_8.xls", col_names = F, skip = 12)
setDT(data)
names(data) <- c("state", "1960", "1970", "1980", "1991", "2000", "2010")
data <- na.exclude(data)

# Rearrange it to create a new column with Urban and Rural definitions
data.total <- copy(data[!state %in% c("Urbana", "Rural")])
states <- data.total[, state]
data.total[, "area" := "both"]

data.urban <- copy(data[state == "Urbana"])
setnames(data.urban, "state", "area")
data.urban[, "state" := states]

data.rural <- copy(data[state == "Rural"])
setnames(data.rural, "state", "area")
data.rural[, "state" := states]

census <- rbindlist(list(data.total, data.urban, data.rural), use.names = T)

# Let's check if the rearrangement is correct
for(i in census[, unique(state)]){
  aux <- census[state == i, .SD, .SDcols = 2:8]
  err <- (aux[area != "both", .SD, .SDcols = 1:6][, .(colSums(.SD))] != aux[area == "both", as.numeric(.SD), .SDcols = 1:6])
  ifelse(err > 0, {print(paste0("ERRORRRR in the state of ", i)); break()}, print(paste0("state of ", i, " is correct")))

}


# Adapt the names Urbana and Rural to english vocabulary
census[area == "Urbana", area := "urban"]
census[area == "Rural", area := "rural"]

# Exclude some macro-region names that are present in the data
census <- census[!state %in% c("Norte", "Nordeste", "Centro-Oeste", "Sudeste", "Sul")]

# Save the tidy data now
write.csv(census, file = "../shiny_app/data/census_population_by_area.csv", quote = T, row.names = F)

# Check if the data was saved correctly
require(data.table)
pop = fread("../shiny_app/data/census_population_by_area.csv")