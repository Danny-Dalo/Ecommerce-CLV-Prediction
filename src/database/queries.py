from src.database.db_engine import engine
import pandas as pd

query = """
    SELECT * FROM clv_data;
"""

clv_data = pd.read_sql(query, engine)

clv_data.to_parquet("data/processed/clv_table_data.parquet")