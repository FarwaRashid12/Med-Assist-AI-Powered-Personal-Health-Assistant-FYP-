import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import ProfileScreen from "../screens/Auth/ProfileScreen";
import SettingsScreen from "../screens/Auth/SettingsScreen";
import ProgressReport from "../screens/Health/ProgressReport";
import EmergencyContact from "../screens/Health/EmergencyContact";

const Stack = createStackNavigator();

export default function ProfileStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="ProfileMain" component={ProfileScreen} />
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
      <Stack.Screen
        name="ProgressReport"
        component={ProgressReport}
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="EmergencyContact"
        component={EmergencyContact}
        options={{
          headerShown: false,
        }}
      />
    </Stack.Navigator>
  );
}
