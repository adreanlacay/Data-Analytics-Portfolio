# Read .xlsx files of the data
library(readxl)
# For data manipulation and summaries
library(dplyr)
# Create plots for background information
library(ggplot2)
# Randomly split data
library(caTools)
# Create correlation plots
library(corrplot)
# Create and assess random forest models
library(randomForest)

###### DATA EXTRACTION ######

# The types of pitches each pitcher throws and their speeds
pitch_speeds <- read_xlsx("Pitch Arsenals.xlsx")

# The stats of each pitcher's pitch
pitch_type_stats <- read_xlsx("Pitch Arsenal Stats/Pitch Type Stats.xlsx")
pitch_type_stats <- pitch_type_stats[, c(1:3, 6:8)]

# Their overall season stats
season_stats <- read_xlsx("season_stats.xlsx")
season_stats <- season_stats[, c(1, 2, 22, 25, 28)]

###### DATA MERGING & CLEANING ######

# Extract all pitcher who throw a 4-Seam fastball and their fastball stats
fb_stats <- subset(pitch_type_stats, `Pitch Type` == "4-Seamer")
# Inner join the stats of fastball pitchers with their average fastball speed
fb_stats <- merge(fb_stats, pitch_speeds, by = c("Pitcher ID", "Pitch Type"))
fb_stats <- fb_stats[, -c(2, 4, 6, 7)]
colnames(fb_stats)[3:4] <- c("fastball_usage", "fastball_speed")

# Extracts all pitchers who throw non-fastball pitches and every type of pitch
non_fb <- subset(pitch_type_stats, `Pitch Type` != "4-Seamer")
# Out of all pitchers who throw a pitch other than a fastball, this will 
# get their most used secondary pitch
secondary_stats <- non_fb %>% 
  group_by(`Player Name`) %>% 
  summarise(secondary_usage = max(`Pitch Usage`, na.rm=TRUE))
# Joins the pitchers and their most used secondary pitch with their stats and
# pitch speed
secondary_stats <- merge(secondary_stats, non_fb, 
                            by.x = c("Player Name", "secondary_usage"), 
                            by.y = c("Player Name", "Pitch Usage"))
secondary_stats <- merge(secondary_stats, 
                            pitch_speeds, 
                            by = c("Pitcher ID", "Pitch Type"))
secondary_stats <- secondary_stats[, -7]
colnames(secondary_stats)[2] <- "secondary_pitch"
# Factor each secondary pitch type
secondary_stats$secondary_pitch <- factor(secondary_stats$secondary_pitch)
colnames(secondary_stats)[5:7] <- c("secondary_thrown",
                                    "secondary_batters",
                                    "secondary_speed")

# Joins both fastball and secondary pitch stats
pitcher_stats <- merge(fb_stats, secondary_stats, by = "Pitcher ID")
pitcher_stats <- merge(pitcher_stats, season_stats, 
                       by.x = "Pitcher ID", by.y = "pitcher_id")
pitcher_stats <- pitcher_stats[, -c(6, 11)]
colnames(pitcher_stats)[2] <- c("pitcher_name")
pitcher_stats$pitcher_role <- factor(pitcher_stats$pitcher_role)
colnames(pitcher_stats)[1] <- "pitcher_id"

# Checks the counts of each secondary pitch
pitcher_stats %>% count(secondary_pitch)
pitcher_stats[pitcher_stats$secondary_pitch %in% c("Knuckleball", "Slurve"), 
              c(2, 5)]
# Since there is not enough data on pitchers with Knuckleballs and Slurves, we
# will remove those rows
pitcher_stats <- pitcher_stats %>% 
  filter(!(secondary_pitch %in% c("Knuckleball", "Slurve")))

# Find any duplicated pitchers
any(duplicated(pitcher_stats$pitcher_id))
pitcher_stats$pitcher_id[duplicated(pitcher_stats$pitcher_id)]
pitcher_stats[pitcher_stats$pitcher_id == 672582, c(2, 5:9)]

