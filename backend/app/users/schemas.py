from pydantic import BaseModel, EmailStr
from typing import List, Optional


class UpdatePointsRequest(BaseModel):
    plastic_type: str


class PlasticBadges(BaseModel):
    pet: Optional[bool] = False
    hdpe: Optional[bool] = False
    ldpe: Optional[bool] = False
    pp: Optional[bool] = False
    ps: Optional[bool] = False


class UserProfileResponse(BaseModel):
    username: str
    email: EmailStr
    points: int
    total_items_recycled: int
    badge: str
    badge_color: str
    pet_count: int
    hdpe_count: int
    ldpe_count: int
    pp_count: int
    ps_count: int
    plastic_badges: PlasticBadges

    class Config:
        orm_mode = True


class BadgeDefinition(BaseModel):
    threshold: int
    badge: str
    color: str
