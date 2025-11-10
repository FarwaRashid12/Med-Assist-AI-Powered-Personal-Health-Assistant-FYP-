import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import Constants from 'expo-constants';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ref, push, set } from 'firebase/database';
import { db } from '../context/firebaseConfig';
import { auth } from '../context/firebaseConfig';

const originalError = console.error;
const originalWarn = console.warn;
console.error = (...args) => {
  const message = args.join(' ');
  if (message.includes('expo-notifications') && message.includes('Android Push notifications') && message.includes('Expo Go')) {
    return;
  }
  originalError.apply(console, args);
};
console.warn = (...args) => {
  const message = args.join(' ');
  if (message.includes('expo-notifications') && message.includes('Android Push notifications') && message.includes('Expo Go')) {
    return;
  }
  originalWarn.apply(console, args);
};

const isExpoGo = Constants.executionEnvironment === 'storeClient';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export const requestNotificationPermissions = async () => {
  try {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync({
        ios: {
          allowAlert: true,
          allowBadge: true,
          allowSound: true,
          allowAnnouncements: false,
        },
      });
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      console.warn('Failed to get notification permissions');
      return false;
    }

    if (Platform.OS === 'android') {
      try {
        await Notifications.setNotificationChannelAsync('medication-reminders', {
          name: 'Medication Reminders',
          importance: Notifications.AndroidImportance.HIGH,
          vibrationPattern: [0, 250, 250, 250],
          lightColor: '#0077B6',
          sound: 'default',
          showBadge: true,
        });
      } catch (error) {
        console.log('Notification channel setup:', error.message);
      }
    }

    return true;
  } catch (error) {
    console.error('Error requesting notification permissions:', error);
    if (isExpoGo) {
      console.log('Running in Expo Go - local notifications should still work');
      return true;
    }
    return false;
  }
};

const parseTime = (timeString) => {
  if (!timeString) return null;

  const timeRegex = /(\d{1,2}):?(\d{2})?\s*(AM|PM|am|pm)?/i;
  const match = timeString.match(timeRegex);

  if (match) {
    let hours = parseInt(match[1], 10);
    const minutes = match[2] ? parseInt(match[2], 10) : 0;
    const period = match[3]?.toUpperCase();

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    } else if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    return { hours, minutes };
  }

  const lowerTime = timeString.toLowerCase();
  if (lowerTime.includes('morning') || lowerTime.includes('breakfast')) {
    return { hours: 8, minutes: 0 };
  }
  if (lowerTime.includes('noon') || lowerTime.includes('lunch')) {
    return { hours: 12, minutes: 0 };
  }
  if (lowerTime.includes('evening') || lowerTime.includes('dinner')) {
    return { hours: 18, minutes: 0 };
  }
  if (lowerTime.includes('night') || lowerTime.includes('bedtime') || lowerTime.includes('sleep')) {
    return { hours: 21, minutes: 0 };
  }

  return null;
};

const parseDuration = (durationString) => {
  if (!durationString) return 7;

  const match = durationString.match(/(\d+)\s*(day|days|week|weeks|month|months)/i);
  if (match) {
    const value = parseInt(match[1], 10);
    const unit = match[2].toLowerCase();

    if (unit.includes('day')) return value;
    if (unit.includes('week')) return value * 7;
    if (unit.includes('month')) return value * 30;
  }

  return 7;
};

