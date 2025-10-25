import React, { useMemo, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Dimensions,
  ScrollView,
} from "react-native";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { LineChart } from "react-native-gifted-charts";
import colors from "../../constants/colors";

let CircularProgress;
try {
  // Safe dynamic import — prevents crash if not found
  CircularProgress = require("react-native-gifted-charts").CircularProgress;
} catch (e) {
  CircularProgress = undefined;
}

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

export default function HomeDashboard({ navigation, route }) {
  const username = route?.params?.name || "Aashifa Sheikh";
  const week = useMemo(() => getCurrentWeek(), []);
  const [selectedIdx, setSelectedIdx] = useState(
    week.findIndex((d) => d.isToday) ?? 0
  );

  const nextReminder = { time: "11:00 AM", title: "Vitamin D", dose: "1 tab" };
  const medsWeek = { taken: 4, total: 7 };
  const vitals = { bp: "118/76", sugar: "104 mg/dL", pulse: "74 bpm" };

  const heartRateData = [70, 74, 71, 76, 72, 75, 73, 77, 72];
  const lineData = heartRateData.map((v) => ({ value: v }));

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={{ paddingBottom: 100 }}
      showsVerticalScrollIndicator={false}
    >
      {/* Header */}
      <View style={styles.headerRow}>
        <View>
          <Text style={styles.smallGreeting}>Good Morning,</Text>
          <Text style={styles.username}>{username}</Text>
        </View>
        <View style={styles.bellWrap}>
          <Ionicons
            name="notifications-outline"
            size={22}
            color={colors.primary}
          />
          <View style={styles.redDot} />
        </View>
      </View>

      {/* Main Reminder */}
      <LinearGradient
        colors={["#CDEBFF", "#9BD6FF", "#5EC0FF"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.bigCard}
      >
        <View style={styles.bigCardHeader}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
            <MaterialCommunityIcons
              name="clock-time-four-outline"
              size={18}
              color="#0b4e78"
            />
            <Text style={styles.bigCardTime}>{nextReminder.time}</Text>
          </View>
          <TouchableOpacity>
            <Text style={styles.addGoal}>Manage</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.bigCardSub}>
          {nextReminder.title} • {nextReminder.dose}
        </Text>

        <FlatList
          data={week}
          horizontal
          showsHorizontalScrollIndicator={false}
          keyExtractor={(item) => item.key}
          contentContainerStyle={{ paddingVertical: 12 }}
          ItemSeparatorComponent={() => <View style={{ width: 10 }} />}
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
                <Text style={[styles.dayNum, active && { color: "#fff" }]}>
                  {item.dayNum}
                </Text>
                <Text style={[styles.dayName, active && { color: "#fff" }]}>
                  {item.dayName}
                </Text>
              </TouchableOpacity>
            );
          }}
        />
      </LinearGradient>

      {/* Summary Cards */}
      <View style={styles.row}>
        <SummaryCard
          title="Upcoming"
          subtitle={`${nextReminder.title} • ${nextReminder.time}`}
          icon={
            <Ionicons name="medkit-outline" size={20} color={colors.primary} />
          }
        />
        <SummaryCard
          title="This Week"
          subtitle={`${medsWeek.taken}/${medsWeek.total} medicines taken`}
          icon={
            <Ionicons
              name="checkmark-done-circle-outline"
              size={20}
              color={colors.primary}
            />
          }
        />
      </View>

      <View style={styles.row}>
        <SummaryCard
          title="BP & Pulse"
          subtitle={`BP ${vitals.bp} • Pulse ${vitals.pulse}`}
          icon={
            <MaterialCommunityIcons
              name="heart-pulse"
              size={20}
              color={colors.primary}
            />
          }
        />
        <SummaryCard
          title="Blood Sugar"
          subtitle={vitals.sugar}
          icon={
            <MaterialCommunityIcons
              name="test-tube"
              size={20}
              color={colors.primary}
            />
          }
        />
      </View>

      {/* Progress Section */}
      <View style={styles.progressCard}>
        <View style={styles.progressHeader}>
          <Text style={styles.progressTitle}>Progress Report</Text>
          <TouchableOpacity>
            <Text style={styles.viewAll}>View All →</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.progressContent}>
          {/* BP Gauge or Fallback */}
          <View style={styles.gaugeContainer}>
            {CircularProgress ? (
              <CircularProgress
                radius={45}
                value={78}
                maxValue={100}
                progressColor={colors.primary}
                title="BP"
                titleColor={colors.textDark}
                activeStrokeWidth={12}
                inActiveStrokeWidth={12}
              />
            ) : (
              <View style={styles.fallbackGauge}>
                <Text style={styles.fallbackText}>BP</Text>
                <Text style={styles.fallbackValue}>{vitals.bp}</Text>
              </View>
            )}
          </View>

          {/* Heart Rate Line Chart */}
          <View style={styles.chartContainer}>
            <LineChart
              data={lineData}
              thickness={3}
              color={colors.primary}
              curved
              hideDataPoints
              height={100}
              areaChart
              startFillColor={"rgba(93,174,255,0.3)"}
              endFillColor={"rgba(93,174,255,0.05)"}
            />
            <Text style={styles.chartLabel}>Heart Rate</Text>
            <Text style={styles.chartValue}>{vitals.pulse}</Text>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}

