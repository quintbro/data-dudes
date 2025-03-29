
from datetime import datetime
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import regex as re
import pyreadr

net1 = pyreadr.read_r("net1.rds")[None]
net2 = pyreadr.read_r("net2.rds")[None]

diff = net2.ts.min() - net1.ts.max()

# Transform the net1 timestamp so that phase 2 begins immediately after phase 1
net1["ts"] = net1["ts"] + diff

# Concatenate the two phases into 1 dataframe
orig_dat = pd.concat([net1, net2])

# Delete the old dataframes from memory
del net1, net2

# Create a List of all possible seconds in the experiment time frame
ts = pd.DataFrame({"ts" : range(orig_dat.ts.min().astype(int), orig_dat.ts.max().astype(int))})

# Loop through every direction and remove those that don't have enough data points
for i in orig_dat['direction'].unique():
    if i == "0 -> 0":
        continue
    tmp_dat = orig_dat[orig_dat['direction'] == i].drop("direction", axis = 1)

    # If there are less than 60 data points for a direction, do not add this to the data frame
    if tmp_dat.shape[0] < 60:
        continue
    
    # Create names that are a mix of the previous column value and the direction of the IP Addresses
    new_names = {old : old + ':' + dir for old, dir in zip(tmp_dat.drop("ts", axis = 1).columns, np.repeat(i, tmp_dat.shape[1] - 1))}
    tmp_dat.rename(columns = new_names, inplace=True)

    # Join the data with the old data frame to ensure that every second is accounted for
    ts = pd.merge(ts, tmp_dat, how="left", on="ts").fillna(0)

# Create a human readable datetime variable so that it is possible to aggregate by minutes
orig_dat["minutes"] = orig_dat["ts"] \
    .apply(lambda x : datetime.fromtimestamp(x)) \
    .apply(lambda x : x.strftime("%Y-%m-%d %H:%M")) # format it so that it doesn't include seconds

# Find the columns that contain the label
label_cols = [i for i in orig_dat.columns if bool(re.search(r"[Ll]abel", i))]

# Group by minutes, drop the columns containing the label, and sort the values
proc_dat = orig_dat \
    .groupby(["minutes"]) \
    .mean() \
    .reset_index() \
    .drop(label_cols, axis=1) \
    .sort_values(by = "minutes")

ts = proc_dat["ts"]

# Scale the data to prep it for PCA
scaler = StandardScaler()
scaled = scaler.fit_transform(proc_dat.drop(['ts', 'minutes'], axis=1))

# Perform Principle Components Analysis on the data to reduce the dimensionality
pca = PCA(n_components=5)
pc_data = pca.fit_transform(scaled)

# Generate labels for each Principle Component so that I can create a pd Dataframe for easier plotting
labels = {"pc" + str(key + 1) : pc_data[:,key] for key in range(5)}

# Create PD dataframe containing principle components
new_item = {"ts" : np.array(ts),
            "minutes" : np.array(proc_dat["minutes"])}
pc_df = pd.DataFrame({**new_item, **labels})

pc_df.to_csv("pc_dat.csv")
pc_df.to_feather("pc_dat.feather")

