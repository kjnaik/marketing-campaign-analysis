import pandas as pd

pd.set_option("display.max_columns", None)
pd.set_option("display.width", 250)

df = pd.read_csv("data/raw/marketing_data.csv")

print("SHAPE:", df.shape)
print("\nMISSING VALUES:")
print(df.isna().sum()[df.isna().sum() > 0])
print("\nDUPLICATE ROWS:", df.duplicated().sum())
print("DUPLICATE IDs:", df["ID"].duplicated().sum())

print("\nNUMERIC SUMMARY:")
print(df.describe().T)

for col in ["Education", "Marital_Status", "Country"]:
    print(f"\n{col}:")
    print(df[col].value_counts(dropna=False))

print("\nDt_Customer samples:", df["Dt_Customer"].head(10).tolist())
