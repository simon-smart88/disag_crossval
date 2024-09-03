library(glue)
library(Metrics)

country_code <- "MDG"

out <- data.frame()

result_files <- list.files(path = "~/crossval",
                           pattern = glue("^{country_code}.*results\\.csv$"),
                           full.names = TRUE)

for (f in result_files){
  df <- read.csv(f)
  out <- rbind(out, df)
}

write.csv(out, "MDG_results_combined.csv")