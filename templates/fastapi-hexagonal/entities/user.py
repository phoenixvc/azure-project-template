from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    """User domain entity"""
    id: Optional[int]
    email: str
    name: str
    password_hash: str
    created_at: datetime
    updated_at: datetime
    
    def is_valid_email(self) -> bool:
        return '@' in self.email and '.' in self.email.split('@')[1]
