import pandas as pd

print("Script started...")

# Replace these with actual file paths or data loading from your CSVs

filepath_a = './FileA.csv' # Adjust the path to your actual file

filepath_b = './FileB.csv' # Adjust the path to your actual file


# Read CSV

df_a = pd.read_csv(filepath_a)

df_b = pd.read_csv(filepath_b)


# Performing the comparison

common_values = set(df_a['DNSHostName']).intersection(df_b['Display Name'])

only_in_a = set(df_a['DNSHostName']).difference(df_b['Display Name'])

only_in_b = set(df_b['Display Name']).difference(df_a['DNSHostName'])


# Creating DataFrames for better visualization

result_common = pd.DataFrame(list(common_values), columns=['Values in Both'])

result_only_in_a = pd.DataFrame(list(only_in_a), columns=['Values only in A'])

result_only_in_b = pd.DataFrame(list(only_in_b), columns=['Values only in B'])


# Save to csvs
result_common.to_csv('Values_in_Both_CSVs.csv', index=False)
result_only_in_a.to_csv('Values_only_in_A.csv', index=False)
result_only_in_b.to_csv('Values_only_in_B.csv', index=False)

print("Results have been saved to the following files:")
print("- Values_in_Both_CSVs.csv")
print("- Values_only_in_A.csv")
print("- Values_only_in_B.csv")