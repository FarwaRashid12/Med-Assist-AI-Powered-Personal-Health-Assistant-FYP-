import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
import { signInWithEmailAndPassword, fetchSignInMethodsForEmail } from "firebase/auth";
import { auth, db } from "../../context/firebaseConfig";
import { ref, get } from "firebase/database";
import colors from "../../constants/colors";

export default function LoginScreen({ navigation }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  // ✅ Handle login
  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert("Error", "Please enter both email and password.");
      return;
    }

    setLoading(true);
    // Check if email exists in Firebase Auth before attempting login
    let emailExists = false;
    try {
      const signInMethods = await fetchSignInMethodsForEmail(auth, email);
      emailExists = signInMethods && signInMethods.length > 0;
    } catch (checkError) {
      // If check fails, we can't determine if email exists
      emailExists = false;
    }

    try {
      // ✅ Authenticate using Firebase Auth
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // ✅ Fetch user data from Realtime Database
      const userRef = ref(db, `users/${user.uid}`);
      const snapshot = await get(userRef);

      if (snapshot.exists()) {
        const userData = snapshot.val();
        console.log("User Data:", userData);
        Alert.alert("Welcome!", `Hello ${userData.fullName || "User"} 👋`);
        navigation.replace("MainTabs"); // Navigate to your app's main screen
      } else {
        Alert.alert("Error", "User data not found in database.");
      }
    } catch (error) {
      // Handle different Firebase auth errors with user-friendly messages
      // Use the emailExists check we did before login attempt
      const errorCode = error.code || "";
      const errorMessage = error.message || "";

      // Check for wrong password error first
      if (errorCode === "auth/wrong-password" || errorMessage.includes("auth/wrong-password")) {
        Alert.alert(
          "Login Failed",
          "Enter correct password."
        );
      } 
      // If email exists but we got invalid-credential, it means wrong password
      else if (emailExists && (errorCode === "auth/invalid-credential" || errorMessage.includes("auth/invalid-credential"))) {
        Alert.alert(
          "Login Failed",
          "Enter correct password."
        );
      } 
      // If email doesn't exist and we got invalid-credential, it means account doesn't exist
      else if (!emailExists && (errorCode === "auth/invalid-credential" || errorMessage.includes("auth/invalid-credential"))) {
        Alert.alert(
          "Login Failed",
          "Account does not exist. Please try signing up."
        );
      } 
      // If we couldn't check email existence but got invalid-credential, show generic message
      else if (errorCode === "auth/invalid-credential" || errorMessage.includes("auth/invalid-credential")) {
        Alert.alert(
          "Login Failed",
          "Invalid email or password. Please check your credentials and try again."
        );
      } 
      else if (errorCode === "auth/user-not-found" || errorMessage.includes("auth/user-not-found")) {
        Alert.alert(
          "Login Failed",
          "Account does not exist. Please try signing up."
        );
      } 
      else if (errorCode === "auth/invalid-email" || errorMessage.includes("auth/invalid-email")) {
        Alert.alert(
          "Login Failed",
          "Invalid email format. Please check your email address."
        );
      } 
      else {
        Alert.alert(
          "Login Failed",
          "Unable to login. Please check your credentials and try again."
        );
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={styles.container}>
         {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={() => navigation.goBack()}>
              <Ionicons name="chevron-back" size={26} color={colors.primary} />
            </TouchableOpacity>
          
            <View style={{ width: 26 }} />
          </View>

          <Text style={styles.welcome}>Welcome</Text>
          <Text style={styles.subText}>
            Log in securely using your email and password.
          </Text>

          {/* Email Input */}
          <Text style={styles.label}>Email</Text>
          <TextInput
            style={styles.input}
            placeholder="example@example.com"
            placeholderTextColor="#A0AEC0"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
          />

          {/* Password Input */}
          <Text style={styles.label}>Password</Text>
          <TextInput
            style={styles.input}
            placeholder="********"
            placeholderTextColor="#A0AEC0"
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />

          {/* Login Button */}
          <TouchableOpacity
            style={styles.button}
            onPress={handleLogin}
            disabled={loading}
          >
            <Text style={styles.buttonText}>
              {loading ? "Logging in..." : "Login"}
            </Text>
          </TouchableOpacity>

          {/* Footer */}
          <Text style={styles.footer}>
            Don’t have an account?{" "}
            <Text
              style={styles.link}
              onPress={() => navigation.navigate("Signup")}
            >
              Sign Up
            </Text>
          </Text>
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: colors.background,
    padding: 25,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginTop: 20,
  },
  headerTitle: {
    color: colors.primary,
    fontSize: 18,
    fontWeight: "600",
  },
  welcome: {
    fontSize: 26,
    fontWeight: "700",
    color: colors.primary,
    marginTop: 40,
    textAlign: "center",
  },
  subText: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: "center",
    marginVertical: 15,
  },
  label: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 6,
  },
  input: {
    backgroundColor: "#EEF6FB",
    borderRadius: 30,
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: "#D0E2F2",
    color: colors.textDark,
  },
  button: {
    backgroundColor: colors.primary,
    paddingVertical: 15,
    borderRadius: 40,
    alignItems: "center",
    marginTop: 10,
  },
  buttonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "600",
  },
  footer: {
    textAlign: "center",
    color: colors.textLight,
    marginTop: 25,
  },
  link: {
    color: colors.primary,
    fontWeight: "600",
  },
});
