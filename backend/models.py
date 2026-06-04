# models.py
from sqlalchemy import Column, Integer, String, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine

Base = declarative_base()

class UserProfile(Base):
    __tablename__ = 'user_profiles'

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    address = Column(String)
    dob = Column(Date)
    phone = Column(String)
    cin = Column(String, unique=True)

# Setup SQLite database
engine = create_engine('sqlite:///./test.db', connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
