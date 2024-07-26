import psycopg2
from faker import Faker

# Database connection parameters
DB_PARAMS = {
    'dbname': 'demo_db',
    'user': 'postgres',
    'password': 'kuITJlWWRT',  # Change this to your password
    'host': '127.0.0.1',   # Change this to your external IP or service IP
    'port': '5432'      # Change this to your NodePort
}

def create_database_and_tables():
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        dbname='postgres',
        user=DB_PARAMS['user'],
        password=DB_PARAMS['password'],
        host=DB_PARAMS['host'],
        port=DB_PARAMS['port']
    )
    conn.autocommit = True
    cursor = conn.cursor()

    # Create the database
    cursor.execute(f"CREATE DATABASE {DB_PARAMS['dbname']};")
    conn.close()

    # Connect to the new database
    conn = psycopg2.connect(**DB_PARAMS)
    cursor = conn.cursor()

    # Create tables
    cursor.execute("""
        CREATE TABLE parent (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100)
        );
    """)
    
    cursor.execute("""
        CREATE TABLE child (
            id SERIAL PRIMARY KEY,
            parent_id INTEGER REFERENCES parent(id),
            description VARCHAR(100)
        );
    """)
    conn.commit()
    conn.close()
    print("Database and tables created successfully.")

def insert_fake_data():
    # Connect to the database
    conn = psycopg2.connect(**DB_PARAMS)
    cursor = conn.cursor()
    fake = Faker()

    # Insert 100,000 records
    for _ in range(100000):
        cursor.execute("INSERT INTO parent (name) VALUES (%s) RETURNING id;", (fake.name(),))
        parent_id = cursor.fetchone()[0]
        cursor.execute("INSERT INTO child (parent_id, description) VALUES (%s, %s);", (parent_id, fake.text(max_nb_chars=100)))
    
    conn.commit()
    conn.close()
    print(f"Inserted 100,000 records into parent and child tables.")

if __name__ == "__main__":
    create_database_and_tables()
    insert_fake_data()
