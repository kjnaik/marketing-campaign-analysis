"""
Data cleaning module for the marketing campaign analysis project.

Pipeline: load -> tidy text -> parse dates -> remove duplicates ->
validate values -> handle outliers -> impute missing values -> save.
"""
from pathlib import Path

import numpy as np
import pandas as pd

RAW_PATH = Path("data/raw/marketing_data.csv")
PROCESSED_PATH = Path("data/processed/cleaned_marketing_data.csv")

SPEND_COLS = [
    "MntWines", "MntFruits", "MntMeatProducts",
    "MntFishProducts", "MntSweetProducts", "MntGoldProds",
]
PURCHASE_COLS = [
    "NumDealsPurchases", "NumWebPurchases",
    "NumCatalogPurchases", "NumStorePurchases",
]
BINARY_COLS = [
    "AcceptedCmp1", "AcceptedCmp2", "AcceptedCmp3",
    "AcceptedCmp4", "AcceptedCmp5", "Response", "Complain",
]
# Rare/odd marital labels folded into "Single"
MARITAL_MAP = {"Alone": "Single", "Absurd": "Single", "YOLO": "Single"}


def load_raw(path: Path = RAW_PATH) -> pd.DataFrame:
    """Load the raw CSV."""
    return pd.read_csv(path)


def tidy_text_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Strip stray whitespace from column names and text values."""
    df = df.copy()
    df.columns = df.columns.str.strip()
    for col in df.columns:
        if not pd.api.types.is_numeric_dtype(df[col]):
            df[col] = df[col].astype("string").str.strip()
    df["Marital_Status"] = df["Marital_Status"].replace(MARITAL_MAP)
    return df


def parse_dates(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    """Convert Dt_Customer to datetime; rows that fail to parse are dropped."""
    df = df.copy()
    df["Dt_Customer"] = pd.to_datetime(
        df["Dt_Customer"], format="mixed", dayfirst=True, errors="coerce"
    )
    bad = df["Dt_Customer"].isna().sum()
    log["unparseable_dates_dropped"] = int(bad)
    return df.dropna(subset=["Dt_Customer"])


def remove_duplicates(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    """Drop fully duplicated rows, then duplicated customer IDs."""
    before = len(df)
    df = df.drop_duplicates()
    log["duplicate_rows_dropped"] = before - len(df)
    before = len(df)
    df = df.drop_duplicates(subset="ID", keep="first")
    log["duplicate_ids_dropped"] = before - len(df)
    return df


def validate_values(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    """Remove impossible values: negative amounts, non-binary flags, bad birth years."""
    before = len(df)

    numeric_nonneg = SPEND_COLS + PURCHASE_COLS + [
        "NumWebVisitsMonth", "Recency", "Kidhome", "Teenhome",
    ]
    df = df[(df[numeric_nonneg] >= 0).all(axis=1)]
    df = df[df[BINARY_COLS].isin([0, 1]).all(axis=1)]

    # Customers must be at least 18 at sign-up and born after 1900
    signup_year = df["Dt_Customer"].dt.year
    df = df[(df["Year_Birth"] >= 1900) & (df["Year_Birth"] <= signup_year - 18)]

    log["invalid_rows_dropped"] = before - len(df)
    return df


def cap_income_outliers(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    """Cap extreme incomes at the IQR upper fence (keeps the row, limits distortion)."""
    df = df.copy()
    q1, q3 = df["Income"].quantile([0.25, 0.75])
    upper = q3 + 1.5 * (q3 - q1)
    capped = (df["Income"] > upper).sum()
    df["Income"] = df["Income"].clip(upper=upper)
    log["income_upper_fence"] = round(float(upper), 2)
    log["income_values_capped"] = int(capped)
    return df


def impute_income(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    """Fill missing Income with the median of the customer's Education group."""
    df = df.copy()
    log["income_missing_before"] = int(df["Income"].isna().sum())
    group_median = df.groupby("Education")["Income"].transform("median")
    df["Income"] = df["Income"].fillna(group_median).fillna(df["Income"].median())
    return df


def clean_data(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Run the full cleaning pipeline and return (clean_df, log)."""
    log = {"rows_raw": len(df)}
    df = tidy_text_columns(df)
    df = parse_dates(df, log)
    df = remove_duplicates(df, log)
    df = validate_values(df, log)
    df = cap_income_outliers(df, log)
    df = impute_income(df, log)
    log["rows_clean"] = len(df)
    return df.reset_index(drop=True), log


def main() -> None:
    raw = load_raw()
    clean, log = clean_data(raw)
    PROCESSED_PATH.parent.mkdir(parents=True, exist_ok=True)
    clean.to_csv(PROCESSED_PATH, index=False)

    print("CLEANING REPORT")
    for key, value in log.items():
        print(f"  {key}: {value}")
    print(f"\nSaved to {PROCESSED_PATH}")
    print("Remaining missing values:", int(clean.isna().sum().sum()))


if __name__ == "__main__":
    main()