# Angel Zerpa threw the same amount of Sinkers and Sliders, but he faced more 
# batters with his Sinker, so we will remove his Slider row.
pitcher_stats <- pitcher_stats %>% 
  filter(!(pitcher_id == 672582 & secondary_pitch == "Slider"))
# No longer need batters faced and total thrown with secondary pitch
pitcher_stats <- pitcher_stats[, -(7:8)]

###### PITCHER SUCCESS: FIP ~ SPEED + ARSENAL COUNT ######

# Gets the total number of pitch types from each pitcher
arsenal_count <- pitch_speeds %>% group_by(`Pitcher ID`) %>% count()
arsenal_count <- as.data.frame(arsenal_count)
colnames(arsenal_count)[2] <- "pitch_type_total"

# Merge the pitcher's stats with their pitch type count
pitcher_stats <- merge(pitcher_stats, arsenal_count, 
                       by.x = "pitcher_id", by.y = "Pitcher ID")

# Total number of pitchers per arsenal count
pitcher_stats %>% group_by(pitch_type_total) %>% count()

# Categorize each pitcher by their arsenal count
pitcher_stats$arsenal_count_category <- c()
for (i in 1:nrow(pitcher_stats)) {
  if (pitcher_stats$pitch_type_total[i] < 4) {
    pitcher_stats$arsenal_count_category[i] <- "Under 4 Pitches"
  } else if (pitcher_stats$pitch_type_total[i] > 5) {
    pitcher_stats$arsenal_count_category[i] <- "Over 5 Pitches"
  } else {
    pitcher_stats$arsenal_count_category[i] <- 
      paste(pitcher_stats$pitch_type_total[i], "Pitches")
  }
}
pitcher_stats$arsenal_count_category <- 
  factor(pitcher_stats$arsenal_count_category)
# Changes order of factors by definition of category
pitcher_stats$arsenal_count_category <- 
  relevel(pitcher_stats$arsenal_count_category, ref = "Under 4 Pitches")

# Plot of a pitcher's fastball speed and FIP
ggplot(pitcher_stats, aes(x = fastball_speed, y = fip)) +
  geom_point(aes(color = "#F69219"), show.legend = FALSE) +
  labs(x = "Fastball Speed (mph)", y = "FIP")

# Plot of a pitcher's fastball speed and FIP, but divided by arsenal count
ggplot(pitcher_stats, aes(x = fastball_speed, y = fip)) +
  geom_point(aes(color = arsenal_count_category), show.legend = FALSE) +
  facet_wrap(vars(arsenal_count_category)) +
  labs(x = "Fastball Speed (mph)", y = "FIP")

# FIP vs. secondary pitch speed
ggplot(pitcher_stats, aes(x = secondary_speed, y = fip)) +
  geom_point(aes(color = secondary_pitch), show.legend = FALSE) +
  facet_wrap(vars(secondary_pitch)) +
  labs(x = "Secondary Pitch Speed (mph)", y = "FIP") +
  guides(color = guide_legend(title = "Secondary Pitch"))
# FIP vs. secondary pitch speed, by arsenal count category
ggplot(pitcher_stats, aes(x = secondary_speed, y = fip)) +
  geom_point(aes(color = arsenal_count_category), show.legend = FALSE) +
  facet_wrap(vars(arsenal_count_category)) +
  labs(x = "Secondary Pitch Speed (mph)", y = "FIP")

# Linear regression model of FIP against a pitcher's fastball speed and arsenal
# count.
fip_fb <- lm(fip ~ fastball_speed + arsenal_count_category, pitcher_stats)
summary(fip_fb)
# 95% confidence intervals of the model's coefficients to determine if a mean
# of 0 exists.
confint(fip_fb)


# Fitting regression model of FIP against a pitcher's secondary pitch speed and 
# arsenal count.
fip_secondary <- lm(fip ~ (secondary_speed * secondary_pitch) + 
                      arsenal_count_category, pitcher_stats)
summary(fip_secondary)
# Confidence interval test of the model's coefficients to determine if a mean
# of 0 exists.
confint(fip_secondary)


###### PITCHING EFFECTIVENESS: WHIFF ~ VELOCITY DIFFERENCE + ARSENAL ######

