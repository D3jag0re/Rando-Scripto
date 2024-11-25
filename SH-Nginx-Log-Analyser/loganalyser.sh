#!/bin/bash

# Top 5 IP Addresses with the most requests

awk '{print $1}' nginx-access.log | sort | uniq -c | sort -nr | head -n5

# Top 5 Most Requested Paths 

awk '{print $7}' nginx-access.log | sort | uniq -c | sort -nr | head -n5

# Top 5 Response Status Codes

# Top 5 User Agents 