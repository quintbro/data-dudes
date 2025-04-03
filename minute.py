#############################################################################
####### This script is to group the grouped data from R by minute and ####### 
#######             perform Principle Components Analysis             #######
#############################################################################

from datetime import datetime
import pickle
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

# Create a human readable datetime variable so that it is possible to aggregate by minutes
orig_dat["minutes"] = orig_dat["ts"] \
    .apply(datetime.fromtimestamp) \
    .apply(lambda x : x.strftime("%Y-%m-%d %H:%M")) # format it so that it doesn't include seconds

# Find the columns that contain the label
label_cols = [i for i in orig_dat.columns if bool(re.search(r"[Ll]abel", i))]

# Group by minutes, drop the columns containing the label, and sort the values
proc_dat = orig_dat \
    .drop("direction", axis=1) \
    .groupby(["minutes"]) \
    .mean() \
    .reset_index() \
    .drop(label_cols, axis=1) \
    .sort_values(by = "minutes")

proc_dat.to_feather("leo_dat.feather")

# Scale the data to prep it for PCA
scaler = StandardScaler()
scaled = scaler.fit_transform(proc_dat.drop(['ts', 'minutes'], axis=1))

# Perform Principle Components Analysis on the data to reduce the dimensionality
pca = PCA(n_components=50)
pc_data = pca.fit_transform(scaled)


col_names = proc_dat.columns
with open("col_names.pkl", "wb") as f:
    pickle.dump(col_names, f)

np.save("loading_vec.npy", pca.components_)

# Generate labels for each Principle Component so that I can create a pd Dataframe for easier plotting
labels = {"pc" + str(key + 1) : pc_data[:,key] for key in range(pc_data.shape[1])}

# Create PD dataframe containing principle components
new_item = {"ts" : np.array(proc_dat["ts"]),
            "minutes" : np.array(proc_dat["minutes"])}
pc_df = pd.DataFrame({**new_item, **labels})

pc_df.to_feather("pc_dat_50.feather")
