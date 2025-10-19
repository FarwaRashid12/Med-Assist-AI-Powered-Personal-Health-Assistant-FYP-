import React from "react";
import { View, Text, StyleSheet, TouchableOpacity, Image } from "react-native";
import { signOut } from "firebase/auth";
import { auth } from "../../context/firebaseConfig"; // ✅ corrected path

export default function ProfileScreen({ navigation }) {
  const user = auth.currentUser;

  const handleLogout = async () => {
    await signOut(auth);
  };

  return (
    <View style={styles.container}>
      <Image
        source={require("../../assets/images/profile_user.png")} // ✅ corrected path
        style={styles.avatar}
      />
      <Text style={styles.name}>{user?.displayName || "Patient"}</Text>
      <Text style={styles.email}>{user?.email}</Text>

      <TouchableOpacity style={styles.button} onPress={handleLogout}>
        <Text style={styles.buttonText}>Logout</Text>
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
  avatar: { width: 120, height: 120, borderRadius: 60, marginBottom: 20 },
  name: { fontSize: 22, fontWeight: "700", color: "#0077B6" },
  email: { fontSize: 16, color: "#555", marginVertical: 6 },
  button: {
    backgroundColor: "#00B4D8",
    paddingVertical: 12,
    paddingHorizontal: 60,
    borderRadius: 40,
    marginTop: 30,
  },
  buttonText: { color: "#fff", fontWeight: "600", fontSize: 16 },
});
