import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import HomeDashboard from "../screens/core/HomeDashboard";
import RecordConsultation from "../screens/core/RecordConsultation";
import Reminders from "../screens/core/Reminders";
import UploadPrescription from "../screens/core/UploadPrescription";

const Stack = createStackNavigator();

export default function CoreStack() {
  return (
    <Stack.Navigator
      initialRouteName="HomeDashboard"
      screenOptions={{ headerShown: false }}
    >
      <Stack.Screen name="HomeDashboard" component={HomeDashboard} />
      <Stack.Screen name="RecordConsultation" component={RecordConsultation} />
      <Stack.Screen name="Reminders" component={Reminders} />
      <Stack.Screen name="UploadPrescription" component={UploadPrescription} />
    </Stack.Navigator>
  );
}