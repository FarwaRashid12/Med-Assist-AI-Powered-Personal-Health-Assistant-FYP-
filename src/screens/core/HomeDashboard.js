// HomeDashboard.js - Complete updated file
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
  Alert,
} from "react-native";
import {
  Ionicons,
  MaterialCommunityIcons,
} from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import colors from "../../constants/colors";

let CircularProgress;
try {
  CircularProgress = require("react-native-gifted-charts").CircularProgress;
} catch (e) {
  CircularProgress = undefined;
}

const { width } = Dimensions.get("window");

// ──────────────────────────────────────────────────────────────
// Helper – current week
// ──────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────
// Main Component
// ──────────────────────────────────────────────────────────────
export default function HomeDashboard({ navigation, route }) {
  const username = route?.params?.name || "Aashifa Sheikh";
  const week = useMemo(() => getCurrentWeek(), []);
  const [selectedIdx, setSelectedIdx] = useState(
    week.findIndex((d) => d.isToday) ?? 0
  );

  const nextReminder = { time: "11:00 AM", title: "Vitamin D", dose: "1 tab" };
  const medsWeek = { taken: 4, total: 7 };
  const vitals = { bp: "118/76", sugar: "104 mg/dL", pulse: "74 bpm" };

  // Pulse animation
  const pulseAnim = useRef(new Animated.Value(1)).current;
  React.useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.2,
          duration: 500,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 500,
          easing: Easing.in(Easing.quad),
          useNativeDriver: true,
        }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [pulseAnim]);

  const onBellPress = () => {
    Alert.alert("Notifications", "You have new reminders!");
  };

  const onViewAllPress = () => {
    Alert.alert("Progress Report", "Opening full report...");
  };

  return (
    <View style={styles.container}>
      {/* Header with more spacing */}
      <LinearGradient colors={["#5EC0FF", "#9BD6FF"]} style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={styles.headerText}>Good Morning, {username}</Text>
          <TouchableOpacity style={styles.bellWrap} onPress={onBellPress}>
            <Ionicons name="notifications" size={24} color="#fff" />
            <View style={styles.redDot} />
          </TouchableOpacity>
        </View>
      </LinearGradient>

      {/* Reminder Card with proper spacing */}
      <View style={styles.reminderCardWrapper}>
        <LinearGradient
          colors={["#CDEBFF", "#9BD6FF", "#5EC0FF"]}
          style={styles.reminderCard}
        >
          <View style={styles.reminderHeader}>
            <View style={styles.timeRow}>
              <MaterialCommunityIcons name="clock-outline" size={18} color="#0b4e78" />
              <Text style={styles.timeText}>{nextReminder.time}</Text>
            </View>
            <TouchableOpacity>
              <Text style={styles.manageBtn}>Manage</Text>
            </TouchableOpacity>
          </View>

          <Text style={styles.reminderSub}>
            {nextReminder.title} • {nextReminder.dose}
          </Text>

          <FlatList
            data={week}
            horizontal
            showsHorizontalScrollIndicator={false}
            keyExtractor={(item) => item.key}
            contentContainerStyle={styles.weekList}
            ItemSeparatorComponent={() => <View style={{ width: 8 }} />}
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
      </View>

      {/* 4 Summary Cards */}
      <View style={styles.row}>
        <SummaryCard
          title="Upcoming"
          subtitle={`${nextReminder.title} • ${nextReminder.time}`}
          icon={<Ionicons name="add-circle" size={20} color="#4CAF50" />}
          bgColor="#E8F5E9"
          highlight={true}
        />
        <SummaryCard
          title="This Week"
          subtitle={`${medsWeek.taken}/${medsWeek.total} medicines taken`}
          icon={<Ionicons name="checkmark-circle" size={20} color="#4CAF50" />}
          bgColor="#E8F5E9"
          highlight={true}
        />
      </View>

      <View style={styles.row}>
        <SummaryCard
          title="BP & Pulse"
          subtitle={`Pulse ${vitals.pulse}`}
          icon={<MaterialCommunityIcons name="heart-pulse" size={20} color="#FF5252" />}
          bgColor="#FFEBEE"
          highlight={true}
        />
        <SummaryCard
          title="Blood Sugar"
          subtitle={vitals.sugar}
          icon={<MaterialCommunityIcons name="test-tube" size={20} color="#2196F3" />}
          bgColor="#E3F2FD"
          highlight={true}
        />
      </View>

      {/* Progress Report - UPDATED TO MATCH YOUR IMAGE */}
      <View style={styles.progressCard}>
        <View style={styles.progressHeader}>
          <Text style={styles.progressTitle}>Progress Report</Text>
          <TouchableOpacity onPress={onViewAllPress}>
            <Text style={styles.viewAll}>View All →</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.progressContent}>
          {/* BP Section - Left side */}
          <View style={styles.bpSection}>
            <Text style={styles.sectionTitle}>BP</Text>
            <View style={styles.bpValues}>
              <Text style={styles.bpValue}>118/76</Text>
              <Text style={styles.bpValue}>118/76</Text>
            </View>
          </View>

          {/* Vertical Divider */}
          <View style={styles.verticalDivider} />

          {/* Heart Section - Right side */}
          <View style={styles.heartSection}>
            <Text style={styles.sectionTitle}>Heart</Text>
            <View style={styles.heartContent}>
              <Animated.Text style={[styles.heartValue, { transform: [{ scale: pulseAnim }] }]}>
                105
              </Animated.Text>
              <Text style={styles.heartUnit}>bpm</Text>
            </View>
          </View>
        </View>
      </View>
    </View>
  );
}

