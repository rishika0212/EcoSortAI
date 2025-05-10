from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.models import User
from app.users.schemas import UpdatePointsRequest
from app.auth.dependencies import get_current_user
from app.database.db_utils import get_db

router = APIRouter()


from app.users.utils import get_badge_by_points, get_badge_color

def get_badge_and_color(points: int):
    badge = get_badge_by_points(points)
    color = get_badge_color(points)
    return badge, color


@router.post("/points")
def update_points(payload: UpdatePointsRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    points_earned = 10
    
    # Get a fresh reference to the user from the current session
    user = db.query(User).filter(User.id == current_user.id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.points += points_earned
    user.total_items_recycled += 1

    # Update plastic type counters
    plastic_type = payload.plastic_type.upper()
    if plastic_type == "PET":
        user.pet_count += 1
    elif plastic_type == "HDPE":
        user.hdpe_count += 1
    elif plastic_type == "LDPE":
        user.ldpe_count += 1
    elif plastic_type == "PP":
        user.pp_count += 1
    elif plastic_type == "PS":
        user.ps_count += 1

    # Update badge
    badge, color = get_badge_and_color(user.points)
    user.badge = badge
    user.badge_color = color

    db.commit()
    db.refresh(user)
    
    # Update the current_user reference with the new values
    current_user = user

    return {
        "success": True,
        "message": f"{points_earned} points added!",
        "data": {
            "points": user.points,
            "badge": badge,
            "badge_color": color,
            "pet_count": user.pet_count,
            "hdpe_count": user.hdpe_count,
            "ldpe_count": user.ldpe_count,
            "pp_count": user.pp_count,
            "ps_count": user.ps_count,
            "total_items_recycled": user.total_items_recycled
        }
    }


@router.get("/users/me")
def get_user_profile(current_user: User = Depends(get_current_user)):
    print(f"API: Returning user profile for {current_user.username}")
    response = {
        "success": True,
        "data": {
            "id": current_user.id,
            "username": current_user.username,
            "points": current_user.points,
            "badge": current_user.badge,
            "badge_color": current_user.badge_color,
            "pet_count": current_user.pet_count,
            "hdpe_count": current_user.hdpe_count,
            "ldpe_count": current_user.ldpe_count,
            "pp_count": current_user.pp_count,
            "ps_count": current_user.ps_count,
            "total_items_recycled": current_user.total_items_recycled,
        }
    }
    print(f"API: Response data: {response}")
    return response
