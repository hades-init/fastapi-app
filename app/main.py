from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import posts, users, login, vote



# Create database tables from models 
# (by default, will not attempt to recreate tables that already exist in target database)
# 
# from app.core.database import Base
# Base.metadata.create_all(bind=engine)
# 
# NOTE: Use alembic to create database schemas/tables



# Initialize the application 
app = FastAPI()

# Configure CORS Policy
# Domains that can access the API
origins = ["*"]

# Add CORS middleware to app
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include an APIRouter in the same app
app.include_router(login.router)
app.include_router(posts.router)
app.include_router(users.router)
app.include_router(vote.router)

# Health-check
@app.get("/health-check")
def health_check():
    return {"status": "Ok"}
