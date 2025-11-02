import React, { useEffect, useRef } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Animated,
  Easing,
  TouchableOpacity,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import colors from "../../constants/colors";

export default function ProgressReport({ navigation }) {
  const pulseAnim = useRef(new Animated.Value(1)).current;

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
    <View style={styles.container}>
      {/* Header */}
      <LinearGradient
        colors={[colors.primary, colors.accent]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.header}
      >
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="arrow-back" size={26} color={colors.white} />
        </TouchableOpacity>
        <Text style={styles.headerText}>Progress Report</Text>
      </LinearGradient>

      {/* Content */}
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: 40 }}
      >
        {/* Section 1 — Summary Cards */}
        <View style={styles.row}>
          <ReportCard
            icon={
              <MaterialCommunityIcons
                name="medication-outline"
                size={26}
                color={colors.accent}
              />
            }
            title="Medicines Taken"
            value="24 / 28"
            sub="This Month"
          />
          <ReportCard
            icon={
              <Ionicons name="flame-outline" size={26} color="#FF6B81" />
            }
            title="Calories Burned"
            value="6,240 kcal"
            sub="Last 7 days"
          />
        </View>

        {/* Section 2 — Vitals */}
        <View style={styles.row}>
          <ReportCard
            icon={
              <MaterialCommunityIcons
                name="heart-pulse"
                size={28}
                color="#FF6B81"
              />
            }
            title="Pulse Rate"
            value="74 bpm"
            sub="Normal"
          />
          <ReportCard
            icon={
              <MaterialCommunityIcons
                name="test-tube"
                size={28}
                color={colors.primary}
              />
            }
            title="Blood Sugar"
            value="104 mg/dL"
            sub="Fasting"
          />
        </View>

        {/* Section 3 — Animated Heart */}
        <View style={styles.reportCard}>
          <Text style={styles.sectionTitle}>Heart Activity</Text>
          <Animated.View
            style={[
              styles.heartWrapper,
              { transform: [{ scale: pulseAnim }] },
            ]}
          >
            <MaterialCommunityIcons name="heart" size={90} color="#FF6B81" />
          </Animated.View>
          <Text style={styles.heartValue}>105 bpm</Text>
          <Text style={styles.heartLabel}>Current Pulse</Text>
        </View>

        {/* Section 4 — BP Report */}
        <View style={styles.reportCard}>
          <Text style={styles.sectionTitle}>Blood Pressure</Text>
          <View style={styles.bpRow}>
            <View style={styles.bpItem}>
              <Text style={styles.bpValue}>118</Text>
              <Text style={styles.bpLabel}>Systolic</Text>
            </View>
            <View style={styles.bpDivider} />
            <View style={styles.bpItem}>
              <Text style={styles.bpValue}>76</Text>
              <Text style={styles.bpLabel}>Diastolic</Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

/* Reusable Report Card */
function ReportCard({ icon, title, value, sub }) {
  return (
    <View style={styles.card}>
      <View style={styles.cardIcon}>{icon}</View>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardValue}>{value}</Text>
      <Text style={styles.cardSub}>{sub}</Text>
    </View>
  );
}

/* Styles */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    paddingTop: 70,
    paddingBottom: 30,
    borderBottomLeftRadius: 22,
    borderBottomRightRadius: 22,
    alignItems: "center",
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 5,
  },
  backButton: {
    position: "absolute",
    left: 20,
    top: 55,
    zIndex: 10,
  },
  headerText: {
    color: colors.white,
    fontSize: 22,
    fontWeight: "700",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: 18,
    marginTop: 18,
  },
  card: {
    width: "47%",
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 14,
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: 3 },
    shadowRadius: 5,
    elevation: 4,
    alignItems: "center",
  },
  cardIcon: {
    backgroundColor: "#EAF6FF",
    padding: 10,
    borderRadius: 12,
    marginBottom: 8,
  },
  cardTitle: { fontSize: 13, fontWeight: "700", color: colors.textDark },
  cardValue: { fontSize: 18, fontWeight: "800", color: colors.primary },
  cardSub: { fontSize: 12, color: colors.textLight },
  reportCard: {
    marginHorizontal: 18,
    marginTop: 18,
    backgroundColor: colors.white,
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 6,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.textDark,
    marginBottom: 12,
  },
  heartWrapper: { alignItems: "center", justifyContent: "center" },
  heartValue: {
    fontSize: 28,
    fontWeight: "800",
    color: colors.primary,
    marginTop: 6,
  },
  heartLabel: { fontSize: 12, color: colors.textLight },
  bpRow: {
    flexDirection: "row",
    justifyContent: "space-evenly",
    alignItems: "center",
    width: "100%",
    marginTop: 10,
  },
  bpItem: { alignItems: "center" },
  bpValue: { fontSize: 26, fontWeight: "700", color: colors.primary },
  bpLabel: { fontSize: 13, color: colors.textLight },
  bpDivider: {
    width: 1,
    height: 50,
    backgroundColor: "#E0E0E0",
  },
});
