# scripts/download_sample.py
import pandas as pd

# NYC TLC public dataset - January 2024 Yellow Taxi trips
url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet"

# Download and read the Parquet file
df = pd.read_parquet(url)

# Take first 10,000 rows
sample = df.head(10000)

# Save to seeds/ folder
sample.to_csv("seeds/yellow_trips_real.csv", index=False)
print("✅ Sample saved to seeds/yellow_trips_real.csv")
