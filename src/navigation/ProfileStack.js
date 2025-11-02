import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import ProfileScreen from "../screens/Auth/ProfileScreen";
import SettingsScreen from "../screens/Auth/SettingsScreen";
import ProgressReport from "../screens/Health/ProgressReport"; // ✅ add this line

const Stack = createStackNavigator();

export default function ProfileStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {/* 👤 Main Profile Page */}
      <Stack.Screen name="ProfileMain" component={ProfileScreen} />

      {/* ⚙️ Settings Page */}
      <Stack.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          headerShown: true,
          headerTitle: "Settings",
          headerTitleAlign: "center",
          headerTintColor: "#0077B6",
        }}
      />

      {/* 📊 Progress Report Page */}
    <Stack.Screen
  name="ProgressReport"
  component={ProgressReport}
  options={{
    headerShown: false, // ✅ hide the extra navigation header
  }}
/>

    </Stack.Navigator>
  );
}

