import React, { useMemo, useState, useRef, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Dimensions,
  Animated,
  Easing,
  SafeAreaView,
  ScrollView,
  StatusBar,
  Platform,
  AppState,
} from "react-native";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { useFocusEffect } from "@react-navigation/native";
import colors from "../../constants/colors";
import { useAuth } from "../../context/AuthContext";
import { ref, get } from "firebase/database";
import { db } from "../../context/firebaseConfig";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { getReminders } from "../../utils/notificationService";

const { width } = Dimensions.get("window");

const getCurrentWeek = () => {
  const today = new Date();
  const dayOfWeek = today.getDay();
  const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
  const monday = new Date(today);
  monday.setDate(today.getDate() + mondayOffset);

  const days = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    days.push({
      key: i.toString(),
      date: d,
      dayNum: d.getDate(),
      dayName: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][i],
      isToday:
        d.getDate() === today.getDate() &&
        d.getMonth() === today.getMonth() &&
        d.getFullYear() === today.getFullYear(),
    });
  }
  return days;
};

// 🕒 dynamic greeting
const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour < 12) return "Good Morning";
  if (hour < 18) return "Good Afternoon";
  return "Good Evening";
};

export default function HomeDashboard({ navigation, route }) {
  const { user, userData } = useAuth();
  const username = userData?.fullName || userData?.displayName || "User";
  const week = useMemo(() => getCurrentWeek(), []);
  const [selectedIdx, setSelectedIdx] = useState(
    week.findIndex((d) => d.isToday) ?? 0
  );

  const medsWeek = { taken: 4, total: 7 };
  
  // State for real vitals data
  const [vitals, setVitals] = useState({ 
    bp: "118/76", 
    sugar: "104 mg/dL", 
    pulse: "74 bpm",
    heartRate: "105"
  });

  // State for next reminder time
  const [nextReminder, setNextReminder] = useState({ time: "11:00 AM" });

  const pulseAnim = useRef(new Animated.Value(1)).current;
  
  // Handle app state changes to maintain consistent layout
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState) => {
      if (nextAppState === 'active') {
        // Ensure StatusBar is set correctly when app comes to foreground
        StatusBar.setBarStyle('light-content');
        if (Platform.OS === 'android') {
          StatusBar.setBackgroundColor(colors.primary);
          StatusBar.setTranslucent(false);
        }
      }
    });

    return () => {
      subscription?.remove();
    };
  }, []);

  // Format time to "11:00 AM" format
  const formatTime = (time) => {
    if (!time) return "11:00 AM";
    
    try {
      // If it's a Date object
      if (time instanceof Date) {
        return time.toLocaleTimeString('en-US', { 
          hour: '2-digit', 
          minute: '2-digit',
          hour12: true 
        });
      }
      
      // If it's a string in ISO format or similar
      if (typeof time === 'string') {
        // Check if it's an ISO date string
        if (time.includes('T') || time.includes('Z')) {
          const date = new Date(time);
          if (!isNaN(date.getTime())) {
            return date.toLocaleTimeString('en-US', { 
              hour: '2-digit', 
              minute: '2-digit',
              hour12: true 
            });
          }
        }
        
        // If it's already in "HH:mm" or "HH:MM AM/PM" format
        // Check if it matches time pattern
        const timeMatch = time.match(/(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i);
        if (timeMatch) {
          let hours = parseInt(timeMatch[1]);
          const minutes = timeMatch[2];
          const ampm = timeMatch[3] ? timeMatch[3].toUpperCase() : null;
          
          // If no AM/PM, assume 24-hour format and convert
          if (!ampm) {
            const date = new Date();
            date.setHours(hours);
            date.setMinutes(parseInt(minutes));
            return date.toLocaleTimeString('en-US', { 
              hour: '2-digit', 
              minute: '2-digit',
              hour12: true 
            });
          } else {
            // Already has AM/PM, just format it properly
            return `${hours}:${minutes} ${ampm}`;
          }
        }
      }
      
      return "11:00 AM";
    } catch (error) {
      console.error("Error formatting time:", error);
      return "11:00 AM";
    }
  };

  // Parse time string to Date object for comparison
  const parseTimeToDate = (time) => {
    if (!time) return null;
    
    try {
      if (time instanceof Date) {
        return time;
      }
      
      if (typeof time === 'string') {
        // Try parsing ISO format
        if (time.includes('T') || time.includes('Z')) {
          const date = new Date(time);
          if (!isNaN(date.getTime())) {
            return date;
          }
        }
        
        // Try parsing "HH:mm" or "HH:MM AM/PM" format
        const timeMatch = time.match(/(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i);
        if (timeMatch) {
          let hours = parseInt(timeMatch[1]);
          const minutes = parseInt(timeMatch[2]);
          const ampm = timeMatch[3] ? timeMatch[3].toUpperCase() : null;
          
          const date = new Date();
          date.setHours(0, 0, 0, 0); // Set to today
          
          if (ampm) {
            // 12-hour format
            if (ampm === 'PM' && hours !== 12) {
              hours += 12;
            } else if (ampm === 'AM' && hours === 12) {
              hours = 0;
            }
          }
          
          date.setHours(hours, minutes, 0, 0);
          return date;
        }
      }
      
      return null;
    } catch (error) {
      console.error("Error parsing time:", error);
      return null;
    }
  };

  // Load next reminder time for today
  const loadNextReminder = React.useCallback(async () => {
    try {
      // Get reminders from AsyncStorage
      const reminders = await getReminders();
      
      // Get prescription plan from AsyncStorage
      const prescriptionPlanStr = await AsyncStorage.getItem("prescriptionPlan");
      const prescriptionPlan = prescriptionPlanStr ? JSON.parse(prescriptionPlanStr) : [];
      
      // Collect all reminder times
      const reminderTimes = [];
      
      // Add times from reminders
      reminders.forEach(reminder => {
        if (reminder.time) {
          reminderTimes.push(reminder.time);
        }
      });
      
      // Add times from prescription plan
      prescriptionPlan.forEach(medicine => {
        if (medicine.reminderSet && medicine.reminderTime) {
          reminderTimes.push(medicine.reminderTime);
        } else if (medicine.time || medicine.timing) {
          reminderTimes.push(medicine.time || medicine.timing);
        }
      });
      
      if (reminderTimes.length === 0) {
        setNextReminder({ time: "11:00 AM" });
        return;
      }
      
      // Convert all times to Date objects and find the earliest one for today
      const now = new Date();
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      // Parse all times and create Date objects for today
      const todayTimes = reminderTimes
        .map(time => parseTimeToDate(time))
        .filter(date => date !== null)
        .map(date => {
          // Create a date for today with the same time
          const todayWithTime = new Date(today);
          todayWithTime.setHours(date.getHours());
          todayWithTime.setMinutes(date.getMinutes());
          return todayWithTime;
        });
      
      if (todayTimes.length === 0) {
        setNextReminder({ time: "11:00 AM" });
        return;
      }
      
      // Find upcoming times (that haven't passed yet)
      const upcomingTimes = todayTimes.filter(time => time >= now);
      
      // If there are upcoming times, use the earliest one
      // Otherwise, use the earliest time overall (even if it has passed)
      let nextTime;
      if (upcomingTimes.length > 0) {
        nextTime = upcomingTimes.reduce((earliest, current) => {
          return current < earliest ? current : earliest;
        });
      } else {
        // All reminders for today have passed, show the earliest one
        nextTime = todayTimes.reduce((earliest, current) => {
          return current < earliest ? current : earliest;
        });
      }
      
      setNextReminder({ time: formatTime(nextTime) });
    } catch (error) {
      console.error("Error loading next reminder:", error);
      setNextReminder({ time: "11:00 AM" });
    }
  }, []);

  // Fetch latest vitals from Firebase
  const loadLatestVitals = React.useCallback(async () => {
    if (!user) return;

    try {
      const reportsRef = ref(db, `users/${user.uid}/progressReports`);
      const snapshot = await get(reportsRef);

      if (snapshot.exists()) {
        const data = snapshot.val();
        const reportsArray = Object.keys(data)
          .map((key) => ({
            id: key,
            ...data[key],
          }))
          .sort((a, b) => {
            // Sort by timestamp if available, otherwise by date and time
            if (a.timestamp && b.timestamp) {
              return new Date(b.timestamp) - new Date(a.timestamp);
            }
            const dateA = new Date(`${a.date}T${a.time}`);
            const dateB = new Date(`${b.date}T${b.time}`);
            return dateB - dateA; // Most recent first
          });

        if (reportsArray.length > 0) {
          const latestReport = reportsArray[0];
          const bp = latestReport.systolic && latestReport.diastolic 
            ? `${latestReport.systolic}/${latestReport.diastolic}` 
            : "118/76";
          const pulse = latestReport.pulse 
            ? `${latestReport.pulse} bpm` 
            : "74 bpm";
          const sugar = latestReport.sugar 
            ? `${latestReport.sugar} mg/dL` 
            : "104 mg/dL";
          const heartRate = latestReport.pulse 
            ? `${latestReport.pulse}` 
            : "105";

          setVitals({ bp, pulse, sugar, heartRate });
        }
      }
    } catch (error) {
      console.error("Error loading vitals:", error);
      // Keep default values on error
    }
  }, [user]);

  // Load vitals and reminders when component mounts or user changes
  useEffect(() => {
    loadLatestVitals();
    loadNextReminder();
  }, [loadLatestVitals, loadNextReminder]);

  // Reload vitals, reminders and reset StatusBar when screen comes into focus
  useFocusEffect(
    React.useCallback(() => {
      // Reset StatusBar when screen is focused
      StatusBar.setBarStyle('light-content');
      if (Platform.OS === 'android') {
        StatusBar.setBackgroundColor(colors.primary);
        StatusBar.setTranslucent(false);
      }
      // Reload vitals data and reminders
      loadLatestVitals();
      loadNextReminder();
    }, [loadLatestVitals, loadNextReminder])
  );

  // Pulse animation effect
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.2,
          duration: 600,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 600,
          easing: Easing.in(Easing.quad),
          useNativeDriver: true,
        }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [pulseAnim]);

  return (
    <SafeAreaView style={styles.safeContainer} edges={['top']}>
      <StatusBar 
        barStyle="light-content" 
        backgroundColor={colors.primary} 
        translucent={false}
        hidden={false}
      />
      <ScrollView 
        style={styles.container}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        bounces={false}
      >
        {/* Header */}
        <LinearGradient
          colors={[colors.primary, colors.accent]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.header}
        >
          <View style={styles.headerRow}>
            <View>
              <Text style={styles.greetingText}>{getGreeting()},</Text>
              <Text style={styles.username}>{username}</Text>
            </View>
            <TouchableOpacity style={styles.bellWrap}>
              <Ionicons name="notifications-outline" size={22} color={colors.white} />
              <View style={styles.redDot} />
            </TouchableOpacity>
          </View>
        </LinearGradient>

        {/* Reminder */}
        <LinearGradient
          colors={[colors.primary, colors.accent]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.reminderCard}
        >
          <View style={styles.reminderHeader}>
            <View style={styles.timeRow}>
              <MaterialCommunityIcons name="clock-outline" size={18} color={colors.white} />
              <Text style={styles.reminderTime}>{nextReminder.time}</Text>
            </View>
            <TouchableOpacity>
              <Text style={styles.manageBtn}>Manage</Text>
            </TouchableOpacity>
          </View>

          <FlatList
            data={week}
            horizontal
            showsHorizontalScrollIndicator={false}
            keyExtractor={(item) => item.key}
            contentContainerStyle={styles.weekList}
            renderItem={({ item, index }) => {
              const active = index === selectedIdx;
              return (
                <TouchableOpacity
                  style={[
                    styles.dayPill,
                    active ? styles.dayPillActive : styles.dayPillInactive,
                  ]}
                  onPress={() => setSelectedIdx(index)}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.dayNum, active && styles.activeText]}>
                    {item.dayNum}
                  </Text>
                  <Text style={[styles.dayName, active && styles.activeText]}>
                    {item.dayName}
                  </Text>
                </TouchableOpacity>
              );
            }}
          />
        </LinearGradient>

        {/* Summary Row */}
        <View style={styles.row}>
          <SummaryCard
            title="Upcoming"
            subtitle={`${nextReminder.time}`}
            icon={<Ionicons name="medkit-outline" size={20} color={colors.accent} />}
          />
          <SummaryCard
            title="This Week"
            subtitle={`${medsWeek.taken}/${medsWeek.total} taken`}
            icon={<Ionicons name="checkmark-done-circle-outline" size={20} color="#4CAF50" />}
          />
        </View>

        <View style={styles.row}>
          <SummaryCard
            title="BP & Pulse"
            subtitle={`Pulse ${vitals.pulse}`}
            icon={<MaterialCommunityIcons name="heart-pulse" size={20} color="#FF6B81" />}
          />
          <SummaryCard
            title="Blood Sugar"
            subtitle={vitals.sugar}
            icon={<MaterialCommunityIcons name="test-tube" size={20} color={colors.primary} />}
          />
        </View>

        {/* Progress Report */}
        <View style={styles.progressCard}>
          <View style={styles.progressHeader}>
            <Text style={styles.progressTitle}>Progress Report</Text>
            <TouchableOpacity
              onPress={() => navigation.navigate("Profile", { screen: "ProgressReport" })}
            >
              <Text style={styles.viewAll}>View All →</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.progressContent}>
            <View style={styles.bpContainer}>
              <LinearGradient
                colors={[colors.accent, colors.primary]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.bpOuterCircle}
              >
                <View style={styles.bpInnerCircle}>
                  <Text style={styles.bpLabel}>BP</Text>
                  <Text style={styles.bpValue}>{vitals.bp}</Text>
                </View>
              </LinearGradient>
            </View>

            <View style={styles.verticalDivider} />

            <View style={styles.heartContainer}>
              <Text style={styles.heartLabel}>Heart</Text>
              <Animated.View
                style={[
                  styles.heartIconWrapper,
                  { transform: [{ scale: pulseAnim }] },
                ]}
              >
                <MaterialCommunityIcons
                  name="heart-outline"
                  size={78}
                  color="#FF6B81"
                />
              </Animated.View>
              <Text style={styles.heartValue}>{vitals.heartRate}</Text>
              <Text style={styles.heartUnit}>bpm</Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function SummaryCard({ title, subtitle, icon }) {
  return (
    <View style={styles.card}>
      <View style={styles.cardIcon}>{icon}</View>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardSub}>{subtitle}</Text>
    </View>
  );
}

