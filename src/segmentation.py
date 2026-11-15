"""
Rule-based segmentation (rules taken from the project brief).
Each segment is a 0/1 flag column, so a customer can belong to several.
"""
from pathlib import Path

import pandas as pd

from src.data_cleaning import PROCESSED_PATH
from src.feature_engineering import add_features, add_bands

FEATURED_PATH = Path("data/processed/featured_marketing_data.csv")

SEGMENT_COLS = [
    "Seg_High_Income", "Seg_Young_Customer", "Seg_Campaign_Responder",
    "Seg_High_Web_Engagement", "Seg_Family_Customer", "Seg_High_Spender",
]


def add_segments(df: pd.DataFrame) -> pd.DataFrame:
    """Apply the six business rules from the brief."""
    df = df.copy()
    spend_p90 = df["Total_Spend"].quantile(0.90)

    df["Seg_High_Income"] = (df["Income"] > 75000).astype(int)
    df["Seg_Young_Customer"] = (df["Age"] < 30).astype(int)
    df["Seg_Campaign_Responder"] = (df["Response"] == 1).astype(int)
    df["Seg_High_Web_Engagement"] = (df["NumWebVisitsMonth"] > 5).astype(int)
    df["Seg_Family_Customer"] = (df["Children"] > 0).astype(int)
    df["Seg_High_Spender"] = (df["Total_Spend"] > spend_p90).astype(int)

    df.attrs["spend_p90"] = float(spend_p90)
    return df


def add_underserved_flag(df: pd.DataFrame) -> pd.DataFrame:
    """Under-served = below-median spend, above-median web visits, no Response."""
    df = df.copy()
    df["Seg_Underserved"] = (
        (df["Total_Spend"] < df["Total_Spend"].median())
        & (df["NumWebVisitsMonth"] > df["NumWebVisitsMonth"].median())
        & (df["Response"] == 0)
    ).astype(int)
    return df


def segment_summary(df: pd.DataFrame) -> pd.DataFrame:
    """One row per segment: size, response rate, average spend and web visits."""
    rows = []
    for col in SEGMENT_COLS + ["Seg_Underserved"]:
        members = df[df[col] == 1]
        rows.append({
            "Segment": col.replace("Seg_", ""),
            "Customers": len(members),
            "Pct_of_Base": round(100 * len(members) / len(df), 1),
            "Response_Rate_%": round(100 * members["Response"].mean(), 1),
            "Avg_Spend": round(members["Total_Spend"].mean(), 1),
            "Avg_Web_Visits": round(members["NumWebVisitsMonth"].mean(), 2),
        })
    return pd.DataFrame(rows)


def build_featured_dataset() -> pd.DataFrame:
    df = pd.read_csv(PROCESSED_PATH)
    df = add_features(df)
    df = add_bands(df)
    df = add_segments(df)
    df = add_underserved_flag(df)
    return df


def main() -> None:
    df = build_featured_dataset()
    FEATURED_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(FEATURED_PATH, index=False)

    pd.set_option("display.width", 200)
    print(f"Rows: {len(df)} | Columns: {df.shape[1]}")
    print(f"90th percentile of Total_Spend: {df.attrs['spend_p90']:.0f}")
    print("\nSanity ranges:")
    print(df[["Age", "Income", "Total_Spend", "Total_Purchases",
              "Children", "Customer_Tenure_Days"]].describe().round(1).T[["min", "50%", "max"]])
    print("\nSEGMENT SUMMARY")
    print(segment_summary(df).to_string(index=False))
    print("\nOverall response rate: "
          f"{100 * df['Response'].mean():.1f}%")
    print(f"\nSaved to {FEATURED_PATH}")


if __name__ == "__main__":
    main()