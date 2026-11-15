"""
Database loader: builds the MySQL schema, loads the featured data
through a staging table, and creates the views.
Run with:  python -m src.db_loader
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

from src.segmentation import FEATURED_PATH

load_dotenv()
SQL_DIR = Path("sql")


def make_engine(with_database: bool = True):
    """Build a SQLAlchemy engine from the .env settings."""
    url = URL.create(
        "mysql+pymysql",
        username=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME", "marketing_db") if with_database else None,
    )
    return create_engine(url)


def run_sql_file(engine, path: Path) -> None:
    """Run a .sql file statement by statement (skips full-line -- comments)."""
    script = path.read_text(encoding="utf-8")
    with engine.begin() as conn:
        for raw in script.split(";"):
            lines = [ln for ln in raw.splitlines() if not ln.strip().startswith("--")]
            statement = "\n".join(lines).strip()
            if statement:
                conn.exec_driver_sql(statement)


def main() -> None:
    df = pd.read_csv(FEATURED_PATH)

    print("1/4 Creating schema ...")
    run_sql_file(make_engine(with_database=False), SQL_DIR / "01_ddl.sql")

    engine = make_engine()
    print("2/4 Writing staging table ...")
    df.to_sql("stg_marketing", engine, if_exists="replace", index=False, chunksize=5000)

    print("3/4 Loading normalized tables ...")
    run_sql_file(engine, SQL_DIR / "02_load_data.sql")

    print("4/4 Creating views ...")
    run_sql_file(engine, SQL_DIR / "04_views.sql")

    print("\nVERIFICATION")
    with engine.connect() as conn:
        for table in ["customers", "spending", "channel_activity",
                      "campaign_responses", "customer_segments"]:
            n = conn.exec_driver_sql(f"SELECT COUNT(*) FROM {table}").scalar()
            print(f"  {table}: {n} rows")
        db_spend = int(conn.exec_driver_sql("SELECT SUM(total_spend) FROM spending").scalar())
        rate = conn.exec_driver_sql(
            "SELECT ROUND(100 * AVG(response), 1) FROM campaign_responses").scalar()
    print(f"  Total spend  DB: {db_spend}  | CSV: {int(df['Total_Spend'].sum())}")
    print(f"  Response rate DB: {rate}%  | CSV: {100 * df['Response'].mean():.1f}%")


if __name__ == "__main__":
    main()