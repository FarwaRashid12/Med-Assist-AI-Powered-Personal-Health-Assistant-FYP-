import React, { useEffect, useState, useRef } from "react";
import {
  View,
  StyleSheet,
  TouchableOpacity,
  Text,
  Image,
  ScrollView,
  Alert,
  ActivityIndicator,
} from "react-native";
import { CameraView, useCameraPermissions } from "expo-camera";
import { Ionicons } from "@expo/vector-icons";
import * as FileSystem from "expo-file-system";
import { ref, set } from "firebase/database";
import { db } from "../../context/firebaseConfig";
import colors from "../../constants/colors";

/**
 * Expo-Go compatible Upload Prescription
 * ✔ Camera via expo-camera
 * ✔ OCR via free OCR.space API (no ML Kit)
 * ✔ Stores parsed text & reminder info in Firebase Realtime DB
 * ✖ No local notifications (Expo Go limitation)
 */
export default function UploadPrescription({ navigation }) {
  const [permission, requestPermission] = useCameraPermissions();
  const [photo, setPhoto] = useState(null);
  const [loading, setLoading] = useState(false);
  const cameraRef = useRef(null);

  useEffect(() => {
    if (!permission?.granted) requestPermission();
  }, [permission]);

  const takePicture = async () => {
    if (cameraRef.current) {
      const photoData = await cameraRef.current.takePictureAsync({ base64: true });
      setPhoto(photoData.uri);
      await processPrescription(photoData.base64);
    }
  };

  /** 🧠 Send base64 image to OCR.space API and extract data */
  const processPrescription = async (base64Image) => {
    try {
      setLoading(true);

      const apiKey = "helloworld"; // demo key; get a free one from https://ocr.space/ocrapi
      const formData = new FormData();
      formData.append("base64Image", `data:image/jpg;base64,${base64Image}`);
      formData.append("language", "eng");

      const response = await fetch("https://api.ocr.space/parse/image", {
        method: "POST",
        headers: { apikey: apiKey },
        body: formData,
      });

      const result = await response.json();
      const text = result?.ParsedResults?.[0]?.ParsedText?.toLowerCase() || "";
      console.log("Recognized Text:", text);

      const medicineMatch = text.match(/medicine\s*:\s*([a-zA-Z0-9]+)/);
      const dateMatch = text.match(/\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b/);
      const timeMatch = text.match(/\b\d{1,2}:\d{2}\s?(am|pm)?\b/);

      const medicine = medicineMatch ? medicineMatch[1] : "Unknown";
      const date = dateMatch ? dateMatch[0] : "Unknown";
      const time = timeMatch ? timeMatch[0] : "Unknown";

      await set(ref(db, `reminders/${Date.now()}`), {
        medicine,
        date,
        time,
        createdAt: new Date().toISOString(),
      });

      setLoading(false);
      Alert.alert("Saved", `📦 ${medicine} reminder stored.\nDate: ${date} Time: ${time}`);
    } catch (err) {
      setLoading(false);
      console.error("OCR error:", err);
      Alert.alert("Error", "Could not process image");
    }
  };

  if (!permission?.granted) {
    return <Text style={styles.permissionText}>Camera permission required</Text>;
  }

  return (
    <View style={styles.container}>
      {loading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color={colors.primary} />
          <Text style={{ color: colors.white, marginTop: 10 }}>Processing…</Text>
        </View>
      )}

      {!photo ? (
        <>
          <CameraView ref={cameraRef} style={styles.camera} />
          <TouchableOpacity style={styles.captureButton} onPress={takePicture}>
            <Ionicons name="camera" size={32} color="#fff" />
          </TouchableOpacity>
        </>
      ) : (
        <ScrollView contentContainerStyle={styles.resultContainer}>
          <Image source={{ uri: photo }} style={styles.preview} />
          <Text style={styles.infoText}>Prescription captured successfully.</Text>
          <TouchableOpacity style={styles.button} onPress={() => setPhoto(null)}>
            <Text style={styles.buttonText}>Capture Another</Text>
          </TouchableOpacity>
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#000" },
  camera: { flex: 1 },
  captureButton: {
    position: "absolute",
    bottom: 40,
    alignSelf: "center",
    width: 80,
    height: 80,
    backgroundColor: colors.primary,
    borderRadius: 40,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: colors.primary,
    shadowOpacity: 0.4,
    shadowRadius: 8,
  },
  resultContainer: {
    flexGrow: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.background,
    padding: 20,
  },
  preview: {
    width: "90%",
    height: 350,
    borderRadius: 12,
    marginBottom: 20,
  },
  infoText: {
    fontSize: 16,
    color: colors.textDark,
    marginBottom: 20,
    textAlign: "center",
  },
  button: {
    backgroundColor: colors.primary,
    paddingVertical: 14,
    borderRadius: 30,
    width: "80%",
    alignItems: "center",
  },
  buttonText: {
    color: colors.white,
    fontWeight: "600",
    fontSize: 16,
  },
  permissionText: {
    flex: 1,
    textAlign: "center",
    color: "#555",
    fontSize: 16,
    marginTop: 200,
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.6)",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 10,
  },
});

