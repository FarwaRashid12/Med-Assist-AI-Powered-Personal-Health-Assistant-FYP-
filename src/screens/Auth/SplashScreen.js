import React, { useEffect } from "react";
import { View, Image, Text, StyleSheet, StatusBar } from "react-native";

export default function SplashScreen({ navigation }) {
  useEffect(() => {
    const timer = setTimeout(() => navigation.replace("Onboarding"), 2500);
    return () => clearTimeout(timer);
  }, [navigation]);

  return (
    <View style={styles.container}>
      <StatusBar backgroundColor="#0077B6" barStyle="light-content" />
      <Image
        source={require("../../assets/icons/medassist_logo.png")}
        style={styles.logo}
        resizeMode="contain"
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
    paddingBottom: 60,
  },
  logo: {
    width: 160,
    height: 160,
    marginBottom: 20,
  },
  text: {
    fontSize: 32,
    fontWeight: "700",
    color: "#FFFFFF",
    marginTop: 10,
    letterSpacing: 1,
  },
  sub: {
    fontSize: 16,
    color: "#CAF0F8",
    marginTop: 6,
    opacity: 0.9,
  },
});
