import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  FlatList,
  Alert,
  ActivityIndicator,
  SafeAreaView,
  ScrollView,
  Modal,
  TextInput,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import * as Contacts from "expo-contacts";
import { ref, set, get, remove } from "firebase/database";
import { db, auth } from "../../context/firebaseConfig";
import { useAuth } from "../../context/AuthContext";
import colors from "../../constants/colors";

const MAX_CONTACTS = 5;

export default function EmergencyContact({ navigation }) {
  const { user } = useAuth();
  const [contacts, setContacts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [showContactPicker, setShowContactPicker] = useState(false);
  const [availableContacts, setAvailableContacts] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    if (user) {
      loadEmergencyContacts();
    }
  }, [user]);

  const loadEmergencyContacts = async () => {
    const currentUser = user || auth.currentUser;
    
    if (!currentUser) {
      console.error("No user found when loading contacts");
      return;
    }
    
    try {
      setLoading(true);
      const firebasePath = `users/${currentUser.uid}/emergencyContacts`;
      const contactsRef = ref(db, firebasePath);
      console.log("Loading contacts from:", firebasePath);
      console.log("User UID:", currentUser.uid);
      
      const snapshot = await get(contactsRef);
      
      if (snapshot.exists()) {
        const data = snapshot.val();
        console.log("Contacts data from Firebase:", data);
        
        const contactsArray = Object.keys(data).map((key) => ({
          id: key,
          ...data[key],
        }));
        
        console.log("Parsed contacts array:", contactsArray);
        setContacts(contactsArray);
      } else {
        console.log("No contacts found in Firebase");
        setContacts([]);
      }
    } catch (error) {
      console.error("Error loading emergency contacts:", error);
      console.error("Error details:", {
        message: error.message,
        code: error.code,
        stack: error.stack,
      });
      Alert.alert("Error", `Failed to load emergency contacts: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const requestContactsPermission = async () => {
    try {
      const { status } = await Contacts.requestPermissionsAsync();
      if (status !== "granted") {
        Alert.alert(
          "Permission Required",
          "Please grant contacts permission to add emergency contacts."
        );
        return false;
      }
      return true;
    } catch (error) {
      console.error("Error requesting contacts permission:", error);
      Alert.alert("Error", "Failed to request contacts permission.");
      return false;
    }
  };

  const pickContact = async () => {
    try {
      // Check if already at max contacts
      if (contacts.length >= MAX_CONTACTS) {
        Alert.alert(
          "Limit Reached",
          `You can only add up to ${MAX_CONTACTS} emergency contacts.`
        );
        return;
      }

      // Request permission
      const hasPermission = await requestContactsPermission();
      if (!hasPermission) return;

      setLoading(true);

      // Get all contacts
      const { data } = await Contacts.getContactsAsync({
        fields: [Contacts.Fields.Name, Contacts.Fields.PhoneNumbers],
      });

      if (data.length === 0) {
        Alert.alert("No Contacts", "No contacts found on your device.");
        setLoading(false);
        return;
      }

      // Filter contacts with phone numbers
      const contactsWithPhone = data.filter(
        (contact) => contact.phoneNumbers && contact.phoneNumbers.length > 0
      );

      if (contactsWithPhone.length === 0) {
        Alert.alert("No Contacts", "No contacts with phone numbers found.");
        setLoading(false);
        return;
      }

      // Filter out already added contacts
      const filteredContacts = contactsWithPhone.filter((contact) => {
        const phone = contact.phoneNumbers[0]?.number || "";
        return !contacts.some(
          (c) => c.phone === phone || c.name === contact.name
        );
      });

      setAvailableContacts(filteredContacts);
      setShowContactPicker(true);
      setSearchQuery("");
    } catch (error) {
      console.error("Error picking contact:", error);
      Alert.alert("Error", "Failed to access contacts.");
    } finally {
      setLoading(false);
    }
  };

  const addEmergencyContact = async (contact) => {
    // Get user from context or auth
    const currentUser = user || auth.currentUser;
    
    if (!currentUser) {
      console.error("No user found in context or auth");
      Alert.alert("Error", "User not logged in. Please log in again.");
      return;
    }
    
    console.log("Current user UID:", currentUser.uid);

    try {
      const phone = contact.phoneNumbers[0]?.number || "";
      const contactName = contact.name || "Unknown";
      
      console.log("Adding contact:", { name: contactName, phone });
      
      const existing = contacts.find(
        (c) => c.phone === phone || c.name === contactName
      );

      if (existing) {
        Alert.alert("Already Added", "This contact is already in your emergency contacts.");
        setShowContactPicker(false);
        return;
      }

      if (contacts.length >= MAX_CONTACTS) {
        Alert.alert(
          "Limit Reached",
          `You can only add up to ${MAX_CONTACTS} emergency contacts.`
        );
        setShowContactPicker(false);
        return;
      }

      setSaving(true);
      setShowContactPicker(false);

      const contactData = {
        name: contactName,
        phone: phone,
        addedAt: new Date().toISOString(),
      };

      console.log("Saving contact data:", contactData);
      console.log("User UID:", currentUser.uid);

      const timestamp = Date.now();
      const firebasePath = `users/${currentUser.uid}/emergencyContacts/${timestamp}`;
      const newContactRef = ref(db, firebasePath);
      
      console.log("Firebase path:", firebasePath);
      console.log("Firebase reference:", newContactRef);
      
      try {
        await set(newContactRef, contactData);
        console.log("Contact saved successfully to Firebase");
        
        const verifyRef = ref(db, firebasePath);
        const verifySnapshot = await get(verifyRef);
        if (verifySnapshot.exists()) {
          console.log("Verified: Contact exists in Firebase:", verifySnapshot.val());
        } else {
          console.error("Warning: Contact was not found after saving");
        }
      } catch (firebaseError) {
        console.error("Firebase set error:", firebaseError);
        throw firebaseError;
      }

      await new Promise(resolve => setTimeout(resolve, 500));
      
      await loadEmergencyContacts();

      Alert.alert("Success", `${contactData.name} added as emergency contact.`);
    } catch (error) {
      console.error("Error adding emergency contact:", error);
      console.error("Error details:", {
        message: error.message,
        code: error.code,
        stack: error.stack,
      });
      Alert.alert("Error", `Failed to add emergency contact: ${error.message}`);
    } finally {
      setSaving(false);
    }
  };

  const filteredAvailableContacts = availableContacts.filter((contact) => {
    const name = (contact.name || "").toLowerCase();
    const phone = (contact.phoneNumbers[0]?.number || "").toLowerCase();
    const query = searchQuery.toLowerCase();
    return name.includes(query) || phone.includes(query);
  });

  const renderContactItem = ({ item }) => {
    const phone = item.phoneNumbers[0]?.number || "No phone";
    return (
      <TouchableOpacity
        style={styles.contactPickerItem}
        onPress={() => addEmergencyContact(item)}
      >
        <View style={styles.contactPickerIcon}>
          <Ionicons name="person" size={24} color={colors.primary} />
        </View>
        <View style={styles.contactPickerInfo}>
          <Text style={styles.contactPickerName}>{item.name || "Unknown"}</Text>
          <Text style={styles.contactPickerPhone}>{phone}</Text>
        </View>
        <Ionicons name="chevron-forward" size={20} color={colors.textLight} />
      </TouchableOpacity>
    );
  };

  const deleteContact = async (contactId) => {
    // Get user from context or auth
    const currentUser = user || auth.currentUser;
    
    if (!currentUser) {
      Alert.alert("Error", "User not logged in. Please log in again.");
      return;
    }

    Alert.alert(
      "Delete Contact",
      "Are you sure you want to remove this emergency contact?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            try {
              const firebasePath = `users/${currentUser.uid}/emergencyContacts/${contactId}`;
              const contactRef = ref(db, firebasePath);
              console.log("Deleting contact from:", firebasePath);
              
              await remove(contactRef);
              console.log("Contact deleted successfully");
              
              await loadEmergencyContacts();
              Alert.alert("Success", "Emergency contact removed.");
            } catch (error) {
              console.error("Error deleting contact:", error);
              console.error("Error details:", {
                message: error.message,
                code: error.code,
              });
              Alert.alert("Error", `Failed to delete emergency contact: ${error.message}`);
            }
          },
        },
      ]
    );
  };

  const renderContact = ({ item }) => {
    return (
      <View style={styles.contactCard}>
        <View style={styles.contactInfo}>
          <View style={styles.contactIcon}>
            <Ionicons name="person" size={24} color={colors.primary} />
          </View>
          <View style={styles.contactDetails}>
            <Text style={styles.contactName}>{item.name}</Text>
            <Text style={styles.contactPhone}>{item.phone}</Text>
          </View>
        </View>
        <TouchableOpacity
          style={styles.deleteButton}
          onPress={() => deleteContact(item.id)}
        >
          <Ionicons name="trash-outline" size={20} color="#FF3B30" />
        </TouchableOpacity>
      </View>
    );
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.safeContainer}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.primary} />
          <Text style={styles.loadingText}>Loading emergency contacts...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeContainer} edges={['top']}>
      <ScrollView 
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.container}>
          <View style={styles.header}>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => navigation.goBack()}
            >
              <Ionicons name="chevron-back" size={24} color={colors.primary} />
            </TouchableOpacity>
            <Text style={styles.headerTitle}>Emergency Contacts</Text>
            <View style={styles.placeholder} />
          </View>

        <View style={styles.infoCard}>
          <Ionicons name="information-circle" size={20} color={colors.primary} />
          <Text style={styles.infoText}>
            Add up to {MAX_CONTACTS} emergency contacts. These contacts can be notified in case of emergencies.
          </Text>
        </View>

        {contacts.length < MAX_CONTACTS && (
          <TouchableOpacity
            style={styles.addButton}
            onPress={pickContact}
            disabled={saving}
          >
            <LinearGradient
              colors={[colors.primary, colors.accent]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.addButtonGradient}
            >
              <Ionicons name="add-circle" size={24} color={colors.white} />
              <Text style={styles.addButtonText}>
                {saving ? "Adding..." : "Add Emergency Contact"}
              </Text>
            </LinearGradient>
          </TouchableOpacity>
        )}

          {contacts.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="people-outline" size={64} color={colors.textLight} />
              <Text style={styles.emptyText}>No emergency contacts</Text>
              <Text style={styles.emptySubtext}>
                Add up to {MAX_CONTACTS} emergency contacts from your phone
              </Text>
            </View>
          ) : (
            <View style={styles.contactsSection}>
              <Text style={styles.sectionTitle}>
                Emergency Contacts ({contacts.length}/{MAX_CONTACTS})
              </Text>
              {contacts.map((contact) => renderContact({ item: contact }))}
            </View>
          )}
        </View>
      </ScrollView>

      <Modal
        visible={showContactPicker}
        animationType="slide"
        transparent={false}
        onRequestClose={() => setShowContactPicker(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity
              onPress={() => setShowContactPicker(false)}
              style={styles.modalCloseButton}
            >
              <Ionicons name="close" size={24} color={colors.textDark} />
            </TouchableOpacity>
            <Text style={styles.modalTitle}>Select Emergency Contact</Text>
            <View style={styles.placeholder} />
          </View>

          <View style={styles.searchContainer}>
            <Ionicons name="search" size={20} color={colors.textLight} style={styles.searchIcon} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search contacts..."
              value={searchQuery}
              onChangeText={setSearchQuery}
              placeholderTextColor={colors.textLight}
            />
            {searchQuery.length > 0 && (
              <TouchableOpacity
                onPress={() => setSearchQuery("")}
                style={styles.clearButton}
              >
                <Ionicons name="close-circle" size={20} color={colors.textLight} />
              </TouchableOpacity>
            )}
          </View>

          {filteredAvailableContacts.length === 0 ? (
            <View style={styles.emptyModalState}>
              <Ionicons name="people-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyModalText}>
                {searchQuery ? "No contacts found" : "No contacts available"}
              </Text>
            </View>
          ) : (
            <FlatList
              data={filteredAvailableContacts}
              renderItem={renderContactItem}
              keyExtractor={(item, index) => item.id || index.toString()}
              contentContainerStyle={styles.modalListContent}
              showsVerticalScrollIndicator={true}
            />
          )}
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingBottom: 100, // Add bottom padding to prevent content from overlapping with navbar
  },
  container: {
    flex: 1,
    padding: 20,
    paddingTop: 10, // Reduced top padding since SafeAreaView handles it
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 20,
    marginTop: 20, // Increased top margin to ensure header is visible
    paddingTop: 10, // Additional padding to ensure visibility
  },
  backButton: {
    padding: 5,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: "700",
    color: colors.primary,
  },
  placeholder: {
    width: 34,
  },
  infoCard: {
    flexDirection: "row",
    backgroundColor: "#E3F2FD",
    padding: 12,
    borderRadius: 12,
    marginBottom: 20,
    alignItems: "flex-start",
  },
  infoText: {
    flex: 1,
    fontSize: 13,
    color: colors.textDark,
    marginLeft: 8,
    lineHeight: 18,
  },
  addButton: {
    borderRadius: 16,
    overflow: "hidden",
    marginBottom: 20,
    elevation: 3,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  addButtonGradient: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 16,
    paddingHorizontal: 20,
  },
  addButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "600",
    marginLeft: 8,
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 60,
    minHeight: 300, // Ensure empty state has minimum height
  },
  emptyText: {
    fontSize: 18,
    fontWeight: "600",
    color: colors.textDark,
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: colors.textLight,
    marginTop: 8,
    textAlign: "center",
  },
  contactsSection: {
    marginBottom: 20, // Add bottom margin for spacing
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 16,
  },
  contactCard: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  contactInfo: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  contactIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#E3F2FD",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 12,
  },
  contactDetails: {
    flex: 1,
  },
  contactName: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 4,
  },
  contactPhone: {
    fontSize: 14,
    color: colors.textLight,
  },
  deleteButton: {
    padding: 8,
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: colors.textLight,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  modalHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: "#E0E0E0",
  },
  modalCloseButton: {
    padding: 5,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: "700",
    color: colors.textDark,
  },
  searchContainer: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.white,
    marginHorizontal: 20,
    marginVertical: 16,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  searchIcon: {
    marginRight: 12,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: colors.textDark,
  },
  clearButton: {
    padding: 4,
  },
  modalListContent: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  contactPickerItem: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.white,
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    elevation: 1,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  contactPickerIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#E3F2FD",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 12,
  },
  contactPickerInfo: {
    flex: 1,
  },
  contactPickerName: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 4,
  },
  contactPickerPhone: {
    fontSize: 14,
    color: colors.textLight,
  },
  emptyModalState: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 60,
  },
  emptyModalText: {
    fontSize: 16,
    color: colors.textLight,
    marginTop: 16,
  },
});

