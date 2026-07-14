# 05. Shortcut & Xcode Setup
Xcode Target -> Info -> URL Types -> + -> URL Schemes = `myassistant`

Shortcut Ablauf:
1. Screenshot aufnehmen
2. Zufallszahl (100000-999999)
3. Inhalt von URL abrufen (POST an Mac /v1/trigger mit session_id und file)
4. URL öffnen: myassistant://task?id=[Zufallszahl]