function SummaryCard({ title, subtitle, icon }) {
  return (
    <TouchableOpacity style={styles.card}>
      <View style={styles.cardIcon}>{icon}</View>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardSub}>{subtitle}</Text>
    </TouchableOpacity>
  );
}

const { height } = Dimensions.get("window");

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, paddingHorizontal: 18, paddingTop: 14 },
  headerRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginTop: 16 },
  smallGreeting: { color: colors.textLight, fontSize: 14 },
  username: { color: colors.textDark, fontSize: 22, fontWeight: "800" },
  bellWrap: { width: 38, height: 38, borderRadius: 20, backgroundColor: "#E7F4FF", alignItems: "center", justifyContent: "center" },
  redDot: { position: "absolute", top: 6, right: 8, width: 8, height: 8, borderRadius: 4, backgroundColor: "#FF3B30" },
  bigCard: { borderRadius: 20, padding: 16, marginTop: 10 },
  bigCardHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  bigCardTime: { fontSize: 16, fontWeight: "700", color: "#0b4e78" },
  bigCardSub: { marginTop: 4, color: "#0b4e78" },
  addGoal: { backgroundColor: "#ffffffcc", color: "#0b4e78", paddingHorizontal: 12, paddingVertical: 8, borderRadius: 16, fontWeight: "700" },
  dayPill: { width: 50, borderRadius: 16, alignItems: "center", paddingVertical: 10 },
  dayPillActive: { backgroundColor: colors.primary },
  dayPillInactive: { backgroundColor: "#fff" },
  dayNum: { fontSize: 18, fontWeight: "800", color: colors.textDark },
  dayName: { fontSize: 11, color: colors.textLight },
  row: { flexDirection: "row", justifyContent: "space-between", marginTop: 16 },
  card: { width: (width - 48) / 2, backgroundColor: "#fff", borderRadius: 16, padding: 14, elevation: 2 },
  cardIcon: { width: 34, height: 34, borderRadius: 10, backgroundColor: "#EAF6FF", alignItems: "center", justifyContent: "center", marginBottom: 10 },
  cardTitle: { fontSize: 14, fontWeight: "800", color: colors.textDark },
  cardSub: { fontSize: 12, color: colors.textLight },
  progressCard: { backgroundColor: "#fff", borderRadius: 16, marginTop: 22, padding: 18, elevation: 3 },
  progressHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 14 },
  progressTitle: { fontSize: 18, fontWeight: "700", color: colors.textDark },
  viewAll: { fontSize: 13, color: colors.primary },
  progressContent: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  gaugeContainer: { alignItems: "center", width: "45%" },
  fallbackGauge: { borderWidth: 4, borderColor: colors.primary, borderRadius: 50, width: 90, height: 90, alignItems: "center", justifyContent: "center" },
  fallbackText: { color: colors.textLight, fontSize: 14 },
  fallbackValue: { fontSize: 18, fontWeight: "700", color: colors.textDark },
  chartContainer: { width: "50%", alignItems: "center" },
  chartLabel: { fontSize: 14, color: colors.textLight, marginTop: 4 },
  chartValue: { fontSize: 18, fontWeight: "700", color: colors.textDark, marginTop: 2 },
});