# config.py
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from a .env file

TESSERACT_PATH = os.getenv("TESSERACT_PATH", "C:/Program Files/Tesseract-OCR/tesseract.exe")