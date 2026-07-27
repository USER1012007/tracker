// COLLAR - ESP32-C3
// Emite beacon BLE fijo, TX power calibrado

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEBeacon.h>
#include <BLEAdvertising.h>
#include <esp_sleep.h>

#define BEACON_UUID "8ec76ea3-6668-48da-9866-75be8bc86f4d"
#define TX_POWER_CAL -59   // RSSI medido a 1m, calibrar con base real
#define MAJOR 1
#define MINOR 1

BLEAdvertising *pAdvertising;

void setup() {
  BLEDevice::init("cat_tag");
  BLEBeacon beacon;
  beacon.setManufacturerId(0x4C00);
  beacon.setProximityUUID(BLEUUID(BEACON_UUID));
  beacon.setMajor(MAJOR);
  beacon.setMinor(MINOR);
  beacon.setSignalPower(TX_POWER_CAL);

  BLEAdvertisementData advData;
  advData.setFlags(0x04);
  std::string strServiceData = "";
  strServiceData += (char)26;
  strServiceData += (char)0xFF;
  strServiceData += beacon.getData();
  advData.addData(strServiceData);

  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->setAdvertisementData(advData);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinInterval(160);  // ~100ms, balance batería/latencia
  pAdvertising->setMaxInterval(320);
  pAdvertising->start();
}

void loop() {
  delay(10000);
  // deep sleep opcional aqui si quieres alargar bateria
}
