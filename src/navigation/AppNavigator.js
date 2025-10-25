import React, { useState, useEffect } from "react";
import { NavigationContainer } from "@react-navigation/native";
import AuthStack from "./AuthStack";
import CoreStack from "./CoreStack";

export default function AppNavigator() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // Start showing splash for a few seconds
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setShowSplash(false);
    }, 2500); // splash delay
    return () => clearTimeout(timer);
  }, []);

  if (showSplash) {
    // 🔹 Temporary Splash (so app won’t flicker)
    return <AuthStack initial="SplashScreen" />;
  }

  return (
    <NavigationContainer>
      {isLoggedIn ? <CoreStack /> : <AuthStack />}
    </NavigationContainer>
  );
}