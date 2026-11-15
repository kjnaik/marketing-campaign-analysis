"""
Feature engineering: derived columns required by the project brief
plus bands used for dashboard filters.
"""
import pandas as pd

from src.data_cleaning import SPEND_COLS, PURCHASE_COLS

CAMPAIGN_COLS = [
    "AcceptedCmp1", "AcceptedCmp2", "AcceptedCmp3",
    "AcceptedCmp4", "AcceptedCmp5", "Response",
]

AGE_BINS = [0, 29, 39, 49, 59, 69, 200]
AGE_LABELS = ["<30", "30-39", "40-49", "50-59", "60-69", "70+"]


def add_features(df: pd.DataFrame) -> pd.DataFrame:
    """Add Age, Customer_Tenure, Total_Spend, Total_Purchases, Children, etc."""
    df = df.copy()
    df["Dt_Customer"] = pd.to_datetime(df["Dt_Customer"])

    # Reference date = day after the latest sign-up, so results are reproducible
    reference_date = df["Dt_Customer"].max() + pd.Timedelta(days=1)

    df["Age"] = reference_date.year - df["Year_Birth"]
    df["Customer_Tenure_Days"] = (reference_date - df["Dt_Customer"]).dt.days
    df["Customer_Tenure_Months"] = (df["Customer_Tenure_Days"] / 30.44).round(1)

    df["Total_Spend"] = df[SPEND_COLS].sum(axis=1)
    df["Total_Purchases"] = df[PURCHASE_COLS].sum(axis=1)
    df["Children"] = df["Kidhome"] + df["Teenhome"]
    df["Campaigns_Accepted"] = df[CAMPAIGN_COLS].sum(axis=1)
    df["Avg_Spend_Per_Purchase"] = (
        df["Total_Spend"] / df["Total_Purchases"].where(df["Total_Purchases"] > 0)
    ).round(2)

    return df


def add_bands(df: pd.DataFrame) -> pd.DataFrame:
    """Add Age_Band and Income_Band (quartile based) for filters and SQL summaries."""
    df = df.copy()
    df["Age_Band"] = pd.cut(df["Age"], bins=AGE_BINS, labels=AGE_LABELS)
    df["Income_Band"] = pd.qcut(
        df["Income"], q=4, labels=["Low", "Lower-Mid", "Upper-Mid", "High"]
    )
    return df