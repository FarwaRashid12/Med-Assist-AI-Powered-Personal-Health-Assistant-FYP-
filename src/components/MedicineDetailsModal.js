import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Modal,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  ScrollView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import colors from '../constants/colors';

export default function MedicineDetailsModal({
  visible,
  medicine,
  onClose,
  onConfirm,
}) {
  const [timing, setTiming] = useState('');
  const [frequency, setFrequency] = useState('');
  const [duration, setDuration] = useState('');
  const [time, setTime] = useState('');
  const [selectedTime, setSelectedTime] = useState(new Date());
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [timeDisplay, setTimeDisplay] = useState('');

  useEffect(() => {
    if (medicine) {
      setTiming(medicine.timing || '');
      setFrequency(medicine.frequency || '');
      setDuration(medicine.duration || '');
      setTime(medicine.time || '');
      
      if (medicine.selectedTime && medicine.selectedTime instanceof Date) {
        setSelectedTime(medicine.selectedTime);
        formatTimeDisplay(medicine.selectedTime);
      } else if (medicine.time) {
        const parsed = parseTimeString(medicine.time);
        if (parsed) {
          setSelectedTime(parsed);
          formatTimeDisplay(parsed);
        }
      }
    }
  }, [medicine]);

  const parseTimeString = (timeStr) => {
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

  const formatTimeDisplay = (date) => {
    if (!date) return;
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    const displayMinutes = minutes.toString().padStart(2, '0');
    setTimeDisplay(`${displayHours}:${displayMinutes} ${ampm}`);
    setTime(`${displayHours}:${displayMinutes} ${ampm}`);
  };

  const handleTimePickerChange = (event, date) => {
    if (Platform.OS === 'android') {
      setShowTimePicker(false);
    }
    if (date) {
      setSelectedTime(date);
      formatTimeDisplay(date);
    }
  };

  const handleTimePickerConfirm = () => {
    setShowTimePicker(false);
    formatTimeDisplay(selectedTime);
  };

  const handleConfirm = () => {
    const updatedMedicine = {
      ...medicine,
      timing: timing.trim() || null,
      frequency: frequency.trim() || null,
      duration: duration.trim() || null,
      time: time.trim() || timeDisplay || null,
      selectedTime: selectedTime,
    };
    onConfirm(updatedMedicine);
    setTiming('');
    setFrequency('');
    setDuration('');
    setTime('');
    setTimeDisplay('');
    setSelectedTime(new Date());
  };

  const handleCancel = () => {
    onClose();
    setTiming('');
    setFrequency('');
    setDuration('');
    setTime('');
  };

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="slide"
      onRequestClose={handleCancel}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.title}>Review & Edit Medicine Details</Text>
            <Text style={styles.subtitle}>
              Please review and update the details for {medicine?.medicine || medicine?.name || 'this medicine'}
            </Text>
          </View>

          <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
            {medicine && (medicine.medicine || medicine.name) && (
              <View style={styles.inputGroup}>
                <Text style={styles.label}>
                  💊 Medicine Name
                </Text>
                <Text style={styles.medicineNameDisplay}>
                  {medicine.medicine || medicine.name}
                </Text>
              </View>
            )}

            <View style={styles.inputGroup}>
              <Text style={styles.label}>
                ⏱️ Timing <Text style={styles.optional}>(When to take)</Text>
              </Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., before meals, after breakfast, 8 AM"
                placeholderTextColor="#999"
                value={timing}
                onChangeText={setTiming}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>
                📅 Frequency <Text style={styles.required}>*</Text> <Text style={styles.optional}>(How often)</Text>
              </Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., twice daily, once a day, three times a day"
                placeholderTextColor="#999"
                value={frequency}
                onChangeText={setFrequency}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>
                ⏰ Time <Text style={styles.optional}>(Specific time)</Text>
              </Text>
              <TouchableOpacity
                style={styles.timePickerButton}
                onPress={() => setShowTimePicker(true)}
              >
                <View style={styles.timePickerContent}>
                  <Ionicons name="time-outline" size={20} color={colors.primary} />
                  <Text style={[styles.timePickerText, timeDisplay && styles.timePickerTextFilled]}>
                    {timeDisplay || 'Tap to select time'}
                  </Text>
                </View>
              </TouchableOpacity>
              {showTimePicker && (
                <View style={styles.timePickerContainer}>
                  {Platform.OS === 'ios' && (
                    <View style={styles.timePickerActions}>
                      <TouchableOpacity onPress={() => setShowTimePicker(false)}>
                        <Text style={styles.timePickerCancel}>Cancel</Text>
                      </TouchableOpacity>
                      <TouchableOpacity onPress={handleTimePickerConfirm}>
                        <Text style={styles.timePickerDone}>Done</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                  <DateTimePicker
                    value={selectedTime}
                    mode="time"
                    display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                    onChange={handleTimePickerChange}
                  />
                </View>
              )}
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>
                📆 Duration <Text style={styles.optional}>(How long)</Text>
              </Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., 7 days, 2 weeks, until finished"
                placeholderTextColor="#999"
                value={duration}
                onChangeText={setDuration}
              />
            </View>
          </ScrollView>

          <View style={styles.buttonRow}>
            <TouchableOpacity style={styles.cancelButton} onPress={handleCancel}>
              <Ionicons name="close-circle" size={24} color={colors.white} />
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.confirmButton, !frequency.trim() && styles.confirmButtonDisabled]}
              onPress={handleConfirm}
              disabled={!frequency.trim()}
            >
              <Ionicons name="checkmark-circle" size={24} color={colors.white} />
              <Text style={styles.confirmText}>Confirm</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: '90%',
    maxHeight: '80%',
    backgroundColor: colors.white,
    borderRadius: 20,
    padding: 20,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 3.84,
      },
      android: {
        elevation: 5,
      },
    }),
  },
  header: {
    marginBottom: 20,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: colors.textLight,
    lineHeight: 20,
  },
  scrollView: {
    maxHeight: 400,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textDark,
    marginBottom: 8,
  },
  medicineNameDisplay: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.primary,
    padding: 12,
    backgroundColor: '#E3F2FD',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#BBDEFB',
  },
  required: {
    color: '#f44336',
  },
  optional: {
    fontSize: 12,
    color: colors.textLight,
    fontWeight: '400',
  },
  input: {
    backgroundColor: '#f5f5f5',
    borderRadius: 12,
    padding: 14,
    fontSize: 15,
    color: colors.textDark,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#f44336',
    paddingVertical: 14,
    borderRadius: 12,
    gap: 8,
  },
  confirmButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    paddingVertical: 14,
    borderRadius: 12,
    gap: 8,
  },
  confirmButtonDisabled: {
    backgroundColor: '#ccc',
    opacity: 0.6,
  },
  cancelText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
  confirmText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
  timePickerButton: {
    backgroundColor: '#f5f5f5',
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  timePickerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  timePickerText: {
    fontSize: 15,
    color: '#999',
  },
  timePickerTextFilled: {
    color: colors.textDark,
    fontWeight: '500',
  },
  timePickerContainer: {
    marginTop: 10,
    backgroundColor: '#f9f9f9',
    borderRadius: 12,
    padding: 10,
  },
  timePickerActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
    marginBottom: 10,
  },
  timePickerCancel: {
    color: '#f44336',
    fontSize: 16,
    fontWeight: '600',
  },
  timePickerDone: {
    color: colors.primary,
    fontSize: 16,
    fontWeight: '600',
  },
});