/* -------------------------- Styles -------------------------- */
const styles = StyleSheet.create({
  safeContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContent: {
    paddingBottom: 80, // Reduced space for navbar since it's lower now
    flexGrow: 1,
  },
  header: {
    paddingHorizontal: 18,
    paddingTop: Platform.OS === 'android' ? 25 : 30, // Increased to make "Good Afternoon" section fully visible
    paddingBottom: 22,
    marginTop: 0,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    elevation: 4,
    minHeight: 100, // Ensure header has enough height
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  greetingText: { 
    color: "#E0F2FF", 
    fontSize: 15,
    marginBottom: 4, // Add spacing between greeting and name
  },
  username: { 
    color: colors.white, 
    fontSize: 22, 
    fontWeight: "800",
    letterSpacing: 0.5, // Better readability
  },
  bellWrap: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.25)",
    alignItems: "center",
    justifyContent: "center",
  },
  redDot: {
    position: "absolute",
    top: 8,
    right: 8,
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#FF3B30",
  },
  reminderCard: {
    marginHorizontal: 18,
    marginTop: 16, // Increased spacing from header
    borderRadius: 20,
    padding: 14,
    elevation: 5,
  },
  reminderHeader: { flexDirection: "row", justifyContent: "space-between" },
  timeRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  reminderTime: { fontSize: 16, fontWeight: "700", color: colors.white },
  manageBtn: {
    backgroundColor: "#fff",
    color: colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 14,
    fontWeight: "700",
  },
  weekList: {
    paddingTop: 8,
    paddingHorizontal: 4,
  },
  dayPill: { 
    width: 50, 
    borderRadius: 16, 
    alignItems: "center", 
    justifyContent: "center",
    paddingVertical: 10,
    paddingHorizontal: 4,
    marginHorizontal: 4,
  },
  dayPillActive: { 
    backgroundColor: colors.primary,
    elevation: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  dayPillInactive: { 
    backgroundColor: colors.white,
    elevation: 1,
  },
  dayNum: { 
    fontSize: 16, 
    fontWeight: "700",
    color: "#333",
    marginBottom: 2,
  },
  dayName: { 
    fontSize: 11, 
    color: "#666",
    fontWeight: "500",
  },
  activeText: { 
    color: colors.white,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 18,
    marginTop: 14, // Increased spacing between rows
  },
  card: {
    width: (width - 48) / 2,
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 14, // Increased padding for better spacing
    elevation: 4,
  },
  cardIcon: {
    width: 34,
    height: 34,
    borderRadius: 10,
    backgroundColor: "#EAF6FF",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 6,
  },
  cardTitle: { fontSize: 14, fontWeight: "700", color: "#000" },
  cardSub: { fontSize: 12, color: "#666" },
  progressCard: {
    marginHorizontal: 18,
    marginTop: 14, // Increased spacing from cards above
    backgroundColor: colors.white,
    borderRadius: 18,
    padding: 14, // Increased padding for better spacing
    elevation: 5,
  },
  progressHeader: { flexDirection: "row", justifyContent: "space-between" },
  progressTitle: { fontSize: 16, fontWeight: "700", color: "#000" },
  viewAll: { fontSize: 12, color: colors.primary, fontWeight: "600" },
  progressContent: {
    flexDirection: "row",
    justifyContent: "space-evenly",
    alignItems: "center",
    marginTop: 10,
  },
  bpContainer: { alignItems: "center" },
  bpOuterCircle: {
    width: 90,
    height: 90,
    borderRadius: 45,
    alignItems: "center",
    justifyContent: "center",
  },
  bpInnerCircle: {
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
  bpLabel: { fontSize: 13, color: "#666" },
  bpValue: { fontSize: 15, fontWeight: "800", color: colors.primary },
  verticalDivider: { width: 1, height: 60, backgroundColor: "#E0E0E0" },
  heartContainer: { alignItems: "center" },
  heartLabel: { fontSize: 14, color: "#666" },
  heartValue: { fontSize: 24, fontWeight: "800", color: colors.primary },
  heartUnit: { fontSize: 12, color: "#666" },
  heartIconWrapper: { justifyContent: "center", alignItems: "center" },
});
