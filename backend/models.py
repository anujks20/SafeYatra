from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime
from sqlalchemy.sql import func

from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    full_name = Column(String, nullable=False)

    email = Column(
        String,
        unique=True,
        index=True,
        nullable=False
    )

    password_hash = Column(
        String,
        nullable=False
    )

    phone = Column(
        String,
        nullable=True
    )

    gender = Column(
        String,
        nullable=True
    )

    age = Column(
        Integer,
        nullable=True
    )

    emergency_contact_name = Column(
        String,
        nullable=True
    )

    emergency_contact_phone = Column(
        String,
        nullable=True
    )

    profile_completed = Column(
        Boolean,
        default=False
    )

    latitude = Column(
        Float,
        nullable=True
    )

    longitude = Column(
        Float,
        nullable=True
    )

    location_sharing = Column(
        Boolean,
        default=True
    )

    # ============================================================
    # FIREBASE CLOUD MESSAGING TOKEN
    # ============================================================

    fcm_token = Column(
        String,
        nullable=True
    )


class SOSAlert(Base):
    __tablename__ = "sos_alerts"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id = Column(
        Integer,
        nullable=False,
        index=True
    )

    latitude = Column(
        Float,
        nullable=True
    )

    longitude = Column(
        Float,
        nullable=True
    )

    status = Column(
        String,
        default="active"
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )