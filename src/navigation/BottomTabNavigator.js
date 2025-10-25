import React from "react";
import { View, TouchableOpacity, StyleSheet, Text } from "react-native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import colors from "../constants/colors";

// Screens
import HomeDashboard from "../screens/core/HomeDashboard";
import UploadPrescription from "../screens/core/UploadPrescription";
import RecordConsultation from "../screens/core/RecordConsultation";
import Reminders from "../screens/core/Reminders";
import ProfileScreen from "../screens/Auth/ProfileScreen";


const Tab = createBottomTabNavigator();

export default function BottomTabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: styles.tabBar,
      }}
    >
      {/* Home */}
      <Tab.Screen
        name="Home"
        component={HomeDashboard}
        options={{
          tabBarIcon: ({ focused }) => (
            <Ionicons
              name="home-outline"
              size={24}
              color={focused ? colors.primary : "#999"}
            />
          ),
        }}
      />

      {/* Voice Record */}
      <Tab.Screen
        name="RecordConsultation"
        component={RecordConsultation}
        options={{
          tabBarIcon: ({ focused }) => (
            <Ionicons
              name="mic-outline"
              size={24}
              color={focused ? colors.primary : "#999"}
            />
          ),
        }}
      />

      {/* Center Upload Button */}
      <Tab.Screen
        name="UploadPrescription"
        component={UploadPrescription}
        options={{
          tabBarButton: (props) => (
            <TouchableOpacity style={styles.centerButton} {...props}>
              <Ionicons name="add" size={30} color={colors.white} />
            </TouchableOpacity>
          ),
        }}
      />

      {/* Reminders */}
      <Tab.Screen
        name="Reminders"
        component={Reminders}
        options={{
          tabBarIcon: ({ focused }) => (
            <Ionicons
              name="alarm-outline"
              size={24}
              color={focused ? colors.primary : "#999"}
            />
          ),
        }}
      />

      {/* Profile */}
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          tabBarIcon: ({ focused }) => (
            <Ionicons
              name="person-outline"
              size={24}
              color={focused ? colors.primary : "#999"}
            />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    position: "absolute",
    bottom: 20,
    left: 20,
    right: 20,
    height: 70,
    borderRadius: 40,
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: 3 },
    shadowRadius: 8,
    elevation: 5,
  },
  centerButton: {
    top: -25,
    width: 65,
    height: 65,
    borderRadius: 35,
    backgroundColor: colors.primary,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOpacity: 0.25,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 6,
  },
});