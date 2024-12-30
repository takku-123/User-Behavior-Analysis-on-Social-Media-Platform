# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(corrplot)
library(igraph)
library(skimr)
library(caret)
library(class)
library(randomForest)
library(ggplot2)
library(tidyr)
library(ggthemes)
library(cluster)
library(factoextra)
library(reshape2)
library(caTools)


###############
#DATA EXPLOARATION AND VISUALLIZATION
###############

#UNDERSTANDING THE DATA: A QUICK OVERVIEW

# Load the dataset
data <- read.csv("C:/Users/hp/Downloads/Data_DMML.csv")

#Check for data structure
str(data)

# Display summary statistics
summary(data)

# Check for missing values
sum(is.na(data))

#Outlier Detection
skim(data)

#DATA VISUALIZATION
  
par(mar = c(4, 5, 4, 2) + 0.1, cex.axis = 0.4, cex.main = 0.8) # Adjust margin and text sizes

data_long <- pivot_longer(
  data = data %>% select(-ID),  # exclude ID here
  cols = where(is.numeric),
  names_to = "Variable",
  values_to = "Value"
)

p <- ggplot(data_long, aes(x = Variable, y = Value)) +
  geom_boxplot(
    fill = "skyblue",       # Box fill color
    color = "navy",         # Box outline color
    outlier.color = "navy"  # Outlier point color
  ) +
  theme_minimal(base_size = 12) +
  theme(
    # Axis text
    axis.text.x = element_text(
      angle = 90, vjust = 0.5, hjust = 1,
      size = 10, color = "black"
    ),
    axis.text.y = element_text(size = 10, color = "black"),
    
    # Axis labels
    axis.title.x = element_text(size = 12, face = "bold", color = "black"),
    axis.title.y = element_text(size = 12, face = "bold", color = "black"),
    
    # Plot title
    plot.title = element_text(
      size = 14, face = "bold", color = "black", hjust = 0.5
    ),
    
    # Backgrounds
    panel.background = element_rect(fill = "white"),
    plot.background  = element_rect(fill = "white"),
    
    # Grids
    panel.grid.major = element_line(color = "white"),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "Boxplots for the Dataset",
    x = NULL,  # remove x-axis label if variables are already on x
    y = "Value"
  )

print(p)


#Histograms
# Arrange plots in 1 row and 3 columns
par(mfrow = c(1, 3), cex.main = 1.5,  # Controls title text size
    cex.lab = 1.5,   # Controls axis label text size
    cex.axis = 1.2   # Controls axis tick mark text size
)

# Histogram for Total Posts
hist(data$TotalPosts,
     main = "Distribution of Total Posts",
     xlab = "Total Posts",
     col = "steelblue")

# Histogram for Mean Word Count
hist(data$MeanWordCount,
     main = "Distribution of Mean Word Count",
     xlab = "Mean Word Count",
     col = "dodgerblue")

# Histogram for Account Age
hist(data$AccountAge,
     main = "Distribution of Account Age",
     xlab = "Account Age",
     col = "royalblue")


# Correlation matrix to see relationships between variables
correlation_matrix <- cor(data[,sapply(data, is.numeric)])
print(correlation_matrix)
# Heatmap of the correlation matrix
corrplot(correlation_matrix, method = "circle",  type = "upper",               
         order = "hclust",             # Cluster the variables
         tl.col = "black",             # Set text label color to black
         tl.srt = 90,                  # Rotate text labels
         tl.cex = 0.6,                 # Text label size (cex = 0.6 is smaller)
         number.cex = 0.8,
         cl.cex = 0.4)

#Active vs Passive Users
# Define active users as those above 75th percentile in TotalPosts
active_users <- subset(data, TotalPosts > quantile(TotalPosts, 0.75))
passive_users <- subset(data, TotalPosts <= quantile(TotalPosts, 0.75))

# Calculate the 75th percentile of TotalPosts once and store it
posts_75th_quantile <- quantile(data$TotalPosts, 0.75)

# Create a new variable in 'data' for user activity level based on the 75th percentile
data$IsActive <- data$TotalPosts > posts_75th_quantile

# Plotting the data
ggplot(data, aes(x = AccountAge, y = TotalPosts, color = IsActive)) +
  geom_point() +
  scale_color_manual(values = c("blue", "skyblue"), labels = c("Passive", "Active")) +
  labs(title = "User Activity over Account Age",
       x = "Account Age (Months)",
       y = "Total Posts",
       color = "User Activity") +
  theme_minimal()

#Impact of Word Count on Engagement
# Scatter plot for MeanWordCount vs LikeRate
ggplot(data, aes(x = MeanWordCount, y = LikeRate)) +
  geom_point(aes(color = AccountAge)) +
  scale_color_gradient(low = "blue", high = "skyblue") +
  labs(title = "Impact of Word Count on Engagement", x = "Mean Word Count", y = "Like Rate")+
theme_minimal()

# Visualization
ggplot(data, aes(x = InitiationRatio, y = MeanPostsPerThread)) +
  geom_point(aes(color = AccountAge)) +
  labs(title = "Thread Initiation vs. Participation", x = "Initiation Ratio", y = "Mean Posts Per Thread")+theme_minimal()

#######################################################
#UNSUPERVISED MODEL
#######################################################


#Removing Outliers
ggplot(data, aes(y = data$MeanWordCount)) + 
  geom_boxplot() +
  labs(title = "Boxplot of Mean Word Count", y = "Mean Word Count")
