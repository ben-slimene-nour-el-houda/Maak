# pdf_handler.py
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

def generate_pdf(filled_form):
    c = canvas.Canvas("filled_form.pdf", pagesize=letter)
    c.drawString(100, 750, f"Name: {filled_form['name']}")
    c.drawString(100, 730, f"Address: {filled_form['address']}")
    c.drawString(100, 710, f"DOB: {filled_form['dob']}")
    c.drawString(100, 690, f"Phone: {filled_form['phone']}")
    c.drawString(100, 670, f"CIN: {filled_form['cin']}")
    c.save()


