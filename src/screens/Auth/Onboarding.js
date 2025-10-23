import React from "react";
import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { Video } from "expo-av";

export default function Onboarding({ navigation }) {
  return (
    
    <View style={styles.container}>
      

      {/* 🎥 Background Video */}
     <Video
  source={require("../../assets/videos/health_intro.mp4")}
  style={styles.video}
  shouldPlay
  isLooping
  resizeMode="contain"   // ✅ changed from "cover" to "contain"
  muted
/>




      {/* 🩺 Overlay Content */}
      <View style={styles.overlay}>
        <Text style={styles.title}>Welcome to Med-Assist</Text>
        <Text style={styles.desc}>
          Stay on track with your medications, monitor vitals, and receive
          bilingual reminders in Urdu & English.
        </Text>

        <TouchableOpacity
          style={styles.button}
          onPress={() => navigation.replace("Login")}
        >
          <Text style={styles.buttonText}>Get Started</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0077B6",
  },
 video: {
  width: "100%",
  height: 400,          // or adjust based on your video height
  alignSelf: "center",
  marginBottom: 20,
},
  overlay: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  title: {
    fontSize: 30,
    fontWeight: "700",
    color: "#FFFFFF",
    marginBottom: 15,
    textAlign: "center",
  },
  desc: {
    fontSize: 16,
    color: "#CAF0F8",
    textAlign: "center",
    lineHeight: 22,
    marginBottom: 50,
  },
  button: {
    backgroundColor: "#00B4D8",
    paddingVertical: 14,
    paddingHorizontal: 80,
    borderRadius: 40,
    shadowColor: "#000",
    shadowOpacity: 0.25,
    shadowRadius: 6,
    elevation: 3,
  },
  buttonText: { color: "#fff", fontWeight: "600", fontSize: 16 },
});
