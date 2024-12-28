
# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(corrplot)
library(igraph)
library(skimr)
library(caret)
library(randomForest)
library(ggplot2)
library(tidyr)
library(ggthemes)
library(cluster)
library(factoextra)
library(reshape2)
###############
#UNSUPERVISED LEARNING
###############

data <- read.csv("C:/Users/Takreem/Downloads/Data Mining and Machine Learning/Data_DMML.csv")

#Removing Outliers from MeanWordCount
IQR <- IQR(data$MeanWordCount, na.rm = TRUE)
Q1 <- quantile(data$MeanWordCount, 0.25, na.rm = TRUE)
Q3 <- quantile(data$MeanWordCount, 0.75, na.rm = TRUE)
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR
outliers <- data$MeanWordCount < lower_bound | data$MeanWordCount > upper_bound
data <- data[!outliers, ]

data_2 <- data %>%  select(-c(ID, AccountAge)) %>%   scale()

#ELbow Test
fviz_nbclust(data_2, kmeans, method = "wss")+ labs(subtitle = "Elbow method")

#Silhouette test
fviz_nbclust(data_2, kmeans, method = "silhouette")+ labs(subtitle = "Silhouette method")

# Scaling the data using Z-score
data_scaled <- scale(data_2)

# Perform K-means clustering with the selected number of clusters
set.seed(123)
kmeans_result <- kmeans(data_scaled, centers = 2, nstart = 50)

# View results
print(kmeans_result)

# Adding cluster assignments back to the original data
data_clean$cluster <- kmeans_result$cluster

# Summarizing and visualizing clusters
cluster_summary <- data_clean %>%
  group_by(cluster) %>%
  summarise_all(mean, na.rm = TRUE)

view(cluster_summary)

# Assuming 'kmeans_result' is your K-means result
centers <- as.data.frame(kmeans_result$centers)

# Adding a cluster column for labeling
centers$cluster <- as.factor(1:nrow(centers))

# Melting the data frame for use with ggplot
centers_melted <- melt(centers, id.vars = "cluster")

# Rename the columns for clarity
colnames(centers_melted) <- c("cluster", "variable", "value")

# Plotting
ggplot(centers_melted, aes(x = reorder(variable, value), y = value)) +
  geom_bar(aes(fill = value > 0), width = 0.8, stat = "identity") +
  facet_wrap(~ cluster, nrow = 1, scales = "free_y") +
  coord_flip() +
  theme_bw() +
  theme(panel.border = element_rect(colour = "black", fill = NA),
        legend.position = "none") +
  labs(x = NULL, y = "Center Value") +
  ggtitle("Cluster Centers Reordered by Variable Value")

a = fviz_cluster(km.res, df, 
                 ellipse.type = "convex",
                 geom=c("point"), 
                 palette = "jco", 
                 main = "non-scaled",
                 ggtheme = theme_classic()) 
