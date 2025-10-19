import React, { useEffect } from "react";
import { View, Image, Text, StyleSheet } from "react-native";

export default function SplashScreen({ navigation }) {
  useEffect(() => {
    const timer = setTimeout(() => navigation.replace("Onboarding"), 2500);
    return () => clearTimeout(timer);
  }, [navigation]);

  return (
    <View style={styles.container}>
      <Image
        source={require("../../../assets/icons/medassist_logo.jpg")}
        style={styles.logo}
      />
      <Text style={styles.text}>Med-Assist</Text>
      <Text style={styles.sub}>Your Personal Health Companion</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0077B6",
    alignItems: "center",
    justifyContent: "center",
  },
  logo: { width: 150, height: 150, marginBottom: 20 },
  text: { fontSize: 32, fontWeight: "700", color: "#fff" },
  sub: { fontSize: 16, color: "#CAF0F8", marginTop: 5 },
});