// ──────────────────────────────────────────────────────────────
// Summary Card Component
// ──────────────────────────────────────────────────────────────
function SummaryCard({ title, subtitle, icon, bgColor, highlight }) {
  return (
    <View style={[styles.summaryCard, highlight && styles.summaryCardHighlight]}>
      <View style={[styles.cardIcon, { backgroundColor: bgColor }]}>
        {icon}
      </View>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardSub}>{subtitle}</Text>
    </View>
  );
}

// ──────────────────────────────────────────────────────────────
// Updated Styles
// ──────────────────────────────────────────────────────────────
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F5F7FA",
    paddingBottom: 80, // Space for navbar
  },

  // Header with better spacing
  header: {
    paddingHorizontal: 18,
    paddingTop: 50,
    paddingBottom: 20, // Increased padding
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  headerContent: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: 10, // Added spacing from top
  },
  headerText: { color: "#fff", fontSize: 18, fontWeight: "700" },
  bellWrap: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.2)",
    justifyContent: "center",
    alignItems: "center",
    marginTop: 10, // Added spacing
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

  // Reminder Card with proper spacing from header
  reminderCardWrapper: {
    marginHorizontal: 18,
    marginTop: -10, // Adjusted to create proper gap
  },
  reminderCard: {
    borderRadius: 20,
    padding: 16,
    elevation: 6,
  },
  reminderHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  timeRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  timeText: { fontSize: 16, fontWeight: "700", color: "#0b4e78" },
  manageBtn: {
    color: "#0b4e78",
    fontWeight: "600",
    backgroundColor: "#fff",
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 16,
    fontSize: 13,
  },
  reminderSub: { 
    marginTop: 8, 
    color: "#0b4e78", 
    fontSize: 14,
    fontWeight: '600'
  },
  weekList: { 
    paddingVertical: 12 
  },

  dayPill: {
    width: 50,
    borderRadius: 14,
    alignItems: "center",
    paddingVertical: 8,
    elevation: 1,
  },
  dayPillActive: { backgroundColor: "#0b4e78" },
  dayPillInactive: { backgroundColor: "#fff" },
  dayName: { fontSize: 10, color: "#666" },
  dayNum: { fontSize: 15, fontWeight: "700", marginTop: 2 },
  activeText: { color: "#fff" },

  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 18,
    marginTop: 14,
  },

  // Summary Cards
  summaryCard: {
    width: (width - 48) / 2,
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 12,
    elevation: 3,
    alignItems: "center",
  },
  summaryCardHighlight: {
    elevation: 6,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
  },
  cardIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 8,
  },
  cardTitle: { fontSize: 13, fontWeight: "700", color: "#000" },
  cardSub: { fontSize: 11, color: "#666", marginTop: 2, textAlign: "center" },

  // Progress Report - UPDATED TO MATCH YOUR IMAGE
  progressCard: {
    marginHorizontal: 18,
    marginTop: 14,
    backgroundColor: "#fff",
    borderRadius: 18,
    padding: 16,
    elevation: 4,
    marginBottom: 10,
  },
  progressHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 16,
  },
  progressTitle: { 
    fontSize: 16, 
    fontWeight: "700",
    color: '#000'
  },
  viewAll: { 
    fontSize: 12, 
    color: "#5EC0FF", 
    fontWeight: "600" 
  },

  progressContent: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 10,
  },

  // BP Section
  bpSection: {
    flex: 1,
    alignItems: "flex-start",
  },
  
  // Heart Section
  heartSection: {
    flex: 1,
    alignItems: "flex-end",
  },
  
  // Common section title
  sectionTitle: { 
    fontSize: 14, 
    fontWeight: "700", 
    marginBottom: 8,
    color: '#333'
  },

  // BP Values
  bpValues: {
    alignItems: 'flex-start',
    gap: 2,
  },
  bpValue: {
    fontSize: 16,
    fontWeight: "700",
    color: "#5EC0FF",
  },

  // Heart Content
  heartContent: {
    alignItems: 'flex-end',
  },
  heartValue: { 
    fontSize: 28, 
    fontWeight: "800", 
    color: "#2196F3",
    lineHeight: 30,
  },
  heartUnit: { 
    fontSize: 12, 
    color: "#666", 
    marginTop: 2
  },

  // Vertical Divider
  verticalDivider: {
    width: 1,
    height: 50,
    backgroundColor: '#E0E0E0',
    marginHorizontal: 20,
  },
});