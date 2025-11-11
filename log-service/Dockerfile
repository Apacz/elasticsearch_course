FROM python:3.12-slim

WORKDIR /app
RUN pip install flask requests

COPY app.py /app/app.py

EXPOSE 5000
CMD ["python", "app.py"]
