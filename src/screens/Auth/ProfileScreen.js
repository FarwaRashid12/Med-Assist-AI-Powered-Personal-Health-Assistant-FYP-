import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  ScrollView,
  Alert,
} from "react-native";
import * as Contacts from "expo-contacts";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Ionicons } from "@expo/vector-icons";
import { signOut } from "firebase/auth";
import { ref, onValue, update } from "firebase/database";

import { auth, db } from "../../context/firebaseConfig";
import colors from "../../constants/colors";

export default function ProfileScreen({ navigation }) {
  const [userData, setUserData] = useState(null);
  const [theme, setTheme] = useState("light");

  useEffect(() => {
    const user = auth.currentUser;
    if (user) {
      const userRef = ref(db, `users/${user.uid}`);
      const unsubscribe = onValue(userRef, (snapshot) => {
        if (snapshot.exists()) {
          setUserData(snapshot.val());
        } else {
          setUserData({
            fullName: user.displayName || "User",
            phone: user.phoneNumber || "N/A",
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

  const handleEmergencyContact = async () => {
    const { status } = await Contacts.requestPermissionsAsync();
    if (status !== "granted") {
      Alert.alert("Permission Denied", "Please allow access to contacts.");
      return;
    }

    const { data } = await Contacts.getContactsAsync({
      fields: [Contacts.Fields.PhoneNumbers],
    });

    if (data.length > 0) {
      const selected = data[0];
      const phone = selected.phoneNumbers?.[0]?.number || "N/A";
      const user = auth.currentUser;
      if (!user) return;

      await update(ref(db, `users/${user.uid}/emergencyContacts`), {
        name: selected.name,
        phone,
      });

      Alert.alert("Saved", `${selected.name} added as emergency contact.`);
    } else {
      Alert.alert("No Contacts Found");
    }
  };

  const handleLogout = async () => {
    await signOut(auth);
    navigation.replace("Login");
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>My Profile</Text>

      <View style={styles.profileBox}>
        <Image
          source={require("../../assets/images/profile_user.png")}
          style={styles.avatar}
        />
        <Text style={styles.name}>{userData?.fullName || "Patient"}</Text>
        <Text style={styles.phone}>{userData?.phone || "N/A"}</Text>
      </View>

      <View style={styles.menuContainer}>
        <MenuItem
          icon="call"
          text="Emergency Contact"
          onPress={handleEmergencyContact}
        />
        <MenuItem
          icon="color-palette"
          text={`App Appearance (${theme})`}
          onPress={toggleTheme}
        />
        <MenuItem
          icon="settings"
          text="Settings"
          onPress={() => navigation.navigate("Settings")}
        />
        <MenuItem icon="log-out" text="Logout" onPress={handleLogout} />
      </View>
    </ScrollView>
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
  },
  profileBox: {
    alignItems: "center",
    marginVertical: 25,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
    borderWidth: 3,
    borderColor: colors.primary,
  },
  name: {
    fontSize: 18,
    fontWeight: "700",
    color: colors.textDark,
    marginTop: 10,
  },
  phone: {
    fontSize: 15,
    color: colors.textLight,
    marginTop: 2,
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
});
