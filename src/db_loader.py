import pandas as pd
df = pd.read_csv("data/raw/marketing_data.csv")
print(df.columns.tolist())
print(df.head(3))
print(df.dtypes)