# Whiff vs. fastball speed plot
ggplot(pitcher_stats, aes(x = fastball_speed, y = whiff_pct)) +
  geom_point()

# Whiff vs. secondary pitch speed plot
ggplot(pitcher_stats, aes(x = secondary_speed, y = whiff_pct)) +
  geom_point(aes(color = secondary_pitch), show.legend = FALSE) + 
  facet_wrap(vars(secondary_pitch))

# Velocity difference between fastball and secondary pitch
pitcher_stats$velo_diff <- 
  pitcher_stats$fastball_speed - pitcher_stats$secondary_speed
summary(pitcher_stats$velo_diff)
# Cases where their secondary pitch is faster than their fastball
pitcher_stats[which(pitcher_stats$velo_diff < 0),  c(2, 4, 7, 13, 5)]

# Need to train the model, so we can randomly split 70% of the data for
# training and the remaining 30% will be used to test our model
set.seed(111)
sample_data <- sample.split(pitcher_stats$whiff_pct, SplitRatio = 0.7)
train_data <- subset(pitcher_stats, sample_data == TRUE)
test_data <- subset(pitcher_stats, sample_data == FALSE)

# Training model to predict whiff from velocity difference
whiff_velo_diff <- lm(whiff_pct ~ velo_diff, train_data)
# Coefficient estimates of the model
summary(whiff_velo_diff)$coefficients
# Confidence interval test of the coefficients
confint(whiff_velo_diff)

# Predict the whiff rates using the testing data and compare the predictions 
# with the actual results
whiff_predict <- predict(whiff_velo_diff, test_data)
test_results <- as.data.frame(cbind(whiff_predict, test_data$whiff_pct))
colnames(test_results) <- c("predictions", "actual")

# Calculate the R-Squared value to compare the fit of the predictions to the
# actual whiff rates in the test data
sse = sum((test_results$prediction - test_results$actual)^2)
sst = sum((mean(pitcher_stats$whiff_pct) - test_results$actual)^2)
r_squared = 1 - sse/sst

# Correlation plot of whiff, velocity difference, secondary pitch speed and
# fastball speed
whiff_cor <- cor(pitcher_stats[, c("whiff_pct", "velo_diff", 
                                   "secondary_speed", "fastball_speed")])
corrplot(whiff_cor, method = "color", 
         type = "lower", tl.col = "black",
         addCoef.col = "black", diag = FALSE)

# New training model with secondary pitch speed 
whiff_velo_second <- lm(whiff_pct ~ (velo_diff * secondary_speed), 
                        train_data)
# Coefficient estimates of the new model
summary(whiff_velo_second)$coefficients
# Confidence interval test of the new model
confint(whiff_velo_second)

# New predictions based on the new model
whiff_predict_new <- predict(whiff_velo_second, test_data)
test_results_new <- as.data.frame(cbind(whiff_predict_new, 
                                        test_data$whiff_pct))
colnames(test_results_new) <- c("predictions", "actual")

# R-Squared value to check fit of new predictions to actual whiff rates
sse_new = sum((test_results_new$prediction - test_results_new$actual)^2)
sst_new = sum((mean(pitcher_stats$whiff_pct) - test_results_new$actual)^2)
r_squared_new = 1 - sse_new/sst_new


###### ROLE CATEGORIZATION: PITCHER ROLE ~ PITCH USAGE + ARSENAL COUNT ######

# Percentage of relievers and starters
starter_pct <- pitcher_stats %>% 
  count(pitcher_role) %>% 
  mutate(proportion = n/nrow(pitcher_stats)) %>%
  arrange(desc(pitcher_role))
# Pie chart illustrating the proportion of relievers and starters
ggplot(starter_pct, aes(x = "", y = proportion, fill = pitcher_role)) +
  geom_bar(stat = "identity", width = 1, show.legend = FALSE, color = "white") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = c("#E6482F", "#2230D3")) +
  geom_text(aes(y = proportion / 2 + 
                  c(0, cumsum(proportion)[-length(proportion)]), 
                label = paste(pitcher_role, "\n", round(proportion * 100), "%"), 
                size = 10), color = "white", show.legend = FALSE) +
  theme_void()

