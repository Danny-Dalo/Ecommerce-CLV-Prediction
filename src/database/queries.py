from src.database.db_engine import engine
import pandas as pd
from sqlalchemy import text



with open("sql/TABLE_VIEWS_02.sql", "r") as f:
    view_sql = f.read()

with engine.begin() as conn:
    conn.execute(text(view_sql))



clv_data = pd.read_sql("SELECT * FROM clv_data;", engine)
clv_data.to_parquet("data/2021_customer_data.parquet")


clv_target = pd.read_sql("SELECT * FROM clv_target", engine)
clv_target.to_parquet("data/2022_customer_data.parquet")

