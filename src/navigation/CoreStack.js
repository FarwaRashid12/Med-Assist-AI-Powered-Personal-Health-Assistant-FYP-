import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import BottomTabNavigator from "./BottomTabNavigator"; // ✅ your existing tabs
import ProgressReport from "../screens/Health/ProgressReport"; // ✅ imported health screen
import UploadPrescription from "../screens/core/UploadPrescription"; // still accessible separately if needed
import SettingsScreen from "../screens/Auth/SettingsScreen";
const Stack = createStackNavigator();

export default function CoreStack() {
  return (
    <Stack.Navigator
      initialRouteName="MainTabs"
      screenOptions={{ headerShown: false }}
    >
      {/* ✅ Your BottomTabNavigator as the main dashboard */}
      <Stack.Screen name="MainTabs" component={BottomTabNavigator} />

      {/* ✅ Extra screens (above the bottom tabs) */}
      <Stack.Screen name="ProgressReport" component={ProgressReport} />
      <Stack.Screen name="UploadPrescription" component={UploadPrescription} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
    </Stack.Navigator>
  );
}