# Histogram of fastball usage by pitcher role
ggplot(pitcher_stats) +
  geom_histogram(aes(x = fastball_usage, fill = pitcher_role),
                 color = "black", show.legend = FALSE) +
  scale_fill_manual(values = c("#E6482F", "#2230D3")) +
  facet_wrap(vars(pitcher_role), nr = 2) +
  labs(x = "Fastball Usage (%)", y = "Number of Pitchers")
# Count and percentage of pitchers with a fastball usage >= 50%
over_50 <- pitcher_stats %>% 
            group_by(pitcher_role) %>% 
            count(fastball_usage >= 50) %>% 
            mutate(pct = ifelse(pitcher_role == "Reliever", n/sum(n), n/sum(n)))

# Plot of fastball vs. secondary pitch usage by pitcher role
ggplot(pitcher_stats, aes(x = fastball_usage, y = secondary_usage)) +
  geom_point(aes(color = pitcher_role)) +
  scale_color_manual(values = c("#E6482F", "#2230D3")) +
  labs(x = "Fastball Usage (%)", y = "Secondary Pitch Usage (%)") +
  guides(color = guide_legend(title = "Pitcher Role"))

# Random forest using a model of only pitch usage as predictors for a pitcher's
# role
role_usage <- randomForest(pitcher_role ~ secondary_usage + fastball_usage,
                            data = train_data, importance = TRUE)
# Predict the roles with the model using the test data
usage_predict <- predict(role_usage, test_data)
# Confusion matrix of the prediction results and actual data
usage_results <- table(usage_predict, test_data$pitcher_role)
# Classification errors of each pitching role
reliever_err <- round(usage_results[1,2] / sum(usage_results[1,]) * 100, 2)
starter_err <- round(usage_results[2,1] / sum(usage_results[2,]) * 100, 2)
class_error <- c(reliever_err, starter_err)
usage_results <- as.data.frame(cbind(usage_results, class_error))
colnames(usage_results)[3] <- "Class. Error"

# Bar graph of pitcher arsenal count by pitcher roles.
ggplot(pitcher_stats, aes(x = arsenal_count_category, fill = pitcher_role)) +
  geom_bar(position = "dodge") +
  geom_text(stat = "count", aes(label = after_stat(count)),
            position = position_dodge(width = 0.9), hjust = 0.5, vjust = -0.5) +
  scale_fill_manual(values = c("#E6482F", "#2230D3")) +
  labs(x = "Arsenal Count", y = "") +
  guides(fill = guide_legend(title = "Pitcher Role"))
# Count and percentage of pitchers throwing more than five pitches.
over_5_pitches <- pitcher_stats %>% 
                    group_by(pitcher_role) %>% 
                    count(pitch_type_total >= 5) %>% 
                    mutate(pct = ifelse(pitcher_role == "Reliever", 
                                        round((n/sum(n)) * 100, 1), 
                                        round((n/sum(n)) * 100, 1)))
  
# Random forest model combining both usage and arsenal count.
role_usage_arsenal <- randomForest(pitcher_role ~ fastball_usage + 
                                     secondary_usage +
                                     arsenal_count_category, 
                                   data = train_data,
                                   importance = TRUE)
# Predict roles with new model
usage_arsenal_predict <- predict(role_usage_arsenal, test_data)
# Confusion matrix of the test results
usage_arsenal_results <- table(usage_arsenal_predict, test_data$pitcher_role)
# Classification errors of each pitching role
reliever_err <- usage_arsenal_results[1,2] / sum(usage_arsenal_results[1,])
starter_err <- usage_arsenal_results[2,1] / sum(usage_arsenal_results[2,])
class_error <- c(reliever_err, starter_err)
usage_arsenal_results <- as.data.frame(cbind(usage_arsenal_results, 
                                             class_error))
usage_arsenal_results$class_error <- round(usage_arsenal_results$class_error * 
                                             100, 2)
colnames(usage_arsenal_results)[3] <- "Class. Error"

