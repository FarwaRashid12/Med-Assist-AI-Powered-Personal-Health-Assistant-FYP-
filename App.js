import React, { useEffect, useState } from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { View, ActivityIndicator, LogBox } from "react-native";

LogBox.ignoreLogs([
  'expo-notifications: Android Push notifications',
  'expo-notifications: Android Push notifications (remote notifications) functionality provided by expo-notifications was removed from Expo Go',
]);

const originalError = console.error;
const originalWarn = console.warn;
console.error = (...args) => {
  const message = args.join(' ');
  if (message.includes('expo-notifications') && message.includes('Android Push notifications') && message.includes('Expo Go')) {
    return;
  }
  originalError.apply(console, args);
};
console.warn = (...args) => {
  const message = args.join(' ');
  if (message.includes('expo-notifications') && message.includes('Android Push notifications') && message.includes('Expo Go')) {
    return;
  }
  originalWarn.apply(console, args);
};

import BottomTabNavigator from "./src/navigation/BottomTabNavigator";
import SplashScreen from "./src/screens/Auth/SplashScreen";
import OnboardingScreen from "./src/screens/Auth/Onboarding";
import LoginScreen from "./src/screens/Auth/LoginScreen";
import SignupScreen from "./src/screens/Auth/SignupScreen";
import ForgetPasswordScreen from "./src/screens/Auth/ForgetPasswordScreen";
import { AuthProvider } from "./src/context/AuthContext";
import colors from "./src/constants/colors";

const Stack = createNativeStackNavigator();

export default function App() {
  const [isLoading, setIsLoading] = useState(true);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 2000);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  return (
    <AuthProvider>
      <NavigationContainer>
        <Stack.Navigator screenOptions={{ headerShown: false }}>
          <Stack.Screen name="Splash" component={SplashScreen} />
          {!isLoggedIn ? (
            <>
              <Stack.Screen name="Onboarding" component={OnboardingScreen} />
              <Stack.Screen name="Login" component={LoginScreen} />
              <Stack.Screen name="Signup" component={SignupScreen} />
              <Stack.Screen
                name="ForgetPasswordScreen"
                component={ForgetPasswordScreen}
              />
            </>
          ) : null}
          <Stack.Screen name="MainTabs" component={BottomTabNavigator} />
        </Stack.Navigator>
      </NavigationContainer>
    </AuthProvider>
  );
}