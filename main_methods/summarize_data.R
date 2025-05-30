library(tidyverse)

net1 <- read_csv("data/phase1_NetworkData.csv") %>%
  mutate(direction = paste(`Source IP`, "->", `Destination IP`))%>%
  mutate(ts = floor(ts)) %>%
  select(ts:Header_Length,
         Duration:flow_active_time,
         label,
         direction) %>%
  group_by(ts, direction) %>%
  summarize(across(everything(), sum))

net2 <- read_csv("data/phase2_NetworkData.csv") %>%
  mutate(direction = paste(`Source IP`, "->", `Destination IP`))%>%
  mutate(ts = floor(ts)) %>%
  select(ts:Header_Length,
         Duration:flow_active_time,
         label,
         direction) %>%
  group_by(ts, direction) %>%
  summarize(across(everything(), sum))

saveRDS(net1, "data/sum_net1.rds")
saveRDS(net2, "data/sum_net2.rds")
