library(randomForest)
library(caret)
library(dplyr)
library(ggplot2)

# 1. Load dataset
data <- read.csv("customer_churn.csv", stringsAsFactors = FALSE)

# 2. Create target variable
data$Churn <- factor(data$Churn.Label)
u
# 3. Drop leakage + useless columns
drop_cols <- c(
  "CustomerID", "Country", "State", "Count",
  "Lat.Long", "Latitude", "Longitude",
  "Churn.Label", "Churn.Value", "Churn.Score", "Churn.Reason"
)

data <- data[, !(names(data) %in% drop_cols)]

# 4. Label encode high-cardinality columns
data$City <- as.numeric(factor(data$City))
data$Zip.Code <- as.numeric(factor(data$Zip.Code))

# 5. Convert remaining character columns to factors
char_cols <- sapply(data, is.character)
data[, char_cols] <- lapply(data[, char_cols], factor)

# 6. Replace blanks with NA + remove NAs
data[data == ""] <- NA
data <- na.omit(data)

# 7. Train-test split
set.seed(123)
index <- createDataPartition(data$Churn, p = 0.7, list = FALSE)
train <- data[index, ]
test  <- data[-index, ]

# 8. Random Forest model
rf_model <- randomForest(
  Churn ~ .,
  data = train,
  ntree = 300,
  mtry = floor(sqrt(ncol(train) - 1)),
  importance = TRUE
)

# 9. Predictions + Confusion Matrix
rf_pred <- predict(rf_model, newdata = test)

rf_results <- confusionMatrix(
  factor(rf_pred, levels = levels(test$Churn)),
  test$Churn
)

print(rf_results)

# ---------------------------------------------------------
# 10. FEATURE IMPORTANCE BAR PLOT (WITH PRINT FIX)
# ---------------------------------------------------------

# Extract importance values
imp <- importance(rf_model)
importance_df <- as.data.frame(imp)

# Automatically pick last column (works for any version)
importance_df$Importance <- importance_df[, ncol(importance_df)]

# Add feature names
importance_df$Feature <- rownames(importance_df)

# Build plot object
importance_plot <- 
  ggplot(importance_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Random Forest Feature Importance",
    x = "Features",
    y = "Importance Score"
  ) +
  theme_minimal()

# PRINT PLOT (required when using source())
print(importance_plot)
