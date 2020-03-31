# Setup ####
options(scipen = 10)

remotes::install_github("joachim-gassen/tidycovid19")

library(tidycovid19)
library(tidyverse)
library(lubridate)
library(zoo)
library(gganimate)
library(scales)

# Get & wrangle data ####
data <- download_jhu_csse_covid19_data()

data <- data %>% 
  mutate(week = week(date)) %>% 
  group_by(country, week) %>% 
  mutate(weekly_confirmed = last(confirmed)) %>% 
  ungroup() %>% 
  group_by(country) %>% 
  mutate(new_cases_week = case_when(week == lag(week) + 1 ~ weekly_confirmed - lag(weekly_confirmed),
                                    week == 4 ~ weekly_confirmed)) %>% 
  mutate(new_cases_week = na.locf(new_cases_week)) %>%
  mutate(new_cases = confirmed - lag(confirmed)) %>% 
  mutate(sum_last_7 = confirmed - lag(confirmed, 7)) %>% 
  ungroup()

# Create animated plots ###
# based on this video by Minute Physics: https://www.youtube.com/watch?v=54XLXg4fYsc

# select countries to include in the plots
countries= c("Italy", "Germany", "Korea, South", "US", "Iran", "China", "Japan")

# New confirmed cases in past seven days X Total confirmed cases
anim1 <- data %>%
  filter(country %in% countries,
         confirmed > 50,
         date >= "2020-01-28") %>%
  ggplot(aes(x = confirmed, y = sum_last_7, color = country)) + 
  geom_point() +
  geom_line() +
  geom_text(aes(label = country), hjust = 0) + 
  geom_text(aes(x = 100, y = 50000, label = date, fontface = "bold", size = 12)) +
  scale_y_log10() +
  scale_x_log10() +
  labs(title = 'Trajectory of COVID-19 Confirmed Cases',
       x = 'Total Confirmed Cases',
       y = 'New Confirmed Cases (in the Past 7 Days)') + 
  theme_minimal() +
  theme(legend.position = "none",
        plot.margin = margin(5.5, 40, 11, 11)) +
  transition_reveal(date) +
  coord_cartesian(clip = 'off')

day_range = max(data$date) - as_date("2020-01-28")

animation1 <- animate(anim1, nframes = as.numeric(day_range) + 1, fps = 1)

anim_save("./output/covid-19_trajectories_last7.gif", animation1)

# New confirmed cases per calendar week + Total confirmed cases
anim2 <- data %>%
  filter(country %in% countries,
         weekly_confirmed > 50) %>%
  ggplot(aes(x = weekly_confirmed, y = new_cases_week, color = country)) + 
  geom_point() +
  geom_line() +
  geom_text(aes(label = country), hjust = 0) + 
  geom_text(aes(x = 100, y = 50000, label = paste("Week", week), fontface = "bold", size = 12)) +
  scale_y_log10() +
  scale_x_log10() +
  labs(title = 'Trajectory of COVID-19 Confirmed Cases',
       x = 'Total Confirmed Cases',
       y = 'New Confirmed Cases (in the Past Week)') + 
  theme_minimal() +
  theme(legend.position = "none",
        plot.margin = margin(5.5, 40, 11, 11)) +
  transition_reveal(week) +
  coord_cartesian(clip = 'off')

week_range = max(data$week) - min(data$week)

animation2 <- animate(anim2, nframes = week_range + 1, fps = 1)

anim_save("./output/covid-19_trajectories_calweeks.gif", animation2)
