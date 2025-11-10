import React, { useState } from 'react';
import {
  View,
  Text,
  Modal,
  StyleSheet,
  TouchableOpacity,
  Platform,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import colors from '../constants/colors';

export default function TimePickerModal({ visible, onClose, onConfirm, initialTime = null }) {
  const [selectedTime, setSelectedTime] = useState(
    initialTime || new Date()
  );

  const handleConfirm = () => {
    console.log('🕐 TimePickerModal - handleConfirm called');
    console.log('🕐 Selected time object:', selectedTime);
    console.log('🕐 Selected time string:', selectedTime.toString());
    console.log('🕐 Selected time ISO:', selectedTime.toISOString());
    console.log('🕐 Hours:', selectedTime.getHours(), 'Minutes:', selectedTime.getMinutes());
    console.log('🕐 Formatted time:', formatTime(selectedTime));
    onConfirm(selectedTime);
    onClose();
  };

  const formatTime = (date) => {
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    const displayMinutes = minutes.toString().padStart(2, '0');
    return `${displayHours}:${displayMinutes} ${ampm}`;
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <Text style={styles.title}>Select Reminder Time</Text>
          
          {Platform.OS === 'ios' ? (
            <DateTimePicker
              value={selectedTime}
              mode="time"
              display="spinner"
              onChange={(event, date) => {
                if (date) {
                  console.log('🕐 iOS TimePicker - onChange:', date);
                  console.log('🕐 Hours:', date.getHours(), 'Minutes:', date.getMinutes());
                  setSelectedTime(date);
                }
              }}
              style={styles.picker}
            />
          ) : (
            <DateTimePicker
              value={selectedTime}
              mode="time"
              display="default"
              onChange={(event, date) => {
                if (date) {
                  console.log('🕐 Android TimePicker - onChange:', date);
                  console.log('🕐 Event type:', event.type);
                  console.log('🕐 Hours:', date.getHours(), 'Minutes:', date.getMinutes());
                  setSelectedTime(date);
                }
                if (event.type === 'set') {
                  handleConfirm();
                }
              }}
            />
          )}

          <View style={styles.timeDisplay}>
            <Text style={styles.timeText}>{formatTime(selectedTime)}</Text>
          </View>

          <View style={styles.buttonRow}>
            <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.confirmButton} onPress={handleConfirm}>
              <Text style={styles.confirmText}>Set Reminder</Text>
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
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: colors.white,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    paddingBottom: 40,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.textDark,
    textAlign: 'center',
    marginBottom: 20,
  },
  picker: {
    width: '100%',
    height: 200,
  },
  timeDisplay: {
    alignItems: 'center',
    marginVertical: 20,
    padding: 15,
    backgroundColor: colors.background,
    borderRadius: 10,
  },
  timeText: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
  },
  cancelButton: {
    flex: 1,
    paddingVertical: 14,
    marginRight: 10,
    borderRadius: 10,
    backgroundColor: colors.background,
    alignItems: 'center',
  },
  cancelText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textLight,
  },
  confirmButton: {
    flex: 1,
    paddingVertical: 14,
    marginLeft: 10,
    borderRadius: 10,
    backgroundColor: colors.primary,
    alignItems: 'center',
  },
  confirmText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.white,
  },
});
