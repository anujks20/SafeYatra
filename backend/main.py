import os

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from dotenv import load_dotenv
from twilio.rest import Client

import firebase_admin
from firebase_admin import credentials, messaging

from database import engine, Base, get_db
from models import User, SOSAlert

from schemas import (
    RegisterRequest,
    LoginRequest,
    ProfileRequest,
    LocationRequest,
    PrivacyRequest,
    SOSRequest,
    FCMTokenRequest,
)


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================

load_dotenv()

TWILIO_ACCOUNT_SID = os.getenv(
    "TWILIO_ACCOUNT_SID"
)

TWILIO_AUTH_TOKEN = os.getenv(
    "TWILIO_AUTH_TOKEN"
)

TWILIO_PHONE_NUMBER = os.getenv(
    "TWILIO_PHONE_NUMBER"
)


# ============================================================
# FIREBASE ADMIN INITIALIZATION
# ============================================================

FIREBASE_KEY_PATH = "/etc/secrets/serviceAccountKey.json"

if not os.path.exists(FIREBASE_KEY_PATH):
    FIREBASE_KEY_PATH = os.path.join(
        os.path.dirname(__file__),
        "firebase",
        "serviceAccountKey.json"
    )

try:

    if not firebase_admin._apps:

        cred = credentials.Certificate(
            FIREBASE_KEY_PATH
        )

        firebase_admin.initialize_app(
            cred
        )

    print(
        "Firebase Admin initialized successfully"
    )

except Exception as e:

    print(
        f"FIREBASE INITIALIZATION ERROR: {str(e)}"
    )


# ============================================================
# CREATE DATABASE TABLES
# ============================================================

Base.metadata.create_all(
    bind=engine
)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="TravelBuddy API",
    version="1.0.0"
)

# ============================================================
# CORS
# ============================================================

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# PASSWORD HASHING
# ============================================================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)


def hash_password(password: str):

    return pwd_context.hash(
        password
    )


def verify_password(
    plain_password: str,
    hashed_password: str
):

    return pwd_context.verify(
        plain_password,
        hashed_password
    )


# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():

    return {
        "message":
            "TravelBuddy backend is running successfully"
    }


# ============================================================
# REGISTER
# ============================================================

