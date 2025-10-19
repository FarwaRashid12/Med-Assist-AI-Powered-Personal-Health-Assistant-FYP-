import { createStackNavigator } from "@react-navigation/stack";
import SplashScreen from "../screens/Auth/SplashScreen";
import Onboarding from "../screens/Auth/Onboarding";

const Stack = createStackNavigator();

export default function AuthStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Splash" component={SplashScreen} />
      <Stack.Screen name="Onboarding" component={Onboarding} />
          </Stack.Navigator>
  );
}