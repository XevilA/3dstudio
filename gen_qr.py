import qrcode
import os

output_dir = "QRCodes"
os.makedirs(output_dir, exist_ok=True)

for i in range(1, 9):
    data = f"room:{i}"
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)
    
    # Orange and Dark Blue colors
    img = qr.make_image(fill_color="#FF6F00", back_color="#001A33")
    filename = os.path.join(output_dir, f"Room_{i}_QR.png")
    img.save(filename)
    
print(f"✅ Generated 8 QR Codes in {output_dir}/")
