import React from "react";
import { View, Text, StyleSheet, Image, TouchableOpacity } from "react-native";

export default function Onboarding({ navigation }) {
  return (
    <View style={styles.container}>
      <Image
        source={require("../../../assets/images/onboard_health.png")}
        style={styles.image}
      />
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
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F9FAFB",
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
  },
  image: { width: 260, height: 260, marginBottom: 30 },
  title: { fontSize: 28, fontWeight: "700", color: "#0077B6", marginBottom: 15 },
  desc: {
    fontSize: 16,
    color: "#555",
    textAlign: "center",
    lineHeight: 22,
    marginBottom: 40,
  },
  button: {
    backgroundColor: "#00B4D8",
    paddingVertical: 14,
    paddingHorizontal: 80,
    borderRadius: 40,
  },
  buttonText: { color: "#fff", fontWeight: "600", fontSize: 16 },
});