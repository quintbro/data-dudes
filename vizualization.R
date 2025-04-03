library(tidyverse)
library(arrow)
library(ggrepel)
library(lubridate)

setwd("~/data-dudes")

proc_dat <- read_feather("data/proc_dat.feather")
start_time <- min(proc_dat$minutes)

proc_dat = proc_dat %>%
  mutate(min_fstart = as.numeric(difftime(minutes, start_time, units = "mins")))

info <- read_csv("data/at_proccess.csv") %>%
  mutate(across(c(min, max), ~as.POSIXct(.x, origin = "1970-01-01", tz = "UTC")))%>%
  mutate(`Tactic Name` = str_to_title(`Tactic Name`)) %>%
  mutate(Tactic = as_factor(`Tactic Name`)) %>%
  mutate(across(c(min, max), ~as.numeric(difftime(.x, start_time, units = "mins"))))  %>%
  mutate(loc = (min + max)/2)

text_info <- info %>%
  filter(loc < 8117.850 | loc > 8256.333)

changepoint <- tibble(
  times = c(7829, 5718),
  name = c("Stopping Time", "Changepoint")
)

fit_plot <- ggplot(proc_dat) +
  #xlim(proc_dat$minutes[5000], proc_dat$minutes[9300]) +
  geom_rect(aes(xmin = min,
                xmax = max,
                fill = Tactic),
            ymin = -Inf,
            ymax = Inf,
            alpha = 0.5,
            data=info) +
  geom_text(aes(x = loc,
                label = Tactic),
            y = 130000000000,
            angle = 90,
            data = text_info,
            nudge_x = -30,
            check_overlap = T) +
  geom_line(aes(x = min_fstart, y = flow_idle_time))+
  geom_vline(aes(xintercept = times,
                 color = name),
             linetype = "dashed",
             data = changepoint) +
  scale_fill_brewer(palette = "Set1") +
  scale_color_manual(values = c("red", "blue")) +
  theme_minimal() +
  labs(
    title = "Sum of Flow Idle Time - Changepoint",
    x = "Minutes Since Experiment Began",
    y = "Flow Idle Time",
    caption = "*Due to size restraints, not all tactics are labeled on the plot directly",
    color = NULL
  )

ggsave("small_labels_plot.png", fit_plot)  