export const scheduleMedicationReminder = async (medicine, customTime = null) => {
  try {
    const hasPermission = await requestNotificationPermissions();
    if (!hasPermission) {
      if (isExpoGo) {
        console.log('Warning: Notification permissions not fully granted, but attempting to schedule local notification anyway');
      } else {
        throw new Error('Notification permissions not granted');
      }
    }

    const medicineName = medicine.medicine || medicine.name || 'Medicine';
    const dosage = medicine.dosage || 'as prescribed';
    
    let timeToUse = null;
    
    if (customTime) {
      const now = new Date();
      timeToUse = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate(),
        customTime.getHours(),
        customTime.getMinutes(),
        0,
        0
      );
      console.log('📅 Using custom time from picker:', timeToUse);
      console.log('📅 Hours:', timeToUse.getHours(), 'Minutes:', timeToUse.getMinutes());
    } else if (medicine.time) {
      const parsed = parseTime(medicine.time);
      if (parsed) {
        const now = new Date();
        timeToUse = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          parsed.hours,
          parsed.minutes,
          0,
          0
        );
      }
    } else if (medicine.timing) {
      const parsed = parseTime(medicine.timing);
      if (parsed) {
        const now = new Date();
        timeToUse = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          parsed.hours,
          parsed.minutes,
          0,
          0
        );
      }
    }

    if (!timeToUse) {
      const now = new Date();
      timeToUse = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate(),
        9,
        0,
        0,
        0
      );
    }

    const now = new Date();
    if (timeToUse <= now) {
      timeToUse.setDate(timeToUse.getDate() + 1);
      console.log('⏰ Time has passed today, scheduling for tomorrow:', timeToUse.toLocaleString());
    }
    
    console.log('⏰ Final scheduled time:', timeToUse.toLocaleString());
    console.log('⏰ Final hours:', timeToUse.getHours(), 'minutes:', timeToUse.getMinutes());

    const durationDays = parseDuration(medicine.duration);
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + durationDays);

    const frequency = medicine.frequency?.toLowerCase() || '';
    let trigger = null;

    if (frequency.includes('twice') || frequency.includes('2')) {
      const morningTime = new Date(timeToUse);
      morningTime.setHours(9, 0, 0, 0);
      const eveningTime = new Date(timeToUse);
      eveningTime.setHours(21, 0, 0, 0);

      const morningId = await Notifications.scheduleNotificationAsync({
        content: {
          title: '💊 Medication Reminder',
          body: `Time to take ${medicineName} - ${dosage}`,
          sound: true,
          priority: Notifications.AndroidNotificationPriority.HIGH,
          data: { medicine: medicineName, dosage },
        },
        trigger: {
          hour: 9,
          minute: 0,
          repeats: true,
        },
        identifier: `med-${medicineName}-morning-${Date.now()}`,
      });

      const eveningId = await Notifications.scheduleNotificationAsync({
        content: {
          title: '💊 Medication Reminder',
          body: `Time to take ${medicineName} - ${dosage}`,
          sound: true,
          priority: Notifications.AndroidNotificationPriority.HIGH,
          data: { medicine: medicineName, dosage },
        },
        trigger: {
          hour: 21,
          minute: 0,
          repeats: true,
        },
        identifier: `med-${medicineName}-evening-${Date.now()}`,
      });

      return { morningId, eveningId };
    } else if (frequency.includes('thrice') || frequency.includes('3')) {
      const times = [
        { hour: 8, minute: 0 },
        { hour: 14, minute: 0 },
        { hour: 20, minute: 0 },
      ];

      const ids = [];
      for (const t of times) {
        const id = await Notifications.scheduleNotificationAsync({
          content: {
            title: '💊 Medication Reminder',
            body: `Time to take ${medicineName} - ${dosage}`,
            sound: true,
            priority: Notifications.AndroidNotificationPriority.HIGH,
            data: { medicine: medicineName, dosage },
          },
          trigger: {
            hour: t.hour,
            minute: t.minute,
            repeats: true,
          },
          identifier: `med-${medicineName}-${t.hour}-${Date.now()}`,
        });
        ids.push(id);
      }
      return ids;
    } else {
      const hours = timeToUse.getHours();
      const minutes = timeToUse.getMinutes();
      
      console.log(`📅 Scheduling daily reminder for ${medicineName}`);
      console.log(`⏰ Time: ${hours}:${minutes.toString().padStart(2, '0')}`);
      console.log(`📆 Scheduled for: ${timeToUse.toLocaleString()}`);
      console.log(`📆 Date object: ${timeToUse.toString()}`);
      
      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: '💊 Medication Reminder',
          body: `Time to take ${medicineName} - ${dosage}`,
          sound: true,
          priority: Notifications.AndroidNotificationPriority.HIGH,
          data: { medicine: medicineName, dosage },
        },
        trigger: {
          hour: hours,
          minute: minutes,
          repeats: true,
        },
        identifier: `med-${medicineName}-${Date.now()}`,
      });

      console.log(`✅ Reminder scheduled successfully! ID: ${notificationId}`);
      console.log(`⏰ Notification will fire daily at ${hours}:${minutes.toString().padStart(2, '0')}`);
      
      try {
        const allNotifications = await Notifications.getAllScheduledNotificationsAsync();
        console.log(`📋 Verification: Found ${allNotifications.length} scheduled notification(s)`);
        
        if (allNotifications.length > 0) {
          const scheduled = allNotifications.find(n => 
            n.identifier.includes(medicineName) || 
            n.content.data?.medicine === medicineName
          );
          if (scheduled) {
            console.log(`✅ Notification verified in system!`);
            console.log(`   Identifier: ${scheduled.identifier}`);
            console.log(`   Trigger:`, scheduled.trigger);
          }
        } else {
          console.log(`ℹ️ Note: getAllScheduledNotificationsAsync() returned 0 in Expo Go.`);
          console.log(`   This is a known limitation - notifications will still fire at the scheduled time.`);
          console.log(`   For production, use a development build: npx expo run:android`);
        }
      } catch (error) {
        console.log(`⚠️ Could not verify scheduled notifications:`, error.message);
      }
      
      return notificationId;
    }
  } catch (error) {
    console.error('Error scheduling reminder:', error);
    throw error;
  }
};

