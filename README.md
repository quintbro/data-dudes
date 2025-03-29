# data-dudes
This repository is for the "Data Dudes" submission to the Cyber Wise Data Science Competition at Texas A&amp;M

# Methodology
The data set that we are working with consists of a simulated APT attack from 2024 run by the canada cybersecurity institute and can be obtained [HERE](https://www.unb.ca/cic/datasets/iiot-dataset-2024.html)

The first phase of the experiment consists of network log data that is %100 benign, and the attack begins during the second phase. The goal of our analysis was to create a model that can identify when the attacks begin using a changepoint detection. Our assumption is that once attackers have access to the system, there will be different interactions than there usually are and we hope to be able to detect that change.

Each row in the dataset represents a packet sent from one IP address to another. By leveraging the relationship between the different IIoT devices as well as the different variables obtained from the network log, we hope to find a difference between the benign and the packets.

Once it is identified that there is an attack, we have a model that will determine what type of attack it is so that the attacker can be removed from the system.
