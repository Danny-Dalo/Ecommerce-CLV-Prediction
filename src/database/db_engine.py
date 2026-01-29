import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

database_url = os.getenv("DB_URL")

engine = create_engine(database_url)