export const saveReminder = async (medicine, notificationIds, selectedTime = null) => {
  try {
    const user = auth.currentUser;
    if (!user) {
      throw new Error('User not authenticated');
    }

    const medicineName = medicine.medicine || medicine.name || 'Unknown';
    const dosage = medicine.dosage || null;
    
    let timeString = null;
    if (selectedTime && selectedTime instanceof Date) {
      timeString = selectedTime.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: true 
      });
    } else if (medicine.time) {
      timeString = medicine.time;
    } else if (medicine.timing) {
      timeString = medicine.timing;
    }

    const createdAt = new Date().toISOString();

    let idsArray = [];
    if (Array.isArray(notificationIds)) {
      idsArray = notificationIds;
    } else if (notificationIds && typeof notificationIds === 'object') {
      idsArray = Object.values(notificationIds).filter(id => id != null);
    } else if (notificationIds) {
      idsArray = [notificationIds];
    }

    const remindersRef = ref(db, 'reminders');
    const newReminderRef = push(remindersRef);
    
    const firebaseReminder = {
      u_id: user.uid,
      medicine_name: medicineName,
      dosage: dosage,
      time: timeString,
      created_at: createdAt,
    };

    await set(newReminderRef, firebaseReminder);
    console.log('✅ Reminder saved to Firebase with ID:', newReminderRef.key);

    const reminders = await AsyncStorage.getItem('medicationReminders');
    const remindersList = reminders ? JSON.parse(reminders) : [];

    const localReminder = {
      id: newReminderRef.key,
      firebaseId: newReminderRef.key,
      medicine: medicineName,
      dosage: dosage,
      time: timeString,
      frequency: medicine.frequency,
      duration: medicine.duration,
      notificationIds: idsArray,
      createdAt: createdAt,
    };

    remindersList.push(localReminder);
    await AsyncStorage.setItem('medicationReminders', JSON.stringify(remindersList));
    
    return newReminderRef.key;
  } catch (error) {
    console.error('Error saving reminder:', error);
    throw error;
  }
};

export const getReminders = async () => {
  try {
    const reminders = await AsyncStorage.getItem('medicationReminders');
    return reminders ? JSON.parse(reminders) : [];
  } catch (error) {
    console.error('Error getting reminders:', error);
    return [];
  }
};

export const cancelReminder = async (notificationIds) => {
  try {
    const ids = Array.isArray(notificationIds) ? notificationIds : [notificationIds];
    for (const id of ids) {
      await Notifications.cancelScheduledNotificationAsync(id);
    }
  } catch (error) {
    console.error('Error canceling reminder:', error);
    throw error;
  }
};

export const getAllScheduledNotifications = async () => {
  try {
    const notifications = await Notifications.getAllScheduledNotificationsAsync();
    console.log('📋 All scheduled notifications:', notifications.length);
    notifications.forEach((notif, index) => {
      console.log(`${index + 1}. ID: ${notif.identifier}`);
      console.log(`   Title: ${notif.content.title}`);
      console.log(`   Body: ${notif.content.body}`);
      console.log(`   Trigger:`, notif.trigger);
      console.log('---');
    });
    return notifications;
  } catch (error) {
    console.error('Error getting scheduled notifications:', error);
    return [];
  }
};

export const sendTestNotification = async () => {
  try {
    const hasPermission = await requestNotificationPermissions();
    if (!hasPermission) {
      throw new Error('Notification permissions not granted');
    }

    await Notifications.scheduleNotificationAsync({
      content: {
        title: '🧪 Test Notification',
        body: 'If you see this, notifications are working!',
        sound: true,
        priority: Notifications.AndroidNotificationPriority.HIGH,
      },
      trigger: null,
    });
    
    console.log('✅ Test notification sent!');
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw error;
  }
};
