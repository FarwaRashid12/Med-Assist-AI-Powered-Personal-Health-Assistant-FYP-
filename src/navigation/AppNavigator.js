import React, { useState, useEffect } from "react";
import { NavigationContainer } from "@react-navigation/native";
import AuthStack from "./AuthStack";
import CoreStack from "./CoreStack";

export default function AppNavigator() {
  const [isLoggedIn, setIsLoggedIn] = useState(true);
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setShowSplash(false);
    }, 2500);
    return () => clearTimeout(timer);
  }, []);

  return (
    <NavigationContainer>
      {showSplash ? (
        <AuthStack initial="SplashScreen" />
      ) : isLoggedIn ? (
        <CoreStack />
      ) : (
        <AuthStack />
      )}
    </NavigationContainer>
  );
}
