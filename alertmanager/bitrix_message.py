from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Replace with your Bitrix24 webhook URL (but don't include the message in it)
BITRIX_WEBHOOK_BASE = "https://idrakai.bitrix24.com/rest/1/n5p8fvongc3zjpq7/im.message.add.json"

@app.route("/alert", methods=["POST"])
def receive_alert():
    data = request.get_json()
    alerts = data.get("alerts", [])

    for alert in alerts:
        status = alert.get("status", "firing")
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})

        alertname = labels.get("alertname", "No Alert Name")
        instance = labels.get("instance", "Unknown Instance")
        summary = annotations.get("summary", "")
        description = annotations.get("description", "")

        # Customize your message here
        message = f"⚠️ [{status.upper()}] {alertname} on {instance}\nSummary: {summary}\nDescription: {description}"

        payload = {
            "DIALOG_ID": "chat2565",  # Replace with your group ID
            "MESSAGE": message,
            "SYSTEM": "Y"
        }

        response = requests.post(BITRIX_WEBHOOK_BASE, json=payload)
        print(f"Sent to Bitrix: {response.status_code}, {response.text}")

    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
