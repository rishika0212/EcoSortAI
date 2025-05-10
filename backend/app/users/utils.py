badge_levels = [
    (1000, "🚀 Planet Protector", "#388E3C"),
    (900, "🛰️ Guardian of Green", "#66BB6A"),
    (800, "👑 Eco Royalty", "#FFD700"),
    (700, "🛡️ Plastic Defender", "#90CAF9"),
    (600, "🔥 Streak Saver", "#EF9A9A"),
    (500, "🧠 Sort Sensei", "#CE93D8"),
    (450, "🌱 Eco Explorer", "#AED581"),
    (400, "🎯 Precision Recycler", "#FFCC80"),
    (350, "🔍 Sort Scout", "#A7FFEB"),
    (300, "☕ PS Slayer", "#F8BBD0"),
    (250, "🍱 PP Pioneer", "#FFF59D"),
    (200, "📦 LDPE Legend", "#E0E0E0"),
    (150, "🚰 HDPE Hero", "#81D4FA"),
    (100, "🧴 PET Pro", "#B2EBF2"),
    (50,  "🔄 Bin Rookie", "#E6FFCC"),
    (10,  "🐣 Green Beginner", "#D0F0C0"),
]

plastic_type_badges = {
    "PET": (10, "🧴 PET Pro"),
    "HDPE": (10, "🚰 HDPE Hero"),
    "LDPE": (10, "📦 LDPE Legend"),
    "PP": (10, "🍱 PP Pioneer"),
    "PS": (10, "☕ PS Slayer"),
}


def get_badge_by_points(points: int) -> str:
    for threshold, badge, _ in badge_levels:
        if points >= threshold:
            return badge
    return "🐣 Green Beginner"


def get_badge_color(points: int) -> str:
    for threshold, _, color in badge_levels:
        if points >= threshold:
            return color
    return "#D0F0C0"


def check_plastic_badges(user):
    awarded = []
    for plastic_type, (threshold, badge) in plastic_type_badges.items():
        count = getattr(user, f"{plastic_type.lower()}_count", 0)
        if count >= threshold:
            awarded.append(badge)
    return awarded


def update_user_badges(user):
    user.badge = get_badge_by_points(user.points)
    return user