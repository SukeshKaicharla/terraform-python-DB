import mysql.connector
from mysql.connector import Error
import time

DB_HOST = "13.201.21.35"  # Public IP of your EC2
DB_USER = "root"
DB_PASSWORD = "root"
DB_NAME = "company"

# ----------------------------------------
# Connect with Retry Logic
# ----------------------------------------
def get_connection(retries=10, delay=5):
    for attempt in range(1, retries + 1):
        try:
            print(f"[INFO] Connecting to MySQL (Attempt {attempt}/{retries})...")
            conn = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD 
            )
            print("[SUCCESS] Connected to MySQL server.")
            return conn
        except Error as e:
            print(f"[WARN] Connection failed: {e}")
            time.sleep(delay)
    raise Exception("[ERROR] Could not connect to MySQL after multiple attempts.")

# ----------------------------------------
# Ensure DB & Table Exist
# ----------------------------------------
def setup_database(cursor):
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME};")
    cursor.execute(f"USE {DB_NAME};")
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS employees (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) UNIQUE,
            department VARCHAR(50)
        );
    """)
    print("[INFO] Database & table ready.")

# ----------------------------------------
# Insert Employees if not exist
# ----------------------------------------
def insert_employees(cursor, conn):
    employees = [
        ("Sukesh", "Engineering"),
        ("Harsha", "Finance"),
        ("Kranthi", "HR"),
        ("Abhi", "Security"),
        ("Venky", "Education"),
    ]

    sql = "INSERT IGNORE INTO employees (name, department) VALUES (%s, %s);"

    cursor.executemany(sql, employees)
    conn.commit()
    print("[INFO] Data inserted (duplicates skipped).")

# ----------------------------------------
# Display Data
# ----------------------------------------
def display_employees(cursor):
    cursor.execute("SELECT * FROM employees;")
    rows = cursor.fetchall()

    print("\n--- Employee Table ---")
    for row in rows:
        print(f"ID={row[0]}, Name={row[1]}, Dept={row[2]}")
    print("----------------------\n")

# ----------------------------------------
# Main Execution
# ----------------------------------------
try:
    conn = get_connection()
    cursor = conn.cursor()

    setup_database(cursor)
    insert_employees(cursor, conn)
    display_employees(cursor)

except Exception as e:
    print(f"[FATAL] Script failed: {e}")

finally:
    if cursor:
        cursor.close()
    if conn:
        conn.close()
    print("[INFO] Script finished.")
