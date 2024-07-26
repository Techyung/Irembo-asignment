import psycopg2
    from faker import Faker

    def create_database_and_tables():
        conn = psycopg2.connect(
            dbname="postgres",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
        cursor.execute("CREATE DATABASE demo_db;")
        conn.close()
        
        conn = psycopg2.connect(
            dbname="demo_db",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        cursor = conn.cursor()
        
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

    def insert_fake_data():
        conn = psycopg2.connect(
            dbname="demo_db",
            user="postgres",
            password="kuITJlWWRT",
            host="127.0.0.1",
            port="5432"
        )
        cursor = conn.cursor()
        
        fake = Faker()
        for _ in range(100000):
            cursor.execute("INSERT INTO parent (name) VALUES (%s) RETURNING id;", (fake.name(),))
            parent_id = cursor.fetchone()[0]
            cursor.execute("INSERT INTO child (parent_id, description) VALUES (%s, %s);", (parent_id, fake.text(max_nb_chars=100)))
        
        conn.commit()
        conn.close()

    if __name__ == "__main__":
        create_database_and_tables()
        insert_fake_data()
