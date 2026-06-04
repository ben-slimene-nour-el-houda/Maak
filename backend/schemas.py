# schemas.py
from pydantic import BaseModel
from datetime import date

class UserProfileCreate(BaseModel):
    full_name: str
    address: str
    dob: date
    phone: str
    cin: str

class UserProfileResponse(UserProfileCreate):
    id: int



