import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Modal,
  TextInput,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import {
  reauthenticateWithCredential,
  EmailAuthProvider,
  updatePassword,
  deleteUser,
} from "firebase/auth";
import { ref, remove } from "firebase/database";
import { auth, db } from "../../context/firebaseConfig";
import colors from "../../constants/colors";

export default function SettingsScreen({ navigation }) {
  const [modalVisible, setModalVisible] = useState(false);
  const [passwordStep, setPasswordStep] = useState("current");
  const [password, setPassword] = useState("");

  // Handle password update flow
  const handleChangePassword = async () => {
    setModalVisible(true);
    setPasswordStep("current");
    setPassword("");
  };

  const confirmPasswordChange = async () => {
    const user = auth.currentUser;
    if (!user) return;

    try {
      if (passwordStep === "current") {
        const cred = EmailAuthProvider.credential(user.email, password);
        await reauthenticateWithCredential(user, cred);
        setPassword("");
        setPasswordStep("new");
      } else if (passwordStep === "new") {
        await updatePassword(user, password);
        setModalVisible(false);
        Alert.alert("Success", "Password updated successfully!");
      }
    } catch (error) {
      console.error("Password error:", error);
      Alert.alert("Error", "Incorrect password or invalid input.");
    }
  };

  // Handle full delete (Auth + Database)
  const handleDeleteAccount = async () => {
    Alert.alert(
      "Delete Account",
      "Are you sure you want to permanently delete your account?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            try {
              const user = auth.currentUser;
              if (!user) return;
              await remove(ref(db, `users/${user.uid}`));
              await deleteUser(user);
              Alert.alert("Deleted", "Your account has been permanently deleted.");
              navigation.replace("Login");
            } catch (error) {
              console.error("Delete Error:", error);
              Alert.alert(
                "Error",
                "You may need to log in again before deleting your account."
              );
            }
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.header}>Settings</Text>

      <View style={styles.menuContainer}>
        <MenuItem
          icon="notifications-outline"
          text="Notification Setting"
          onPress={() => Alert.alert("Coming Soon")}
        />
        <MenuItem
          icon="key-outline"
          text="Change Password"
          onPress={handleChangePassword}
        />
        <MenuItem
          icon="person-remove-outline"
          text="Delete Account"
          onPress={handleDeleteAccount}
        />
      </View>

      {/* Password Modal */}
      <Modal
        transparent
        visible={modalVisible}
        animationType="slide"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>
              {passwordStep === "current" ? "Enter Current Password" : "Enter New Password"}
            </Text>
            <TextInput
              style={styles.input}
              secureTextEntry
              value={password}
              onChangeText={setPassword}
              placeholder="••••••••"
              placeholderTextColor="#aaa"
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() => setModalVisible(false)}
              >
                <Text style={styles.cancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.saveButton}
                onPress={confirmPasswordChange}
              >
                <Text style={styles.saveText}>
                  {passwordStep === "current" ? "Next" : "Save"}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const MenuItem = ({ icon, text, onPress }) => (
  <TouchableOpacity style={styles.menuItem} onPress={onPress}>
    <View style={styles.leftSection}>
      <Ionicons name={icon} size={22} color={colors.primary} />
      <Text style={styles.menuText}>{text}</Text>
    </View>
    <Ionicons name="chevron-forward" size={20} color="#aaa" />
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: 20,
  },
  header: {
    fontSize: 22,
    color: colors.primary,
    fontWeight: "700",
    textAlign: "center",
    marginTop: 40,
    marginBottom: 20,
  },
  menuContainer: {
    marginTop: 10,
    backgroundColor: colors.white,
    borderRadius: 20,
    paddingVertical: 5,
    elevation: 2,
  },
  menuItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 14,
    paddingHorizontal: 18,
    borderBottomWidth: 1,
    borderColor: "#f0f0f0",
  },
  leftSection: {
    flexDirection: "row",
    alignItems: "center",
  },
  menuText: {
    fontSize: 16,
    fontWeight: "500",
    color: colors.textDark,
    marginLeft: 15,
  },
  modalContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.4)",
  },
  modalBox: {
    backgroundColor: colors.white,
    padding: 25,
    width: "85%",
    borderRadius: 15,
    elevation: 6,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 12,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 10,
    padding: 10,
    fontSize: 16,
    color: colors.textDark,
    marginBottom: 20,
  },
  modalButtons: {
    flexDirection: "row",
    justifyContent: "flex-end",
  },
  cancelButton: {
    paddingHorizontal: 15,
    paddingVertical: 8,
  },
  cancelText: {
    color: "#999",
    fontSize: 15,
  },
  saveButton: {
    backgroundColor: colors.primary,
    borderRadius: 8,
    paddingHorizontal: 20,
    paddingVertical: 8,
  },
  saveText: {
    color: colors.white,
    fontWeight: "600",
  },
});
