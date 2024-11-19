#!/bin/bash

# Top 5 IP Addresses with the most requests

awk '{print $1}' nginx-access.txt | sort | uniq -c

# Top 5 Most Requested Paths 

# Top 5 Response Status Codes

# Top 5 User Agents 