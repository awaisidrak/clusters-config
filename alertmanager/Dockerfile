# Use a lightweight Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy your script
COPY bitrix_message.py .

# Install dependencies
RUN pip install flask requests

# Expose port for Flask
EXPOSE 5001

# Run the Flask app
CMD ["python", "bitrix_message.py"]
