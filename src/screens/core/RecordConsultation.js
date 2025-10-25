import React from "react";
import { View, Text, StyleSheet } from "react-native";
import colors from "../../constants/colors";

export default function RecordConsultation() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>🎙 Record Consultation</Text>
      <Text style={styles.text}>
        This is where you’ll record or upload doctor–patient conversations.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: colors.background,
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    color: colors.primary,
    marginBottom: 10,
  },
  text: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: "center",
    width: "80%",
  },
});