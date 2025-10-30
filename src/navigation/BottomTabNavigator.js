// BottomTabNavigator.tsx
import React from "react";
import {
  View,
  TouchableOpacity,
  StyleSheet,
  Platform,
} from "react-native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { Ionicons } from "@expo/vector-icons";
import colors from "../constants/colors";

// Screens
import HomeDashboard from "../screens/core/HomeDashboard";
import UploadPrescription from "../screens/core/UploadPrescription";
import RecordConsultation from "../screens/core/RecordConsultation";
import Reminders from "../screens/core/Reminders";
import ProfileScreen from "../screens/Auth/ProfileScreen";

const Tab = createBottomTabNavigator();

/* ------------------------------------------------------------------ */
/*  Custom tabBar – 5 slots, the centre one is the floating + button  */
/* ------------------------------------------------------------------ */
function CustomTabBar({ state, descriptors, navigation }) {
  const totalTabs = state.routes.length; // 5
  const centerIndex = Math.floor(totalTabs / 2); // 2

  return (
    <View style={styles.tabBarContainer}>
      {state.routes.map((route, index) => {
        const { options } = descriptors[route.key];
        const isFocused = state.index === index;

        // ---------- centre (floating) button ----------
        if (index === centerIndex) {
          return (
            <View key={route.key} style={styles.centerButtonWrapper}>
              <TouchableOpacity
                style={styles.centerButton}
                onPress={() => navigation.navigate("UploadPrescription")}
              >
                <Ionicons name="add" size={36} color="#fff" />
              </TouchableOpacity>
            </View>
          );
        }

        // ---------- normal tabs ----------
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

        return (
          <TouchableOpacity
            key={route.key}
            style={styles.tabButton}
            onPress={onPress}
            accessibilityRole="button"
            accessibilityState={isFocused ? { selected: true } : {}}
          >
            <Ionicons
              name={iconName}
              size={26}
              color={isFocused ? colors.primary : "#999"}
            />
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

/* ------------------------------------------------------------------ */
export default function BottomTabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
      }}
      tabBar={props => <CustomTabBar {...props} />}
    >
      <Tab.Screen name="Home" component={HomeDashboard} />
      <Tab.Screen name="RecordConsultation" component={RecordConsultation} />
      {/* The centre screen is just a placeholder – it will never be rendered */}
      <Tab.Screen
        name="UploadPrescription"
        component={UploadPrescription}
        listeners={({ navigation }) => ({
          tabPress: e => {
            // Prevent the default navigation – we handle it in the custom bar
            e.preventDefault();
            navigation.navigate("UploadPrescription");
          },
        })}
      />
      <Tab.Screen name="Reminders" component={Reminders} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}

/* ------------------------------------------------------------------ */
// BottomTabNavigator.tsx - Fix navbar position
const styles = StyleSheet.create({
  tabBarContainer: {
    position: "absolute",
    bottom: 0, // Changed to 0 to stick to bottom
    left: 0, // Changed to full width
    right: 0,
    height: 80, // Increased height for better spacing
    backgroundColor: "#fff",
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: -3 }, // Shadow on top
    shadowRadius: 8,
    elevation: 10,
    paddingHorizontal: 20, // Increased padding
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  tabButton: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    height: '100%',
  },
  centerButtonWrapper: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    height: '100%',
  },
  centerButton: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: colors.primary || "#5EC0FF",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 10,
  },
});