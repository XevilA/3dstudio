import PyPDF2
import sys

try:
    reader = PyPDF2.PdfReader('รูปแบบการจัดสตูดิโอ.pdf')
    text = []
    for i, page in enumerate(reader.pages):
        text.append(f"--- PAGE {i+1} ---")
        page_text = page.extract_text()
        text.append(page_text if page_text else "[No text on this page]")
    
    with open('pdf_output.txt', 'w', encoding='utf-8') as f:
        f.write("\n".join(text))
    print("PDF extraction complete. Wrote to pdf_output.txt")
except Exception as e:
    print(f"Error reading PDF: {e}")