@app.post("/register")
def register(
    user: RegisterRequest,
    db: Session = Depends(get_db)
):

    if user.password != user.confirm_password:

        raise HTTPException(
            status_code=400,
            detail="Passwords do not match"
        )

    existing_user = db.query(
        User
    ).filter(
        User.email == user.email
    ).first()

    if existing_user:

        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    new_user = User(

        full_name=user.full_name,

        email=user.email,

        password_hash=hash_password(
            user.password
        )
    )

    db.add(
        new_user
    )

    db.commit()

    db.refresh(
        new_user
    )

    return {

        "message":
            "User registered successfully",

        "user_id":
            new_user.id,

        "email":
            new_user.email
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/login")
def login(
    user: LoginRequest,
    db: Session = Depends(get_db)
):

    existing_user = db.query(
        User
    ).filter(
        User.email == user.email
    ).first()

    if not existing_user:

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    if not verify_password(
        user.password,
        existing_user.password_hash
    ):

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    return {

        "message":
            "Login successful",

        "user_id":
            existing_user.id,

        "full_name":
            existing_user.full_name,

        "email":
            existing_user.email,

        "profile_completed":
            existing_user.profile_completed
    }


# ============================================================
# SAVE FCM TOKEN
# ============================================================

@app.post("/fcm-token/{user_id}")
def save_fcm_token(
    user_id: int,
    token_data: FCMTokenRequest,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.fcm_token = token_data.fcm_token

    db.commit()

    db.refresh(
        user
    )

    print(
        f"FCM token saved successfully "
        f"for user {user.id}"
    )

    return {

        "message":
            "FCM token saved successfully",

        "user_id":
            user.id
    }


# ============================================================
# GET USER PROFILE
# ============================================================

@app.get("/profile/{user_id}")
def get_profile(
    user_id: int,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {

        "id":
            user.id,

        "full_name":
            user.full_name,

        "email":
            user.email,

        "phone":
            user.phone,

        "gender":
            user.gender,

        "age":
            user.age,

        "emergency_contact_name":
            user.emergency_contact_name,

        "emergency_contact_phone":
            user.emergency_contact_phone,

        "profile_completed":
            user.profile_completed,

        "latitude":
            user.latitude,

        "longitude":
            user.longitude,

        "location_sharing":
            user.location_sharing
    }


# ============================================================
# UPDATE PROFILE
# ============================================================

@app.put("/profile/{user_id}")
def update_profile(
    user_id: int,
    profile: ProfileRequest,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    if profile.phone is not None:

        user.phone = profile.phone

    if profile.gender is not None:

        user.gender = profile.gender

    if profile.age is not None:

        user.age = profile.age

    if profile.emergency_contact_name is not None:

        user.emergency_contact_name = (
            profile.emergency_contact_name
        )

    if profile.emergency_contact_phone is not None:

        user.emergency_contact_phone = (
            profile.emergency_contact_phone
        )

    user.profile_completed = True

    db.commit()

    db.refresh(
        user
    )

    return {

        "message":
            "Profile updated successfully",

        "profile_completed":
            user.profile_completed
    }


# ============================================================
# UPDATE LOCATION
# ============================================================

@app.put("/location/{user_id}")
def update_location(
    user_id: int,
    location: LocationRequest,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.latitude = location.latitude

    user.longitude = location.longitude

    db.commit()

    db.refresh(
        user
    )

    return {

        "message":
            "Location updated successfully",

        "latitude":
            user.latitude,

        "longitude":
            user.longitude
    }


# ============================================================
# GET PRIVACY SETTINGS
# ============================================================

@app.get("/privacy/{user_id}")
def get_privacy(
    user_id: int,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {

        "user_id":
            user.id,

        "location_sharing":
            user.location_sharing
    }


# ============================================================
# UPDATE PRIVACY SETTINGS
# ============================================================

@app.put("/privacy/{user_id}")
def update_privacy(
    user_id: int,
    privacy: PrivacyRequest,
    db: Session = Depends(get_db)
):

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user.location_sharing = (
        privacy.location_sharing
    )

    db.commit()

    db.refresh(
        user
    )

    return {

        "message":
            "Privacy settings updated successfully",

        "location_sharing":
            user.location_sharing
    }


# ============================================================
# TEST FCM NOTIFICATION
# ============================================================

@app.post("/test-fcm")
def send_test_fcm(
    fcm_token: str
):

    try:

        message = messaging.Message(

            notification=messaging.Notification(

                title="🚨 TravelBuddy Test",

                body=(
                    "Firebase notification "
                    "is working successfully!"
                )
            ),

            token=fcm_token,

            android=messaging.AndroidConfig(

                priority="high"
            )
        )

        response = messaging.send(
            message
        )

        print(
            f"FCM notification sent successfully: "
            f"{response}"
        )

        return {

            "message":
                "FCM notification sent successfully",

            "message_id":
                response
        }

    except Exception as e:

        print(
            f"FCM ERROR: {str(e)}"
        )

        raise HTTPException(

            status_code=500,

            detail=str(e)
        )


# ============================================================
# SOS ALERT
# ============================================================

@app.post("/sos/{user_id}")
def create_sos_alert(
    user_id: int,
    sos: SOSRequest,
    db: Session = Depends(get_db)
):

    # --------------------------------------------------------
    # GET USER
    # --------------------------------------------------------

    user = db.query(
        User
    ).filter(
        User.id == user_id
    ).first()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found"
        )


    # --------------------------------------------------------
    # UPDATE LOCATION FROM SOS REQUEST
    # --------------------------------------------------------

    if sos.latitude is not None:

        user.latitude = sos.latitude

    if sos.longitude is not None:

        user.longitude = sos.longitude

    db.commit()

    db.refresh(
        user
    )


    # --------------------------------------------------------
    # CREATE SOS ALERT RECORD
    # --------------------------------------------------------

    new_sos_alert = SOSAlert(

        user_id=user.id,

        latitude=user.latitude,

        longitude=user.longitude,

        status="active"
    )

    db.add(
        new_sos_alert
    )

    db.commit()

    db.refresh(
        new_sos_alert
    )


    # ========================================================
    # SEND TWILIO SMS
    # ========================================================

    sms_sent = False
    sms_error = None

    try:
        if not user.emergency_contact_phone:
            raise Exception(
                "Emergency contact phone number not found"
            )

        if (
            not TWILIO_ACCOUNT_SID
            or not TWILIO_AUTH_TOKEN
            or not TWILIO_PHONE_NUMBER
        ):
            raise Exception(
                "Twilio credentials not configured"
            )

        client = Client(
            TWILIO_ACCOUNT_SID,
            TWILIO_AUTH_TOKEN
        )

        # ----------------------------------------------------
        # FORMAT INDIAN EMERGENCY CONTACT NUMBER
        # ----------------------------------------------------

        emergency_phone = (
            user.emergency_contact_phone.strip()
        )

        if not emergency_phone.startswith("+"):
            emergency_phone = "+91" + emergency_phone

        # ----------------------------------------------------
        # TWILIO TRIAL TEMPLATE
        # ----------------------------------------------------

        message = client.messages.create(
            body="sms_account_alerts",
            from_=TWILIO_PHONE_NUMBER,
            to=emergency_phone
        )

        sms_sent = True

        print(
            f"SOS SMS sent successfully. "
            f"SID: {message.sid}"
        )

    except Exception as e:
        sms_error = str(e)

        print(
            f"ERROR SENDING SOS SMS: "
            f"{sms_error}"
        )


    # ========================================================
    # SEND FCM NOTIFICATION TO EMERGENCY CONTACT
    # ========================================================

    fcm_sent = False
    fcm_error = None

    try:

        # ----------------------------------------------------
        # CHECK EMERGENCY CONTACT PHONE
        # ----------------------------------------------------

        if not user.emergency_contact_phone:
            raise Exception(
                "Emergency contact phone number not found"
            )

        # ----------------------------------------------------
        # NORMALIZE EMERGENCY CONTACT PHONE
        # ----------------------------------------------------

        emergency_phone = "".join(
            ch
            for ch in user.emergency_contact_phone
            if ch.isdigit()
        )

        # Remove Indian country code 91
        if (
            emergency_phone.startswith("91")
            and len(emergency_phone) == 12
        ):
            emergency_phone = emergency_phone[2:]

        # Keep last 10 digits
        emergency_phone = emergency_phone[-10:]


        # ----------------------------------------------------
        # FIND EMERGENCY CONTACT TRAVELBUDDY USER
        # ----------------------------------------------------

        emergency_contact_user = None

        all_users = db.query(User).all()

        for candidate in all_users:

            # Do not match the SOS sender
            if candidate.id == user.id:
                continue

            # Candidate must have a phone number
            if not candidate.phone:
                continue

            # Normalize candidate phone
            candidate_phone = "".join(
                ch
                for ch in candidate.phone
                if ch.isdigit()
            )

            # Remove Indian country code 91
            if (
                candidate_phone.startswith("91")
                and len(candidate_phone) == 12
            ):
                candidate_phone = candidate_phone[2:]

            # Keep last 10 digits
            candidate_phone = candidate_phone[-10:]


            # Compare phone numbers
            if candidate_phone == emergency_phone:

                emergency_contact_user = candidate
                break


        # ----------------------------------------------------
        # CHECK IF EMERGENCY CONTACT IS REGISTERED
        # ----------------------------------------------------

        if not emergency_contact_user:
            raise Exception(
                "Emergency contact is not registered "
                "as a TravelBuddy user"
            )


        # ----------------------------------------------------
        # CHECK EMERGENCY CONTACT FCM TOKEN
        # ----------------------------------------------------

        if not emergency_contact_user.fcm_token:
            raise Exception(
                "Emergency contact FCM token not found"
            )


        # ----------------------------------------------------
        # PRINT CONTACT INFORMATION
        # ----------------------------------------------------

        print(
            "========================================"
        )

        print(
            "EMERGENCY CONTACT FOUND"
        )

        print(
            f"Contact User ID: "
            f"{emergency_contact_user.id}"
        )

        print(
            f"Contact Name: "
            f"{emergency_contact_user.full_name}"
        )

        print(
            f"Contact Phone: "
            f"{emergency_contact_user.phone}"
        )

        print(
            "========================================"
        )


        # ----------------------------------------------------
        # CREATE FCM MESSAGE
        # ----------------------------------------------------

        fcm_message = messaging.Message(

            notification=messaging.Notification(

                title="🚨 SOS ALERT",

                body=(
                    f"{user.full_name} "
                    "has activated an SOS alert."
                )
            ),

            # IMPORTANT:
            # Send FCM to emergency contact,
            # NOT to the SOS sender.
            token=emergency_contact_user.fcm_token,

            android=messaging.AndroidConfig(

                priority="high",

                notification=messaging.AndroidNotification(

                    title="🚨 SOS ALERT",

                    body=(
                        f"{user.full_name} "
                        "has activated an SOS alert."
                    ),

                    sound="default",

                    # This channel contains
                    # your custom SOS siren.
                    channel_id="sos_alerts_v3"
                )
            )
        )


        # ----------------------------------------------------
        # SEND FCM
        # ----------------------------------------------------

        fcm_response = messaging.send(
            fcm_message
        )

        fcm_sent = True

        print(
            "SOS FCM notification sent successfully "
            "to emergency contact. "
            f"Message ID: {fcm_response}"
        )


    except Exception as e:

        fcm_error = str(e)

        print(
            f"ERROR SENDING SOS FCM: "
            f"{fcm_error}"
        )


    # ========================================================
    # RETURN RESPONSE
    # ========================================================

    return {

        "message":
            "SOS alert activated successfully",

        "sos_id":
            new_sos_alert.id,

        "user_id":
            user.id,

        "user_name":
            user.full_name,

        "latitude":
            new_sos_alert.latitude,

        "longitude":
            new_sos_alert.longitude,

        "status":
            new_sos_alert.status,

        "created_at":
            new_sos_alert.created_at,

        "emergency_contact_name":
            user.emergency_contact_name,

        "emergency_contact_phone":
            user.emergency_contact_phone,

        "sms_sent":
            sms_sent,

        "sms_error":
            sms_error,

        "fcm_sent":
            fcm_sent,

        "fcm_error":
            fcm_error
    }





# ============================================================
# POLICE DASHBOARD ENDPOINTS
# ============================================================

@app.get("/police/user")
def police_find_user(
    email: str,
    db: Session = Depends(get_db)
):
    """
    Find a TravelBuddy user by email for the police dashboard.
    """

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "user_id": user.id,
        "full_name": user.full_name,
        "email": user.email,
        "phone": user.phone,

        "latitude": user.latitude,
        "longitude": user.longitude,

        "emergency_contact_name":
            user.emergency_contact_name,

        "emergency_contact_phone":
            user.emergency_contact_phone
    }


@app.get("/police/user/{user_id}/status")
def police_user_status(
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Get current user location and latest SOS status.
    """

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    latest_sos = (
        db.query(SOSAlert)
        .filter(SOSAlert.user_id == user_id)
        .order_by(SOSAlert.id.desc())
        .first()
    )

    sos_data = None

    if latest_sos:
        sos_data = {
            "id": latest_sos.id,
            "latitude": latest_sos.latitude,
            "longitude": latest_sos.longitude,
            "status": latest_sos.status,
            "created_at": latest_sos.created_at
        }

    return {
        "user_id": user.id,
        "full_name": user.full_name,

        "latitude": user.latitude,
        "longitude": user.longitude,

        "emergency_contact_name":
            user.emergency_contact_name,

        "emergency_contact_phone":
            user.emergency_contact_phone,

        "sos": sos_data
    }


@app.get("/police/sos/active")
def police_active_sos(
    db: Session = Depends(get_db)
):
    """
    Get all currently active SOS alerts.
    """

    alerts = (
        db.query(SOSAlert)
        .filter(SOSAlert.status == "active")
        .order_by(SOSAlert.id.desc())
        .all()
    )

    result = []

    for alert in alerts:

        user = (
            db.query(User)
            .filter(User.id == alert.user_id)
            .first()
        )

        if not user:
            continue

        result.append({
            "sos_id": alert.id,

            "user_id": user.id,

            "user_name": user.full_name,

            "email": user.email,

            "phone": user.phone,

            "latitude": alert.latitude,

            "longitude": alert.longitude,

            "created_at": alert.created_at,

            "emergency_contact_name":
                user.emergency_contact_name,

            "emergency_contact_phone":
                user.emergency_contact_phone
        })

    return {
        "active_sos": result
    }


# ============================================================
# RESOLVE SOS
# ============================================================

@app.put("/police/sos/{sos_id}/resolve")
def resolve_sos(
    sos_id: int,
    db: Session = Depends(get_db)
):
    """
    Mark an active SOS alert as resolved.
    """

    sos = (
        db.query(SOSAlert)
        .filter(SOSAlert.id == sos_id)
        .first()
    )

    if not sos:
        raise HTTPException(
            status_code=404,
            detail="SOS alert not found"
        )

    sos.status = "resolved"

    db.commit()
    db.refresh(sos)

    return {
        "message": "Emergency resolved successfully",
        "sos_id": sos.id,
        "status": sos.status
    }