from pydantic import BaseModel, EmailStr
from typing import Optional


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    confirm_password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ProfileRequest(BaseModel):
    phone: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class LocationRequest(BaseModel):
    latitude: float
    longitude: float


class PrivacyRequest(BaseModel):
    location_sharing: bool


class SOSRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None


# ============================================================
# FIREBASE CLOUD MESSAGING TOKEN
# ============================================================

class FCMTokenRequest(BaseModel):
    fcm_token: str