#.libPaths("~/R_libs")
library(caret)
library(dplyr)
library(randomForest)
library(readr)

## Fitting RF models to predict attack or benign and sublabels

#### Importing dataset and processing it
DF_around_attack = read.csv("processed_df_label.csv")

# Turning all the characters into factors 
DF_around_attack = DF_around_attack%>%mutate(across(where(is.character),as.factor))
DF_around_attack$label = as.factor(DF_around_attack$label) 

# separating data set into Training & Testing (75% training, 25% testing)
train_id = createDataPartition(DF_around_attack$label, p = 0.75, list = FALSE)

Test_d = DF_around_attack[-train_id,]
Train_d = DF_around_attack[train_id,]

# Using cross validation with 10 folds, with testing tuning parameters of 2,3,4,5
k = 10
trainControl = trainControl(method = "cv", number = k)
tuneGrid = expand.grid('mtry' = c(2,3,4,5))

# Fitting model now
rf_mod_full_d = train(label~.-subLabel, data = Train_d , method = "rf", trControl = trainControl, tuneGrid = tuneGrid)
# looking at the best tuning parameter mtry.
rf_mod_full_d$bestTune

# Finding accuracy...
prediction = predict(rf_mod_full_d, Test_d)
mean(prediction==Test_d$label)

# HOWEVER
# since there are too many benigns, we should use other metrics than accuracy. Let's calculate recall
recall <- sum(prediction == 1 & Test_d$label == 1) / sum(prediction == 1)
recall
# 97.21116 % of the attacks were sucessfully identified as an attack!

# Plotting variable importance plot
plot(rf_mod_full_d)
plot(varImp(rf_mod_full_d))

################### fitting model again using only top 25 predictors
importance <- varImp(rf_mod_full_d)  # Get variable importance
importance_df <- importance$importance  # Extract importance data frame

top_25_features = importance_df%>%arrange(desc(Overall))%>%head(25)%>%rownames()

# Actually we are going to remove IP addresses since if we do, this method, or model, will only work for the
# data when there is same IP address in the data set.
feature_dropping_Destination <- top_25_features[!grepl("IP", top_25_features)]

# Fitting RF model again with reduced features
rf_mod_reduced_d = train(
  as.formula(paste("label ~", paste(feature_dropping_Destination, collapse=" + "))),
  data = Train_d ,
  method = "rf",
  tuneGrid = tuneGrid, 
  trControl = trainControl)

# Finding best tuning parameter again of mtry
rf_mod_reduced_d$bestTune

# Predicting and finding recall
prediction = predict(rf_mod_reduced_d, Test_d)
recall <- sum(prediction == 1 & Test_d$label == 1) / sum(prediction == 1)
recall

# getting top 25 predictors of reduced rf model 
importance <- varImp(rf_mod_reduced_d)  # Get variable importance
importance_df <- importance$importance  # Extract importance data frame

top_25_features = importance_df%>%arrange(desc(Overall))%>%head(25)%>%rownames()
top_25_features
plot(importance)


################## Fitting RF model to predict sublabel

# creating data partition for training and testing data(75% for training, 25% for testing)
train_id = createDataPartition(DF_around_attack$subLabel, p = 0.75, list = FALSE)

Test_d = DF_around_attack[-train_id,]
Train_d = DF_around_attack[train_id,]

# Fitting Random Forest model to predict sublabel with training data
rf_mod_full_sublabel = train(subLabel~.-label, data = Train_d , method = "rf", trControl = trainControl, tuneGrid = tuneGrid)

# Finding best tuning parameter again of mtry
rf_mod_full_sublabel$bestTune

importance <- varImp(rf_mod_full_sublabel)  # Get variable importance
importance_df <- importance$importance  # Extract importance data frame

# getting rid of columns with IP addresses for same reason from above and picking top 25 important features
top_25_features_sublabel_1 = importance_df%>%arrange(desc(Overall))%>%head(29)%>%rownames()
top_25_features_sublabel_1
plot(importance)

# Making prediction and getting performance
prediction = predict(rf_mod_full_sublabel, Test_d)
conf_matrix <- confusionMatrix(prediction, Test_d$subLabel, positive = "1")


# Class-wise recall (Sensitivity)
recall_per_class <- conf_matrix$byClass[, "Sensitivity"]
print(recall_per_class)

# Macro-average recall (mean of class-wise recall)
macro_recall <- mean(recall_per_class, na.rm = TRUE)
print(macro_recall)


############### Fitting Rndom Forest model for sublabel with only top 25 important features

# getting top 25 important features
top_25_features_sublabel_1 = top_25_features_sublabel_1[!grepl("IP", top_25_features_sublabel_1)]

# Fitting model...
rf_mod_reduced_sublabel = train(
  as.formula(paste("subLabel ~", paste(top_25_features_sublabel_1, collapse=" + "))),
  data = Train_d ,
  method = "rf",
  tuneGrid = tuneGrid, 
  trControl = trainControl)

# printing out the best tune parameter
rf_mod_reduced_sublabel$bestTune

# prediction and getting performance
prediction = predict(rf_mod_reduced_sublabel, Test_d)
conf_matrix <- confusionMatrix(prediction, Test_d$subLabel)

plot(varImp(rf_mod_reduced_sublabel))

tibble()

# Class-wise recall (Recall)
recall_per_class <- mean(conf_matrix$byClass[, "Sensitivity"])
specificity = mean(conf_matrix$byClass[,"Specificity"])
F1_score = mean(conf_matrix$byClass[,"F1"])
accuracy = length(which(prediction==Test_d$subLabel))/nrow(Test_d)

print(recall_per_class)

X = c("Recall","Specificity","F1_score","Accuracy")
Scores = c(recall_per_class, specificity, F1_score, accuracy)
Recall_df = data.frame(Type_of_measurement = X, Scores = Scores)
ggplot(aes(x = Type_of_measurement), data = Recall_df) + geom_bar(col = "skyblue", alpha = 0.9) + theme_minimal() 

# Macro-average recall (mean of class-wise recall)
macro_recall <- mean(recall_per_class, na.rm = TRUE)
print(macro_recall)


# saving model
saveRDS(rf_mod_reduced_sublabel, "/Users/brianpark/Desktop/Data competition/2024/rf_mod_reduced_sublabel.rds")
