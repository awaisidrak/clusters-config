import time
import requests
import json
from hashlib import sha256

# === CONFIGURATION ===
ALERTMANAGER_URL = "http://65.21.159.98:32223/api/v2/alerts"
BITRIX_WEBHOOK_URL = "https://idrakai.bitrix24.com/rest/1/n5p8fvongc3zjpq7/im.message.add.json"
BITRIX_DIALOG_ID = "chat2565"
POLL_INTERVAL = 30  # seconds

# === State ===
sent_alerts = set()

def hash_alert(alert):
    # Create a unique hash per alert to avoid duplicates
    return sha256(json.dumps(alert, sort_keys=True).encode()).hexdigest()

def format_message(alert):
    labels = alert.get("labels", {})
    annotations = alert.get("annotations", {})
    return (
        f"🚨 *Alert:* {labels.get('alertname', 'N/A')}\n"
        f"🧭 *Severity:* {labels.get('severity', 'unknown')}\n"
        f"📝 *Description:* {annotations.get('description', 'No description')}\n"
        f"📌 *Instance:* {labels.get('instance', 'unknown')}"
    )

def send_to_bitrix(message):
    payload = {
        "DIALOG_ID": BITRIX_DIALOG_ID,
        "MESSAGE": message,
        "SYSTEM": "Y"
    }
    headers = {"Content-Type": "application/json"}
    response = requests.post(BITRIX_WEBHOOK_URL, headers=headers, json=payload)
    if response.status_code != 200:
        print(f"❌ Failed to send alert to Bitrix: {response.text}")
    else:
        print("✅ Alert sent to Bitrix")

def poll_alertmanager():
    try:
        response = requests.get(ALERTMANAGER_URL, timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"⚠️ Error fetching alerts: {e}")
        return []

def main():
    print("🚀 Starting Alertmanager-to-Bitrix bridge...")
    while True:
        alerts = poll_alertmanager()
        for alert in alerts:
            if alert.get("status") != "firing":
                continue
            alert_id = hash_alert(alert)
            if alert_id not in sent_alerts:
                message = format_message(alert)
                send_to_bitrix(message)
                sent_alerts.add(alert_id)
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