IQR <- IQR(data$MeanWordCount, na.rm = TRUE)
Q1 <- quantile(data$MeanWordCount, 0.25, na.rm = TRUE)
Q3 <- quantile(data$MeanWordCount, 0.75, na.rm = TRUE)
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR
outliers <- data$MeanWordCount < lower_bound | data$MeanWordCount > upper_bound
data <- data[!outliers, ]
# Boxplot after removing outliers
ggplot(data, aes(y = MeanWordCount)) + 
  geom_boxplot() +
  labs(title = "Boxplot of Mean Word Count After Removing Outliers", y = "Mean Word Count")

data$ContentEngagementScore <- with(data, InDegree + OutDegree + TotalPosts + MeanWordCount + PercentQuestions + PercentURLs)
data$ActiveContributionIndex <- with(data, OutDegree / max(InDegree, 1))  # Avoid division by zero
data$DiversityIndex <- with(data, MeanPostsPerThread + MeanPostsPerSubForum)
data$InitiationFrequency <- with(data, InitiationRatio * TotalPosts)
data$InteractionRatio <- with(data, LikeRate + PercBiNeighbours)

data_features <- data[, c("ContentEngagementScore", "ActiveContributionIndex", "DiversityIndex", 
                          "InitiationFrequency", "InteractionRatio")]

set.seed(123)

data_scaled <- scale(data_features)
data_scaled

#ELbow Test
fviz_nbclust(data_scaled, kmeans, method = "wss")+ labs(subtitle = "Elbow method")

#Silhouette test
fviz_nbclust(data_features, kmeans, method = "silhouette")+ labs(subtitle = "Silhouette method")

# Perform K-means clustering with the selected number of clusters

wss <- function(k) {
  kmeans_result <- kmeans(data_scaled, centers = k, nstart = 150)
  return (kmeans_result$tot.withinss) }
wss_values <- sapply(2:8, wss)
optimal_clusters <- which.min(wss_values)
min_wss_value <- min(wss_values)
  
cat("The optimal number of clusters is", optimal_clusters, "with a WSS score of", min_wss_value, "\n")

final_kmeans <- kmeans(data_scaled, centers = 7, nstart = 100)

plot_clusters <- fviz_cluster(final_kmeans, data = data_scaled,
                              palette = "jco", geom = "point",
                              ellipse = TRUE, main = "Cluster Plot with K-means Clustering")
print(plot_clusters)


# >>> CLUSTER PLOT (Blue palette) <<<
# Below is a custom set of blues (feel free to change or reorder)
blue_palette <- c("#c6dbef", "#9ecae1", "#6baed6", 
                  "#4292c6", "#2171b5", "#08519c", "#08306b")

plot_clusters <- fviz_cluster(final_kmeans, 
                              data = data_scaled,
                              palette = blue_palette,  # all blues
                              geom = "point",
                              ellipse = TRUE,
                              main = "Cluster Plot (All Blue)") +
  theme_minimal(base_size = 12)

print(plot_clusters)

data_with_clusters <- as.data.frame(data_scaled)
data_with_clusters$cluster <- as.factor(final_kmeans$cluster)
cluster_summary <- data_with_clusters %>%
  group_by(cluster) %>%
  summarise_all(mean, na.rm = TRUE)
view(cluster_summary)

#Look at the size of the clusters
print(final_kmeans$size)

final_kmeans

#Look at the cluster centers
print(final_kmeans$centers)
final_kmeans$iter

#Apply the cluster IDs to the original data frame
data$cluster <- final_kmeans$cluster

table(data$cluster)

# Convert cluster centers to a data frame and add a cluster column
centers_df <- as.data.frame(final_kmeans$centers)
centers_df$cluster <- as.factor(1:nrow(centers_df))

# Melting the data
centers_melted <- melt(centers_df, id.vars = "cluster")

# Renaming the variables to shorter names for better visualization
centers_melted$variable <- factor(centers_melted$variable, labels = c("Engagement", "Contribution", "Diversity", "Initiation", "Interaction"))

# Create the bar graph using ggplot
ggplot(centers_melted, aes(x = variable, y = value, fill = cluster)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.75)) +
  theme_minimal() +
  labs(y = "Mean Value", x = "Feature", fill = "Cluster") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),  # Rotate the x-axis labels for readability
        legend.position = "bottom") +
  coord_flip()  # Flip coordinates to make horizontal bar graph

# Calculate silhouette information
social_media_sil <- silhouette(final_kmeans$cluster, dist(data_scaled))

# Visualize silhouette plot
fviz_silhouette(social_media_sil) + 
  labs(subtitle = "Silhouette Analysis") +
  theme_minimal() +
  ylim(-0.1, 0.4)

#######################################################
#SUPERVISED MODEL
#######################################################

# Splitting the dataset into training and testing sets with a 70:30 ratio
split <- sample.split(data, SplitRatio = 0.7)

# Subset the data into training and testing sets based on the split
train_cl <- subset(data, split == TRUE)
test_cl <- subset(data, split == FALSE)

train_features <- train_cl[, -which(names(data) == "cluster")]
test_features <- test_cl[, -which(names(data) == "cluster")]

train_scale <- scale(train_features)
test_scale <- scale(test_features)
k_value= 39
classifier_knn <- knn(train = train_scale,
                      test = test_scale,
                      cl = train_cl$cluster,
                      k = k_value)

# Viewing the classifier results
classifier_knn

print(nrow(train_scale))
print(length(train_cl$cluster))

# Ensure factor levels match, especially if the clustering produced factor levels
test_cl$cluster <- factor(test_cl$cluster, levels = unique(train_cl$cluster))

# Create the confusion matrix
conf_mat <- confusionMatrix(as.factor(classifier_knn), test_cl$cluster)

# Print the confusion matrix
print(conf_mat)



