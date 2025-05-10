from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.models import User
from app.users.schemas import UpdatePointsRequest
from app.auth.dependencies import get_current_user
from app.database.db_utils import get_db

router = APIRouter()


def get_badge_and_color(points: int):
    badge_levels = [
        (500, "🚀 Planet Protector", "#388E3C"),
        (400, "🛰️ Guardian of Green", "#66BB6A"),
        (300, "👑 Eco Royalty", "#FFD700"),
        (250, "🛡️ Plastic Defender", "#90CAF9"),
        (200, "🔥 Streak Saver", "#EF9A9A"),
        (150, "🧠 Sort Sensei", "#CE93D8"),
        (100, "🌱 Eco Explorer", "#AED581"),
        (70, "🎯 Precision Recycler", "#FFCC80"),
        (50, "🔍 Sort Scout", "#A7FFEB"),
        (40, "☕ PS Slayer", "#F8BBD0"),
        (30, "🍱 PP Pioneer", "#FFF59D"),
        (20, "📦 LDPE Legend", "#E0E0E0"),
        (10, "🚰 HDPE Hero", "#81D4FA"),
        (1, "🧴 PET Pro", "#B2EBF2"),
        (0, "🐣 Green Beginner", "#D0F0C0"),
    ]

    for threshold, badge, color in badge_levels:
        if points >= threshold:
            return badge, color
    return "🐣 Green Beginner", "#D0F0C0"


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
