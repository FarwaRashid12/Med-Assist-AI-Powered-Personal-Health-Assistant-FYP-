import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  Alert,
  ScrollView,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { getReminders, scheduleMedicationReminder, saveReminder } from "../../utils/notificationService";
import TimePickerModal from "../../components/TimePickerModal";
import colors from "../../constants/colors";
import { auth } from "../../context/firebaseConfig";

export default function Reminders({ route, navigation }) {
  const [plan, setPlan] = useState(route.params?.plan || []);
  const [savedReminders, setSavedReminders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [schedulingReminder, setSchedulingReminder] = useState(false);
  const [timePickerVisible, setTimePickerVisible] = useState(false);
  const [selectedMedicineIndex, setSelectedMedicineIndex] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      
      const saved = await AsyncStorage.getItem("prescriptionPlan");
      if (saved) {
        const parsed = JSON.parse(saved);
        const parsedWithDates = parsed.map(medicine => {
          if (medicine.selectedTimeISO) {
            return {
              ...medicine,
              selectedTime: new Date(medicine.selectedTimeISO),
            };
          }
          return medicine;
        });
        setPlan(parsedWithDates);
      } else {
        setPlan([]);
      }
      
      const reminders = await getReminders();
      setSavedReminders(reminders);
    } catch (e) {
      console.warn("Failed to load data", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      loadData();
    });
    return unsubscribe;
  }, [navigation]);

  const handleSetReminder = (index) => {
    const medicine = plan[index];
    
    let timeToUse = null;
    if (medicine.selectedTime) {
      if (medicine.selectedTime instanceof Date) {
        timeToUse = medicine.selectedTime;
      } else if (typeof medicine.selectedTime === 'string') {
        timeToUse = new Date(medicine.selectedTime);
      }
    } else if (medicine.selectedTimeISO) {
      timeToUse = new Date(medicine.selectedTimeISO);
    }
    
    if (timeToUse && timeToUse instanceof Date && !isNaN(timeToUse.getTime())) {
      scheduleReminderForMedicine(index, timeToUse);
    } else if (medicine.time || medicine.timing) {
      const parsed = parseTimeFromString(medicine.time || medicine.timing);
      if (parsed) {
        scheduleReminderForMedicine(index, parsed);
      } else {
        setSelectedMedicineIndex(index);
        setTimePickerVisible(true);
      }
    } else {
      setSelectedMedicineIndex(index);
      setTimePickerVisible(true);
    }
  };

  const parseTimeFromString = (timeStr) => {
    if (!timeStr) return null;
    const timeRegex = /(\d{1,2}):?(\d{2})?\s*(AM|PM|am|pm)/i;
    const match = timeStr.match(timeRegex);
    if (match) {
      let hours = parseInt(match[1], 10);
      const minutes = match[3] ? parseInt(match[2] || '0', 10) : 0;
      const period = match[3]?.toUpperCase();
      
      if (period === 'PM' && hours !== 12) hours += 12;
      if (period === 'AM' && hours === 12) hours = 0;
      
      const date = new Date();
      date.setHours(hours, minutes, 0, 0);
      return date;
    }
    return null;
  };

  const scheduleReminderForMedicine = async (index, customTime) => {
    const medicine = plan[index];
    
    if (!medicine || !medicine.medicine) {
      Alert.alert('Error', 'Invalid medicine data');
      return;
    }

    const user = auth.currentUser;
    if (!user) {
      Alert.alert('Error', 'Please log in to set reminders');
      return;
    }

    setSchedulingReminder(true);
    
    try {
      const notificationIds = await scheduleMedicationReminder(medicine, customTime);
      
      const reminderId = await saveReminder(medicine, notificationIds, customTime);
      
      const updatedPlan = [...plan];
      updatedPlan[index] = {
        ...updatedPlan[index],
        reminderSet: true,
        reminderTime: customTime || medicine.time || medicine.timing,
        reminderId: reminderId,
      };
      setPlan(updatedPlan);
      
      const medicinesForStorage = updatedPlan.map(m => ({
        ...m,
        selectedTime: m.selectedTime ? m.selectedTime.toISOString() : null,
      }));
      await AsyncStorage.setItem("prescriptionPlan", JSON.stringify(medicinesForStorage));
      
      const timeDisplay = customTime 
        ? customTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
        : medicine.time || medicine.timing || 'scheduled time';
      
      Alert.alert(
        '✅ Reminder Set',
        `Reminder set for ${medicine.medicine} at ${timeDisplay}\n\nYou will receive a notification at the scheduled time.`
      );
    } catch (error) {
      console.error('Error setting reminder:', error);
      Alert.alert(
        '❌ Error',
        error.message || 'Failed to set reminder. Please check notification permissions and try again.'
      );
    } finally {
      setSchedulingReminder(false);
    }
  };

  const handleTimePickerConfirm = (selectedTime) => {
    if (selectedMedicineIndex !== null) {
      scheduleReminderForMedicine(selectedMedicineIndex, selectedTime);
    }
    setTimePickerVisible(false);
    setSelectedMedicineIndex(null);
  };

  const renderItem = ({ item, index }) => {
    const hasReminder = item.reminderSet || savedReminders.some(
      r => r.medicine === (item.medicine || item.name)
    );
    
    const medicineName = item.medicine || item.name || 'Unknown Medicine';
    
    return (
      <View style={styles.card}>
        <View style={styles.cardContent}>
          <View style={styles.cardHeader}>
            <Text style={styles.medName}>{medicineName}</Text>
            {hasReminder ? (
              <View style={styles.setBadge}>
                <Ionicons name="checkmark-circle" size={16} color={colors.white} style={{ marginRight: 4 }} />
                <Text style={styles.setBadgeText}>Set</Text>
              </View>
            ) : (
              <TouchableOpacity
                style={styles.setButton}
                onPress={() => handleSetReminder(index)}
                disabled={schedulingReminder}
              >
                <Ionicons name="alarm" size={16} color={colors.white} style={{ marginRight: 4 }} />
                <Text style={styles.setButtonText}>Set Reminder</Text>
              </TouchableOpacity>
            )}
          </View>
          
          <View style={styles.medicineDetails}>
            {item.dosage && (
              <View style={styles.detailItem}>
                <Ionicons name="water" size={18} color={colors.primary} />
                <Text style={styles.detailText}>Dosage: {item.dosage}</Text>
              </View>
            )}

            {item.timing && (
              <View style={styles.detailItem}>
                <Ionicons name="time" size={18} color={colors.primary} />
                <Text style={styles.detailText}>Timing: {item.timing}</Text>
              </View>
            )}

            {(item.time || item.selectedTime || item.selectedTimeISO) && (
              <View style={styles.detailItem}>
                <Ionicons name="alarm" size={18} color={colors.primary} />
                <Text style={styles.detailText}>Time: {
                  (() => {
                    if (item.selectedTime instanceof Date) {
                      return item.selectedTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
                    } else if (item.selectedTimeISO) {
                      const date = new Date(item.selectedTimeISO);
                      return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
                    } else if (typeof item.selectedTime === 'string') {
                      const date = new Date(item.selectedTime);
                      if (!isNaN(date.getTime())) {
                        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
                      }
                    }
                    return item.time;
                  })()
                }</Text>
              </View>
            )}

            {item.frequency && (
              <View style={styles.detailItem}>
                <Ionicons name="calendar" size={18} color={colors.primary} />
                <Text style={styles.detailText}>Frequency: {item.frequency}</Text>
              </View>
            )}

            {item.duration && (
              <View style={styles.detailItem}>
                <Ionicons name="calendar-outline" size={18} color={colors.primary} />
                <Text style={styles.detailText}>Duration: {item.duration}</Text>
              </View>
            )}

            <View style={styles.detailItem}>
              <Ionicons name="document-text" size={18} color={colors.primary} />
              <Text style={styles.detailText}>Instructions: {item.instructions || 'no instruction given'}</Text>
            </View>
          </View>
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={styles.loadingText}>Loading your reminders...</Text>
      </View>
    );
  }

  if (!plan.length) {
    return (
      <SafeAreaView style={styles.safeContainer}>
        <View style={styles.center}>
          <Ionicons name="medical-outline" size={64} color={colors.textLight} />
          <Text style={styles.emptyText}>No reminders found.</Text>
          <TouchableOpacity
            style={styles.btn}
            onPress={() => navigation.navigate("UploadPrescription")}
          >
            <Text style={styles.btnText}>Upload a Prescription</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeContainer}>
      <View style={styles.container}>
        <Text style={styles.title}>💊 Medication Planner</Text>
        <FlatList
          data={plan}
          renderItem={renderItem}
          keyExtractor={(_, i) => i.toString()}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          refreshing={loading}
          onRefresh={loadData}
        />
      </View>

      <TimePickerModal
        visible={timePickerVisible}
        onClose={() => {
          setTimePickerVisible(false);
          setSelectedMedicineIndex(null);
        }}
        onConfirm={handleTimePickerConfirm}
        initialTime={selectedMedicineIndex !== null && plan[selectedMedicineIndex]?.selectedTime 
          ? plan[selectedMedicineIndex].selectedTime
          : selectedMedicineIndex !== null && plan[selectedMedicineIndex]?.time 
          ? parseTimeFromString(plan[selectedMedicineIndex].time)
          : null}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  container: { 
    flex: 1, 
    backgroundColor: colors.background,
    paddingTop: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: colors.primary,
    marginBottom: 20,
    paddingHorizontal: 20,
  },
  listContent: {
    paddingHorizontal: 20,
    paddingBottom: 100,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: 16,
    marginBottom: 16,
    overflow: "hidden",
    elevation: 3,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  cardContent: {
    padding: 16,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary,
  },
  cardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  medName: { 
    fontSize: 18, 
    fontWeight: "700", 
    color: colors.textDark,
    flex: 1,
  },
  setBadge: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#4CAF50",
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  setBadgeText: {
    color: colors.white,
    fontSize: 14,
    fontWeight: "600",
  },
  setButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#4CAF50",
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  setButtonText: {
    color: colors.white,
    fontSize: 14,
    fontWeight: "600",
    marginLeft: 4,
  },
  detailsRow: {
    marginTop: 8,
  },
  medicineDetails: {
    marginTop: 12,
  },
  detailItem: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 8,
  },
  detailText: { 
    fontSize: 14, 
    color: colors.textDark,
    marginLeft: 8,
    fontWeight: "500",
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: colors.textLight,
  },
  emptyText: { 
    fontSize: 18, 
    color: colors.textLight, 
    marginTop: 16,
    marginBottom: 20,
    textAlign: "center",
  },
  btn: {
    backgroundColor: colors.primary,
    paddingHorizontal: 25,
    paddingVertical: 12,
    borderRadius: 25,
  },
  btnText: { 
    color: colors.white, 
    fontWeight: "600", 
    fontSize: 16,
  },
});
