#!/bin/bash 

top -o %MEM
top -o %CPU
top -n 1 -b > top-output.txt #saves it to file
head -n 12 top-output.txt | tail -6 #Pulls top 5 with header