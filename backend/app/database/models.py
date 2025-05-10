from sqlalchemy import Column, Integer, String
from app.database.connection import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True)
    email = Column(String, unique=True)
    hashed_password = Column(String)
    
    # Point and badge system
    points = Column(Integer, default=0)
    badge = Column(String, default="🐣 Green Beginner")
    total_items_recycled = Column(Integer, default=0)
    badge_color = Column(String, default="#FFFFFF")

    # Per-plastic-type counts
    pet_count = Column(Integer, default=0)
    hdpe_count = Column(Integer, default=0)
    ldpe_count = Column(Integer, default=0)
    pp_count = Column(Integer, default=0)
    ps_count = Column(Integer, default=0)
