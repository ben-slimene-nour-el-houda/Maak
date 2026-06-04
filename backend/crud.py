# crud.py
from sqlalchemy.orm import Session
from models import UserProfile
from schemas import UserProfileCreate

from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException

async def create_user_profile(user: UserProfileCreate, db: Session):
    db_user = UserProfile(**user.dict())  # Convert schema to model
    try:
        db.add(db_user)  # Add user to session
        db.commit()  # Commit transaction to database
        db.refresh(db_user)  # Refresh the user object to get the database-generated ID
        return db_user
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Ce numéro CIN existe déjà dans la base de données.")

def get_user_profile(user_id: int, db: Session):
    """
    Retrieves a user profile by user_id from the database.
    """
    db_user = db.query(UserProfile).filter(UserProfile.id == user_id).first()
    return db_user

