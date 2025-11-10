import React from "react";
import { View, TouchableOpacity, StyleSheet, Platform } from "react-native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { Ionicons } from "@expo/vector-icons";
import colors from "../constants/colors";

import ProfileStack from "./ProfileStack"; 
import HomeDashboard from "../screens/core/HomeDashboard";
import UploadPrescription from "../screens/core/UploadPrescription";
import RecordConsultation from "../screens/core/RecordConsultation";
import Reminders from "../screens/core/Reminders";

const Tab = createBottomTabNavigator();

function CustomTabBar({ state, descriptors, navigation }) {
  const currentRoute = state.routes[state.index]?.name;
  const showFAB = currentRoute !== "UploadPrescription";

  return (
    <View style={styles.tabBarWrapper}>
      {showFAB && (
        <View style={styles.centerButtonWrapper}>
          <TouchableOpacity
            activeOpacity={0.85}
            style={styles.centerButton}
            onPress={() => navigation.navigate("UploadPrescription")}
          >
            <Ionicons name="add" size={28} color={colors.white} />
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.tabBarContainer}>
        {state.routes.map((route, index) => {
          const { options } = descriptors[route.key];
          const isFocused = state.index === index;

          if (route.name === "UploadPrescription") {
            return null;
          }

          const onPress = () => {
            const event = navigation.emit({
              type: "tabPress",
              target: route.key,
              canPreventDefault: true,
            });
            if (!isFocused && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          };

          const iconName = {
            Home: isFocused ? "home" : "home-outline",
            RecordConsultation: isFocused ? "mic" : "mic-outline",
            Reminders: isFocused ? "alarm" : "alarm-outline",
            Profile: isFocused ? "person" : "person-outline",
          }[route.name];

          const iconColor = isFocused ? colors.primary : "#A0A0A0";

          return (
            <TouchableOpacity
              key={route.key}
              onPress={onPress}
              style={styles.tabButton}
              accessibilityRole="button"
            >
              <Ionicons name={iconName} size={24} color={iconColor} />
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

export default function BottomTabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
      }}
      tabBar={(props) => <CustomTabBar {...props} />}
    >
      <Tab.Screen name="Home" component={HomeDashboard} />
      <Tab.Screen name="RecordConsultation" component={RecordConsultation} />
      <Tab.Screen
        name="UploadPrescription"
        component={UploadPrescription}
        listeners={({ navigation }) => ({
          tabPress: (e) => {
            e.preventDefault();
            navigation.navigate("UploadPrescription");
          },
        })}
      />
      <Tab.Screen name="Reminders" component={Reminders} />
      <Tab.Screen name="Profile" component={ProfileStack} />
    </Tab.Navigator>
  );
}

const styles = StyleSheet.create({
  tabBarWrapper: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: Platform.OS === "android" ? 76 : 83,
    pointerEvents: "box-none",
  },
  tabBarContainer: {
    position: "absolute",
    bottom: Platform.OS === "android" ? 8 : 15,
    left: 20,
    right: 20,
    height: 60,
    borderRadius: 30,
    backgroundColor: colors.white,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-around",
    paddingHorizontal: 10,
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: -2 },
    shadowRadius: 10,
    elevation: 15,
    zIndex: 1000,
    minHeight: 60,
    maxHeight: 60,
    pointerEvents: "auto",
  },
  tabButton: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  centerButtonWrapper: {
    position: "absolute",
    right: 20,
    bottom: 78,
  },
  centerButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: colors.accent,
    shadowOpacity: 0.4,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 4 },
    elevation: 8,
  },
});
