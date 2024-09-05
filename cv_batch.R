library(disaggregation)
library(sf)
library(terra)
library(modelr) # splitting data
library(Metrics) # evaluate results
library(glue) # fstrings

response <- st_read("mdg_shapes.shp")

# ISO3 code for the response data
country_code <- "MDG"

covariates <- rast(glue("{country_code}_stack.tif"))

aggregation <- covariates$Worldpop
covariates$Worldpop <- NULL

covariates <- terra::scale(covariates)

names(covariates) <- gsub(" ", "_", names(covariates))

n_groups <- 5
n_reps <- 5
start_seed <- 123

# Get the task ID from the environment variables
task_id <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))

# Convert task_id to loop indices
r <- ((task_id - 1) %% n_groups) + 1   # Outer loop index (1 to 5)

set.seed(start_seed * r)

for (n in 1:n_groups){

  # Split data into 5 training / testing datasets
  cv  <- crossv_kfold(response, k = n_groups)

  set.seed((start_seed * r)  + n)

  train <- cv$train[[n]]$data[cv$train[[n]]$idx,]

  cov_train <- crop(covariates, train, mask = TRUE)
  agg_train <- crop(aggregation, train, mask = TRUE)

  prep <- prepare_data(train, cov_train, agg_train, id_var = "ID_2", response_var = "inc", na_action = TRUE, make_mesh = TRUE)
  fit <- disag_model(prep, family = "poisson", link = "log")
  pred <- predict_model(fit, predict_iid = TRUE, new_data = covariates)
  # generate prediction intervals at 80 % credible interval
  uncertain <- predict_uncertainty(fit, new_data = covariates, predict_iid = TRUE, CI = 0.8)
  cases <- pred$prediction * aggregation
  lower_cases <- uncertain$predictions_ci$`lower CI` * aggregation
  upper_cases <- uncertain$predictions_ci$`upper CI` * aggregation
  agg_cases <- cbind(extract(lower_cases, response, fun = "sum", ID = FALSE, na.rm = TRUE),
                     extract(cases, response, fun = "sum", na.rm = TRUE),
                     extract(upper_cases, response, fun = "sum", ID = FALSE, na.rm = TRUE))
  agg_cases$rep <- r

  test_index <- cv$test[[n]]$idx
  test_result <- agg_cases[test_index,]

  saveRDS(fit, glue("{country_code}_r{r}_n{n}_model.rds"))
  write.csv(test_result, glue("{country_code}_r{r}_n{n}_results.csv"))
}
