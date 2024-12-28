# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(corrplot)
library(igraph)
library(caret)
library(randomForest)


# Load the dataset
data <- read.csv("C:/Users/hp/Downloads/Data_DMML.csv")

# Display summary statistics
summary(data)

# Check for missing values
sum(is.na(data))

# Histograms for some of the numeric variables
hist(data$TotalPosts, main="Distribution of Total Posts", xlab="Total Posts")
hist(data$MeanWordCount, main="Distribution of Mean Word Count", xlab="Mean Word Count")
hist(data$AccountAge, main="Distribution of Account Age", xlab="Account Age")

# Boxplots for LikeRate and MeanPostsPerThread to see the distribution and outliers
boxplot(data$LikeRate, main="Boxplot of Like Rate", ylab="Like Rate")
boxplot(data$MeanPostsPerThread, main="Boxplot of Mean Posts Per Thread", ylab="Mean Posts Per Thread")

# Scatter plot to explore relationships between variables
plot(data$TotalPosts, data$LikeRate, main="Total Posts vs. Like Rate",
     xlab="Total Posts", ylab="Like Rate", pch=19)
plot(data$AccountAge, data$PercBiNeighbours, main="Account Age vs. Percentage of Bidirectional Neighbours",
     xlab="Account Age", ylab="PercBiNeighbours", pch=19)

# Correlation matrix to see relationships between variables
correlation_matrix <- cor(data[,sapply(data, is.numeric)])
print(correlation_matrix)

# Heatmap of the correlation matrix
library(corrplot)
corrplot(correlation_matrix, method = "circle")

#Active vs Passive Users
# Define active users as those above 75th percentile in TotalPosts
active_users <- subset(data, TotalPosts > quantile(TotalPosts, 0.75))
passive_users <- subset(data, TotalPosts <= quantile(TotalPosts, 0.75))

ggplot(data, aes(x = AccountAge, y = TotalPosts, color = TotalPosts > quantile(TotalPosts, 0.75))) +
  geom_point() +
  labs(title = "User Activity over Account Age", x = "Account Age (Months)", y = "Total Posts")

#Impact of Word Count on Engagement
# Scatter plot for MeanWordCount vs LikeRate
ggplot(data, aes(x = MeanWordCount, y = LikeRate)) +
  geom_point(aes(color = AccountAge)) +
  scale_color_gradient(low = "blue", high = "red") +
  labs(title = "Impact of Word Count on Engagement", x = "Mean Word Count", y = "Like Rate")

# Visualization
ggplot(data, aes(x = InitiationRatio, y = MeanPostsPerThread)) +
  geom_point(aes(color = AccountAge)) +
  labs(title = "Thread Initiation vs. Participation", x = "Initiation Ratio", y = "Mean Posts Per Thread")



