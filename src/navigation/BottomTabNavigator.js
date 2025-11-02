import React from "react";
import { View, TouchableOpacity, StyleSheet, Platform } from "react-native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { Ionicons } from "@expo/vector-icons";
import colors from "../constants/colors";

// Screens
import ProfileStack from "./ProfileStack"; 
import HomeDashboard from "../screens/core/HomeDashboard";
import UploadPrescription from "../screens/core/UploadPrescription";
import RecordConsultation from "../screens/core/RecordConsultation";
import Reminders from "../screens/core/Reminders";

const Tab = createBottomTabNavigator();

/* ------------------------------------------------------------------ */
/* Custom TabBar – Center Floating (+) Button                         */
/* ------------------------------------------------------------------ */
function CustomTabBar({ state, descriptors, navigation }) {
  const totalTabs = state.routes.length;
  const centerIndex = Math.floor(totalTabs / 2);

  return (
    <View style={styles.tabBarContainer}>
      {state.routes.map((route, index) => {
        const { options } = descriptors[route.key];
        const isFocused = state.index === index;

        // Center Floating + Button
        if (index === centerIndex) {
          return (
            <View key={route.key} style={styles.centerButtonWrapper}>
              <TouchableOpacity
                activeOpacity={0.85}
                style={styles.centerButton}
                onPress={() => navigation.navigate("UploadPrescription")}
              >
                <Ionicons name="add" size={30} color={colors.white} />
              </TouchableOpacity>
            </View>
          );
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
            <Ionicons name={iconName} size={26} color={iconColor} />
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

/* ------------------------------------------------------------------ */
/* Styles */
/* ------------------------------------------------------------------ */
const styles = StyleSheet.create({
  tabBarContainer: {
    position: "absolute",
    bottom: Platform.OS === "android" ? 12 : 25,
    left: 20,
    right: 20,
    height: 70,
    borderRadius: 35,
    backgroundColor: colors.white,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-around",
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: -2 },
    shadowRadius: 10,
    elevation: 15,
  },
  tabButton: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  centerButtonWrapper: {
    position: "absolute",
    bottom: 38,
    alignSelf: "center",
  },
  centerButton: {
    width: 58,
    height: 58,
    borderRadius: 29,
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
