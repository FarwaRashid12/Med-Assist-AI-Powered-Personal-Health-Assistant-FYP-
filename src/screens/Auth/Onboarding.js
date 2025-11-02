import React, { useRef } from "react";
import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { Video } from "expo-av";
import { useNavigation } from "@react-navigation/native"; // ✅ for reliable navigation
import colors from "../../constants/colors";

export default function Onboarding() {
  const navigation = useNavigation();
  const videoRef = useRef(null);

  return (
    <View style={styles.container}>
      {/* 🎥 Fullscreen Background Video */}
      <Video
        ref={videoRef}
        source={require("../../assets/videos/health_intro.mp4")}
        style={styles.video}
        shouldPlay
        isLooping
        resizeMode="cover"
        isMuted
        rate={1.0}
      />

      {/* Transparent overlay for interactions */}
      <View style={styles.overlay}>
        <Text style={styles.title}>Welcome to Med-Assist</Text>
        <Text style={styles.desc}>
          Stay on track with your medications, monitor vitals, and receive
          bilingual reminders in Urdu & English.
        </Text>

        <TouchableOpacity
          style={styles.button}
          activeOpacity={0.8}
          onPress={() => navigation.replace("Login")} // ✅ works even from stack or tab
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
    backgroundColor: colors.primary,
  },
  video: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    width: "100%",
    height: "100%",
  },
  overlay: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 24,
    backgroundColor: "rgba(0, 0, 0, 0.4)", // ✅ ensures touchable works
  },
  title: {
    fontSize: 30,
    fontWeight: "700",
    color: colors.white,
    marginBottom: 15,
    textAlign: "center",
  },
  desc: {
    fontSize: 16,
    color: "#CAF0F8",
    textAlign: "center",
    lineHeight: 22,
    marginBottom: 40,
  },
  button: {
    backgroundColor: colors.accent,
    paddingVertical: 14,
    paddingHorizontal: 70,
    borderRadius: 40,
    elevation: 5,
  },
  buttonText: {
    color: colors.white,
    fontWeight: "600",
    fontSize: 16,
  },
});
