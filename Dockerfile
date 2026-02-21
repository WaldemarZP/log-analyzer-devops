# Base image
FROM python:3.12-slim

# Installing dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copying code
COPY . .

# Running the application
CMD ["python", "log_analyzer.py", "--file", "sample.log"]
