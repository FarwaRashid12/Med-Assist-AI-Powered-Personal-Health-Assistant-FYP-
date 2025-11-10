import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import BottomTabNavigator from "./BottomTabNavigator";
import ProgressReport from "../screens/Health/ProgressReport";
import UploadPrescription from "../screens/core/UploadPrescription";
import SettingsScreen from "../screens/Auth/SettingsScreen";
const Stack = createStackNavigator();

export default function CoreStack() {
  return (
    <Stack.Navigator
      initialRouteName="MainTabs"
      screenOptions={{ headerShown: false }}
    >
      <Stack.Screen name="MainTabs" component={BottomTabNavigator} />
      <Stack.Screen name="ProgressReport" component={ProgressReport} />
      <Stack.Screen name="UploadPrescription" component={UploadPrescription} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
    </Stack.Navigator>
  );
}
