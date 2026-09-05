#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

int value = 0;

// Custom UUIDs (must match Flutter)
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "12345678-1234-1234-1234-123456789def"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println("Device Connected");
    }
    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println("Device Disconnected");
        pServer->startAdvertising(); // Make it discoverable again
    }
};

void setup() {
    Serial.begin(115200);

    BLEDevice::init("ESP32_SimpleInt");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
            CHARACTERISTIC_UUID,
            BLECharacteristic::PROPERTY_NOTIFY
    );
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pCharacteristic->addDescriptor(new BLE2902());
    pAdvertising->start();

    Serial.println(">>> BLE Simple Int Started");
}

void loop() {
    if (deviceConnected) {
        value = 50 + (millis() / 1000 % 100); // 50-149 integer
        uint8_t data = (uint8_t)value;
        pCharacteristic->setValue(&data, 1);
        pCharacteristic->notify();
        delay(500);
    }
}
