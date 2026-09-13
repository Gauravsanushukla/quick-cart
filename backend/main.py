from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from pydantic import BaseModel

app = FastAPI(title="QuickCart API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Product(BaseModel):
    id: int
    name: str
    price: float
    category: str
    in_stock: bool

products_db = [
    {"id": 1, "name": "Quantum Anti-Gravity Pod", "price": 49999.0, "category": "Core", "in_stock": True},
    {"id": 2, "name": "Magnetic Levitation Boots", "price": 12499.0, "category": "Wearables", "in_stock": True},
    {"id": 3, "name": "Ion-Propulsion Thruster Mini", "price": 28999.0, "category": "Propulsion", "in_stock": False},
    {"id": 4, "name": "Zero-G Stabilizer Ring", "price": 7999.0, "category": "Accessories", "in_stock": True}
]

@app.get("/health")
def health_check():
    return {"status": "healthy", "engine": "FastAPI ASGI"}

@app.get("/api/products", response_model=List[Product])
def get_products():
    return products_db
