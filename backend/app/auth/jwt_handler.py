from jose import jwt
from datetime import datetime, timedelta

SECRET_KEY = '3IacGb3nnOCin5VVKvNORH1eoP1Dh0b4O642Q-vpYoY'
ALGORITHM = "HS256"

def create_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=1)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str):
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
