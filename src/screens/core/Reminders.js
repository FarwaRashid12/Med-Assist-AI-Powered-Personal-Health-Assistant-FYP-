import React from "react";
import { View, Text, StyleSheet } from "react-native";

export default function Reminders() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Reminders ⏰</Text>
      <Text style={styles.text}>You currently have no reminders set.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F8FAFF",
    alignItems: "center",
    justifyContent: "center",
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    color: "#1A73E8",
    marginBottom: 10,
  },
  text: {
    fontSize: 16,
    color: "#555",
  },
});