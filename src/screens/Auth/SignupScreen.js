import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
  Modal,
  FlatList,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { createUserWithEmailAndPassword, updateProfile } from "firebase/auth";
import { ref, set } from "firebase/database";
import { auth, db } from "../../context/firebaseConfig";
import { Ionicons } from "@expo/vector-icons";
import colors from "../../constants/colors";

const genderOptions = ["Male", "Female", "Other"];

export default function SignupScreen({ navigation }) {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [gender, setGender] = useState("");
  const [age, setAge] = useState("");
  const [loading, setLoading] = useState(false);
  const [showGenderDropdown, setShowGenderDropdown] = useState(false);

  const handleSignup = async () => {
    if (!fullName || !email || !password || !confirmPassword || !gender || !age) {
      Alert.alert("Error", "All fields are required!");
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert("Error", "Passwords do not match!");
      return;
    }
    
    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum < 1 || ageNum > 150) {
      Alert.alert("Error", "Please enter a valid age (1-150)");
      return;
    }

    setLoading(true);
    try {
      // ✅ Create user in Firebase Authentication
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // ✅ Save user data to Realtime Database
      await set(ref(db, `users/${user.uid}`), {
        fullName,
        email,
        gender,
        age: ageNum,
        createdAt: new Date().toISOString(),
      });

      // ✅ Update Firebase Auth profile
      await updateProfile(user, { displayName: fullName });

      Alert.alert("Success", "Account created successfully!");
      navigation.replace("Login");
    } catch (error) {
      // Handle different Firebase auth errors with user-friendly messages
      const errorCode = error.code || "";
      const errorMessage = error.message || "";

      if (errorCode === "auth/invalid-email" || errorMessage.includes("auth/invalid-email")) {
        Alert.alert(
          "Signup Failed",
          "Incorrect email format. Please enter a valid email address."
        );
      } else if (errorCode === "auth/email-already-in-use" || errorMessage.includes("auth/email-already-in-use")) {
        Alert.alert(
          "Signup Failed",
          "This email is already registered. Please try logging in instead."
        );
      } else if (errorCode === "auth/weak-password" || errorMessage.includes("auth/weak-password")) {
        Alert.alert(
          "Signup Failed",
          "Password is too weak. Please use a stronger password (at least 6 characters)."
        );
      } else if (errorCode === "auth/operation-not-allowed" || errorMessage.includes("auth/operation-not-allowed")) {
        Alert.alert(
          "Signup Failed",
          "Signup is currently disabled. Please contact support."
        );
      } else {
        Alert.alert(
          "Signup Failed",
          "Unable to create account. Please check your information and try again."
        );
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>New Account</Text>

        <Text style={styles.label}>Full Name</Text>
        <TextInput
          style={styles.input}
          placeholder="John Doe"
          placeholderTextColor="#9CA3AF"
          value={fullName}
          onChangeText={setFullName}
        />

        <Text style={styles.label}>Email</Text>
        <TextInput
          style={styles.input}
          placeholder="example@gmail.com"
          placeholderTextColor="#9CA3AF"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
        />

        <Text style={styles.label}>Password</Text>
        <TextInput
          style={styles.input}
          placeholder="********"
          placeholderTextColor="#9CA3AF"
          secureTextEntry
          value={password}
          onChangeText={setPassword}
        />

        <Text style={styles.label}>Confirm Password</Text>
        <TextInput
          style={styles.input}
          placeholder="********"
          placeholderTextColor="#9CA3AF"
          secureTextEntry
          value={confirmPassword}
          onChangeText={setConfirmPassword}
        />

        <Text style={styles.label}>Gender</Text>
        <TouchableOpacity
          style={styles.dropdown}
          onPress={() => setShowGenderDropdown(true)}
        >
          <Text style={[styles.dropdownText, !gender && styles.dropdownPlaceholder]}>
            {gender || "Select Gender"}
          </Text>
          <Ionicons name="chevron-down" size={20} color="#9CA3AF" />
        </TouchableOpacity>

        {/* Gender Dropdown Modal */}
        <Modal
          visible={showGenderDropdown}
          transparent={true}
          animationType="fade"
          onRequestClose={() => setShowGenderDropdown(false)}
        >
          <TouchableOpacity
            style={styles.modalOverlay}
            activeOpacity={1}
            onPress={() => setShowGenderDropdown(false)}
          >
            <View style={styles.dropdownModal} onStartShouldSetResponder={() => true}>
              <FlatList
                data={genderOptions}
                keyExtractor={(item) => item}
                renderItem={({ item }) => (
                  <TouchableOpacity
                    style={[
                      styles.dropdownOption,
                      gender === item && styles.dropdownOptionSelected,
                    ]}
                    onPress={() => {
                      setGender(item);
                      setShowGenderDropdown(false);
                    }}
                  >
                    <Text
                      style={[
                        styles.dropdownOptionText,
                        gender === item && styles.dropdownOptionTextSelected,
                      ]}
                    >
                      {item}
                    </Text>
                  </TouchableOpacity>
                )}
              />
            </View>
          </TouchableOpacity>
        </Modal>

        <Text style={styles.label}>Age</Text>
        <TextInput
          style={styles.input}
          placeholder="Enter your age"
          placeholderTextColor="#9CA3AF"
          value={age}
          onChangeText={setAge}
          keyboardType="numeric"
          maxLength={3}
        />

        <TouchableOpacity
          style={styles.button}
          onPress={handleSignup}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {loading ? "Creating..." : "Sign Up"}
          </Text>
        </TouchableOpacity>

        <Text style={styles.footer}>
          Already have an account?{" "}
          <Text
            style={styles.link}
            onPress={() => navigation.navigate("Login")}
          >
            Log In
          </Text>
        </Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff", padding: 20 },
  scroll: { flexGrow: 1, justifyContent: "center" },
  title: { fontSize: 22, fontWeight: "700", textAlign: "center", marginBottom: 20,   color: "#0077b6", },
  label: { fontWeight: "600", marginTop: 10 , color: colors.textDark,},
  input: {
    backgroundColor: "#EEF6FB",
    borderRadius: 30,
    padding: 12,
    marginTop: 5,
  },
  button: {
    backgroundColor: "#0077b6",
    borderRadius: 40,
    paddingVertical: 15,
    alignItems: "center",
    marginTop: 25,
  },
  buttonText: { color: "#fff", fontWeight: "700", fontSize: 16 },
  dropdown: {
    backgroundColor: "#EEF6FB",
    borderRadius: 30,
    padding: 12,
    marginTop: 5,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  dropdownText: {
    fontSize: 16,
    color: colors.textDark,
  },
  dropdownPlaceholder: {
    color: "#9CA3AF",
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "center",
  },
  dropdownModal: {
    backgroundColor: "#fff",
    borderRadius: 12,
    width: "80%",
    maxWidth: 300,
    maxHeight: 200,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  dropdownOption: {
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: "#F0F0F0",
  },
  dropdownOptionSelected: {
    backgroundColor: "#EEF6FB",
  },
  dropdownOptionText: {
    fontSize: 16,
    color: colors.textDark,
  },
  dropdownOptionTextSelected: {
    color: "#0077b6",
    fontWeight: "600",
  },
  footer: { textAlign: "center", marginTop: 20, color: "#777" },
  link: { color: "#0077b6", fontWeight: "600" },
});
