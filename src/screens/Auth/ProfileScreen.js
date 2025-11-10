import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  ScrollView,
  Alert,
  Modal,
  TextInput,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { signOut } from "firebase/auth";
import { ref, onValue, remove } from "firebase/database";
import {
  reauthenticateWithCredential,
  EmailAuthProvider,
  updatePassword,
  deleteUser,
} from "firebase/auth";

import { auth, db } from "../../context/firebaseConfig";
import colors from "../../constants/colors";

export default function ProfileScreen({ navigation }) {
  const [userData, setUserData] = useState(null);
  const [theme, setTheme] = useState("light");
  const [modalVisible, setModalVisible] = useState(false);
  const [passwordStep, setPasswordStep] = useState("current");
  const [password, setPassword] = useState("");

  useEffect(() => {
    const user = auth.currentUser;
    if (user) {
      const userRef = ref(db, `users/${user.uid}`);
      const unsubscribe = onValue(userRef, (snapshot) => {
        if (snapshot.exists()) {
          setUserData({
            ...snapshot.val(),
            email: user.email || "N/A",
          });
        } else {
          setUserData({
            fullName: user.displayName || "User",
            phone: user.phoneNumber || "N/A",
            email: user.email || "N/A",
          });
        }
      });
      loadTheme();
      return () => unsubscribe();
    } else {
      navigation.replace("Login");
    }
  }, []);

  const loadTheme = async () => {
    const saved = await AsyncStorage.getItem("theme");
    if (saved) setTheme(saved);
  };

  const toggleTheme = async () => {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    await AsyncStorage.setItem("theme", newTheme);
    Alert.alert("Theme Changed", `App theme set to ${newTheme.toUpperCase()}`);
  };

  const handleEmergencyContact = () => {
    navigation.navigate("EmergencyContact");
  };

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

  const handleLogout = async () => {
    await signOut(auth);
    navigation.replace("Login");
  };

  return (
    <View style={styles.container}>
      <SafeAreaView style={styles.safeContainer} edges={['top']}>
        {/* Upper Colored Bar - Starts from top like Medication Planner */}
        <View style={styles.upperSection}>
          <View style={styles.upperLeft} />
          <View style={styles.upperRight} />
        </View>
      </SafeAreaView>

      <ScrollView style={styles.scrollContent} contentContainerStyle={styles.scrollContentContainer}>
        {/* Profile Card with Gradient */}
        <LinearGradient
          colors={[colors.primary, colors.accent]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.profileCard}
        >
          <Image
            source={require("../../assets/images/profile_user.png")}
            style={styles.avatar}
          />
          <Text style={styles.name}>{userData?.fullName || "Patient"}</Text>
          <Text style={styles.email}>{userData?.email || auth.currentUser?.email || "N/A"}</Text>
        </LinearGradient>

      {/* Menu Options */}
      <View style={styles.menuContainer}>
        <MenuItem
          icon="call"
          text="Emergency Contacts"
          onPress={handleEmergencyContact}
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
        <MenuItem icon="log-out" text="Logout" onPress={handleLogout} />
      </View>

      {/* Password Change Modal */}
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
      </ScrollView>
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
  },
  safeContainer: {
    backgroundColor: colors.primary,
  },
  upperSection: {
    flexDirection: "row",
    height: 50,
    backgroundColor: colors.primary,
    width: "100%",
  },
  upperLeft: {
    flex: 1,
    backgroundColor: colors.primary,
  },
  upperRight: {
    flex: 1,
    backgroundColor: colors.primary,
  },
  scrollContent: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContentContainer: {
    paddingTop: 10,
  },
  profileCard: {
    marginHorizontal: 20,
    marginTop: 15,
    marginBottom: 20,
    borderRadius: 20,
    padding: 30,
    paddingTop: 40,
    alignItems: "center",
    elevation: 5,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 3,
    borderColor: colors.white,
    marginBottom: 20,
  },
  name: {
    fontSize: 20,
    fontWeight: "700",
    color: colors.white,
    marginBottom: 8,
  },
  email: {
    fontSize: 14,
    color: colors.white,
    opacity: 0.9,
  },
  menuContainer: {
    marginHorizontal: 20,
    backgroundColor: colors.white,
    borderRadius: 20,
    paddingVertical: 5,
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  menuItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 16,
    paddingHorizontal: 20,
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
