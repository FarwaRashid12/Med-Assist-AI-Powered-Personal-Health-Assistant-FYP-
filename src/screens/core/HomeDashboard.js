import React, { useMemo, useState, useRef } from "react";
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
} from "react-native";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import colors from "../../constants/colors";

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
  const username = route?.params?.name || "User";
  const week = useMemo(() => getCurrentWeek(), []);
  const [selectedIdx, setSelectedIdx] = useState(
    week.findIndex((d) => d.isToday) ?? 0
  );

  const nextReminder = { time: "11:00 AM" };
  const medsWeek = { taken: 4, total: 7 };
  const vitals = { bp: "118/76", sugar: "104 mg/dL", pulse: "74 bpm" };

  const pulseAnim = useRef(new Animated.Value(1)).current;
  React.useEffect(() => {
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
    <SafeAreaView style={styles.safeContainer}>
      <View style={styles.container}>
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
                >
                  <Text style={[styles.dayName, active && styles.activeText]}>
                    {item.dayName}
                  </Text>
                  <Text style={[styles.dayNum, active && styles.activeText]}>
                    {item.dayNum}
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
              <Text style={styles.heartValue}>105</Text>
              <Text style={styles.heartUnit}>bpm</Text>
            </View>
          </View>
        </View>
      </View>
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
    paddingBottom: 20,
  },
  header: {
    paddingHorizontal: 18,
    paddingTop: 45,
    paddingBottom: 24,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    elevation: 4,
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  greetingText: { color: "#E0F2FF", fontSize: 14 },
  username: { color: colors.white, fontSize: 20, fontWeight: "800" },
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
    marginTop: 12,
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
  dayPill: { width: 45, borderRadius: 14, alignItems: "center", paddingVertical: 8 },
  dayPillActive: { backgroundColor: colors.primary },
  dayPillInactive: { backgroundColor: colors.white },
  dayName: { fontSize: 11, color: "#666" },
  dayNum: { fontSize: 15, fontWeight: "700" },
  activeText: { color: colors.white },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 18,
    marginTop: 12,
  },
  card: {
    width: (width - 48) / 2,
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 12,
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
    marginTop: 14,
    backgroundColor: colors.white,
    borderRadius: 18,
    padding: 14,
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
