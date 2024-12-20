import random
# Function to generate random Vietnamese names
def generate_name():
    first_names = ["Nguyen", "Tran", "Le", "Pham", "Hoang", "Phan", "Vu", "Dang", "Do", "Bui"]
    middle_names = ["Van", "Thi", "Ngoc", "Quoc", "Minh", "Bao", "Duy", "Huu", "Thanh", "Anh"]
    last_names = ["Anh", "Binh", "Duy", "Phuc", "Nam", "Ha", "Linh", "Son", "Trang", "Huong"]
    return f"{random.choice(first_names)} {random.choice(middle_names)} {random.choice(last_names)}"

# Function to generate a random phone number
def generate_phone():
    prefix = random.choice(["091", "090", "092", "093", "096", "097", "098"])
    return f"{prefix}{random.randint(1000000, 9999999)}"

# Function to generate random email
def generate_email(name):
    email_providers = ["@gmail.com", "@yahoo.com", "@example.com", "@hotmail.com"]
    name_part = name.lower().replace(" ", ".")
    return f"{name_part}{random.choice(email_providers)}"

# Function to generate gender
def generate_gender():
    return random.choice(["Nam", "Nữ", "Khác"])

# Generate SQL statements for 100,000 customers
output_file = "insert_khachhang_100k_corrected.sql"
with open(output_file, "w", encoding="utf-8") as file:
    for i in range(1, 100001):
        so_cccd = f"123456{str(i).zfill(6)}"  # Ensure exactly 12 digits
        name = generate_name()
        phone = generate_phone()
        email = generate_email(name)
        gender = generate_gender()

        # Write the SQL insert statement to the file
        file.write(
            f"INSERT INTO KhachHang (SoCCCD, SoDienThoai, Email, HoTen, GioiTinh) VALUES ('{so_cccd}', '{phone}', '{email}', '{name}', '{gender}');\n"
        )

print(f"File '{output_file}' has been created with 100,000 records.")

output_file = "insert_ban.sql"

# Mở file để ghi dữ liệu
with open(output_file, "w", encoding="utf-8") as file:
    for chi_nhanh in range(1, 16):  # Mã chi nhánh từ 1 đến 15
        for ban in range(1, 41):  # Mã số bàn từ 1 đến 40
            ma_so_ban = ban
            ma_chi_nhanh = chi_nhanh
            trang_thai = 0  # Trạng thái mặc định là 0
            suc_chua = random.randint(2, 20)  # Sức chứa từ 2 đến 20

            # Tạo câu lệnh SQL
            sql = f"INSERT INTO Ban (MaSoBan, MaChiNhanh, TrangThai, SucChua) VALUES ({ma_so_ban}, {ma_chi_nhanh}, {trang_thai}, {suc_chua});"

            # Ghi vào file
            file.write(sql + "\n")

print(f"File '{output_file}' đã được tạo thành công với các câu lệnh INSERT.")