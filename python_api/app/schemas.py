from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=6)
    token: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class SignupCompanyRequest(BaseModel):
    admin_name: str
    admin_email: EmailStr
    admin_password: str
    name: str
    last_name: str
    email: EmailStr
    phone: str
    company_name: str
    role: Optional[str] = None
    password: str
    cnpj: str
    segment: str


class SaveAnswerItem(BaseModel):
    question_id: int
    score: str
    justification: Optional[str] = ""
    evidence: Optional[str] = ""


class SaveAssessmentRequest(BaseModel):
    assessment_id: int
    answers: List[SaveAnswerItem]


class UpdateUserProfileRequest(BaseModel):
    name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    company_name: Optional[str] = None
    cnpj: Optional[str] = None
    segment: Optional[str] = None

