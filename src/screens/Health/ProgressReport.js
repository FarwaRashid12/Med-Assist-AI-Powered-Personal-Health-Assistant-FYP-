import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Alert,
  Modal,
  SafeAreaView,
  Platform,
  Image,
} from "react-native";
import { SafeAreaView as RNSafeAreaView } from "react-native-safe-area-context";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import { ref, set, get } from "firebase/database";
import { db } from "../../context/firebaseConfig";
import { useAuth } from "../../context/AuthContext";
import * as Sharing from "expo-sharing";
import * as FileSystem from "expo-file-system/legacy";
import * as Print from "expo-print";
import { Asset } from "expo-asset";
import AsyncStorage from "@react-native-async-storage/async-storage";
import colors from "../../constants/colors";

// Import the logo
const logoSource = require("../../assets/icons/medassist_logo.png");

export default function ProgressReport({ navigation }) {
  const { user, userData } = useAuth();
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  // Form inputs
  const [systolic, setSystolic] = useState("");
  const [diastolic, setDiastolic] = useState("");
  const [pulse, setPulse] = useState("");
  const [sugar, setSugar] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [time, setTime] = useState(
    new Date().toTimeString().split(" ")[0].slice(0, 5)
  );

  useEffect(() => {
    if (user) {
      loadReports();
    }
  }, [user]);

  const loadReports = async () => {
    if (!user) return;

    try {
      setLoading(true);
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
            const dateA = new Date(`${a.date}T${a.time}`);
            const dateB = new Date(`${b.date}T${b.time}`);
            return dateB - dateA; // Most recent first
          });
        setReports(reportsArray);
      } else {
        setReports([]);
      }
    } catch (error) {
      console.error("Error loading reports:", error);
      Alert.alert("Error", "Failed to load progress reports.");
    } finally {
      setLoading(false);
    }
  };

  const validateInputs = () => {
    if (!systolic || !diastolic) {
      Alert.alert("Error", "Please enter both Systolic and Diastolic values.");
      return false;
    }

    const sys = parseInt(systolic);
    const dia = parseInt(diastolic);

    if (isNaN(sys) || sys < 50 || sys > 250) {
      Alert.alert("Error", "Systolic should be between 50 and 250.");
      return false;
    }

    if (isNaN(dia) || dia < 30 || dia > 150) {
      Alert.alert("Error", "Diastolic should be between 30 and 150.");
      return false;
    }

    if (pulse && (isNaN(parseInt(pulse)) || parseInt(pulse) < 30 || parseInt(pulse) > 200)) {
      Alert.alert("Error", "Pulse rate should be between 30 and 200 bpm.");
      return false;
    }

    if (sugar && (isNaN(parseInt(sugar)) || parseInt(sugar) < 50 || parseInt(sugar) > 500)) {
      Alert.alert("Error", "Blood sugar should be between 50 and 500 mg/dL.");
      return false;
    }

    return true;
  };

  const handleSave = async () => {
    if (!validateInputs()) return;

    if (!user) {
      Alert.alert("Error", "User not logged in.");
      return;
    }

    try {
      const reportData = {
        systolic: parseInt(systolic),
        diastolic: parseInt(diastolic),
        pulse: pulse ? parseInt(pulse) : null,
        sugar: sugar ? parseInt(sugar) : null,
        date,
        time,
        timestamp: new Date().toISOString(),
      };

      if (editingIndex !== null) {
        // Update existing report
        const reportId = reports[editingIndex].id;
        const reportRef = ref(db, `users/${user.uid}/progressReports/${reportId}`);
        await set(reportRef, reportData);
        Alert.alert("Success", "Progress report updated successfully!");
      } else {
        // Add new report with timestamp as key
        const timestamp = Date.now();
        const reportRef = ref(db, `users/${user.uid}/progressReports/${timestamp}`);
        await set(reportRef, reportData);
        Alert.alert("Success", "Progress report added successfully!");
      }

      // Reset form
      setSystolic("");
      setDiastolic("");
      setPulse("");
      setSugar("");
      setDate(new Date().toISOString().split("T")[0]);
      setTime(new Date().toTimeString().split(" ")[0].slice(0, 5));
      setShowAddModal(false);
      setEditingIndex(null);

      // Reload reports
      await loadReports();
    } catch (error) {
      console.error("Error saving report:", error);
      Alert.alert("Error", "Failed to save progress report.");
    }
  };

  const handleEdit = (index) => {
    const report = reports[index];
    setSystolic(report.systolic.toString());
    setDiastolic(report.diastolic.toString());
    setPulse(report.pulse ? report.pulse.toString() : "");
    setSugar(report.sugar ? report.sugar.toString() : "");
    setDate(report.date);
    setTime(report.time);
    setEditingIndex(index);
    setShowAddModal(true);
  };

  const handleDelete = (index) => {
    Alert.alert(
      "Delete Report",
      "Are you sure you want to delete this progress report?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            if (!user) return;
            try {
              const reportId = reports[index].id;
              const reportRef = ref(db, `users/${user.uid}/progressReports/${reportId}`);
              await set(reportRef, null);
              await loadReports();
              Alert.alert("Success", "Report deleted successfully.");
            } catch (error) {
              console.error("Error deleting report:", error);
              Alert.alert("Error", "Failed to delete report.");
            }
          },
        },
      ]
    );
  };

  const generatePDFHTML = async (report, logoBase64, medications = []) => {
    const bpStatus = getBPStatus(report.systolic, report.diastolic);
    const userName = userData?.fullName || userData?.displayName || "User";
    const userGender = userData?.gender || "Not specified";
    const userAge = userData?.age || "Not specified";
    const statusColor = bpStatus.color;
    
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: Arial, sans-serif;
              padding: 40px;
              color: #333;
              line-height: 1.6;
              position: relative;
            }
            .logo-container {
              position: absolute;
              top: 20px;
              right: 40px;
              width: 70px;
              height: 70px;
              z-index: 10;
            }
            .logo-container img {
              width: 100%;
              height: 100%;
              object-fit: contain;
            }
            .header {
              text-align: center;
              margin-bottom: 30px;
              border-bottom: 3px solid #0077B6;
              padding-bottom: 20px;
              padding-right: 90px;
              position: relative;
            }
            .header h1 {
              color: #0077B6;
              margin: 0;
              font-size: 28px;
            }
            .header p {
              color: #666;
              margin: 5px 0;
              font-size: 14px;
            }
            .info-section {
              margin-bottom: 25px;
            }
            .info-row {
              display: flex;
              justify-content: space-between;
              margin-bottom: 10px;
              padding: 8px 0;
              border-bottom: 1px solid #eee;
            }
            .info-row-pair {
              display: flex;
              justify-content: space-between;
              margin-bottom: 10px;
              padding: 8px 0;
              border-bottom: 1px solid #eee;
            }
            .info-item {
              flex: 1;
              display: flex;
              flex-direction: column;
            }
            .info-item:first-child {
              margin-right: 40px;
            }
            .info-label {
              font-weight: bold;
              color: #555;
              margin-bottom: 4px;
            }
            .info-value {
              color: #333;
            }
            .metrics-section {
              margin-top: 30px;
              background-color: #f9f9f9;
              padding: 20px;
              border-radius: 8px;
            }
            .metrics-section h2 {
              color: #0077B6;
              margin-top: 0;
              margin-bottom: 20px;
              font-size: 20px;
            }
            .metric-item {
              margin-bottom: 15px;
              padding: 12px;
              background-color: white;
              border-radius: 5px;
              border-left: 4px solid #0077B6;
            }
            .metric-label {
              font-weight: bold;
              color: #555;
              margin-bottom: 5px;
            }
            .metric-value {
              font-size: 18px;
              color: #0077B6;
              font-weight: bold;
            }
            .status-badge {
              display: inline-block;
              padding: 5px 12px;
              border-radius: 15px;
              color: white;
              font-size: 12px;
              font-weight: bold;
              margin-left: 10px;
              background-color: ${statusColor};
            }
            .footer {
              margin-top: 40px;
              text-align: center;
              color: #999;
              font-size: 12px;
              border-top: 1px solid #eee;
              padding-top: 20px;
            }
            .dosage-section {
              margin-top: 30px;
              background-color: #f9f9f9;
              padding: 20px;
              border-radius: 8px;
            }
            .dosage-section h2 {
              color: #0077B6;
              margin-top: 0;
              margin-bottom: 20px;
              font-size: 20px;
            }
            .dosage-table {
              width: 100%;
              border-collapse: collapse;
              background-color: white;
              border-radius: 5px;
              overflow: hidden;
            }
            .dosage-row {
              border-bottom: 1px solid #eee;
            }
            .dosage-row:last-child {
              border-bottom: none;
            }
            .dosage-row:hover {
              background-color: #f5f5f5;
            }
            .dosage-medicine {
              padding: 12px 15px;
              font-weight: bold;
              color: #0077B6;
              font-size: 15px;
              width: 50%;
            }
            .dosage-value {
              padding: 12px 15px;
              color: #333;
              font-size: 14px;
              width: 50%;
            }
            .dosage-header {
              background-color: #0077B6;
              color: white;
              font-weight: bold;
              padding: 12px 15px;
              font-size: 14px;
            }
            .no-medications {
              text-align: center;
              color: #999;
              padding: 20px;
              font-style: italic;
            }
          </style>
        </head>
        <body>
          ${logoBase64 ? `
          <div class="logo-container">
            <img src="data:image/png;base64,${logoBase64}" alt="MedAssist Logo" />
          </div>
          ` : ''}
          <div class="header">
            <h1>Progress Report</h1>
            <p>${userName}</p>
          </div>
          
          <div class="info-section">
            <div class="info-row-pair">
              <div class="info-item">
                <span class="info-label">Name:</span>
                <span class="info-value">${userName}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Gender:</span>
                <span class="info-value">${userGender}</span>
              </div>
            </div>
            <div class="info-row-pair">
              <div class="info-item">
                <span class="info-label">Age:</span>
                <span class="info-value">${userAge} years</span>
              </div>
              <div class="info-item">
                <span class="info-label">Date:</span>
                <span class="info-value">${report.date}</span>
              </div>
            </div>
            <div class="info-row-pair">
              <div class="info-item">
                <span class="info-label">Time:</span>
                <span class="info-value">${report.time}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Generated on:</span>
                <span class="info-value">${new Date().toLocaleString()}</span>
              </div>
            </div>
          </div>
          
          <div class="metrics-section">
            <h2>Health Metrics</h2>
            
            <div class="metric-item">
              <div class="metric-label">Blood Pressure</div>
              <div class="metric-value">
                ${report.systolic}/${report.diastolic} mmHg
                <span class="status-badge">${bpStatus.text}</span>
              </div>
            </div>
            
            ${report.pulse ? `
            <div class="metric-item">
              <div class="metric-label">Pulse Rate</div>
              <div class="metric-value">${report.pulse} bpm</div>
            </div>
            ` : ''}
            
            ${report.sugar ? `
            <div class="metric-item">
              <div class="metric-label">Blood Sugar</div>
              <div class="metric-value">${report.sugar} mg/dL</div>
            </div>
            ` : ''}
          </div>
          
          ${medications.length > 0 ? `
          <div class="dosage-section">
            <h2>Current Medications & Dosage</h2>
            <table class="dosage-table">
              <tr>
                <th class="dosage-header">Medicine Name</th>
                <th class="dosage-header">Dosage</th>
              </tr>
              ${medications.map(med => `
                <tr class="dosage-row">
                  <td class="dosage-medicine">${med.medicine || med.name || 'Unknown Medicine'}</td>
                  <td class="dosage-value">${med.dosage || 'Not specified'}</td>
                </tr>
              `).join('')}
            </table>
          </div>
          ` : ''}
          
          <div class="footer">
            <p>Generated by MedAssist - Your Personal Health Assistant</p>
          </div>
        </body>
      </html>
    `;
    
    return html;
  };

  const handleDownloadSingle = async (report) => {
    try {
      const userName = userData?.fullName || userData?.displayName || "User";
      // Clean the username: keep letters, numbers, and spaces, remove other special characters
      const cleanedUserName = userName.replace(/[^a-zA-Z0-9\s]/g, "").trim();
      const fileName = `${cleanedUserName} Health Report.pdf`;
      
      // Load and convert logo to base64
      let logoBase64 = '';
      try {
        // Use Asset.fromModule to properly load the asset in Expo
        const asset = Asset.fromModule(logoSource);
        await asset.downloadAsync();
        
        // Get the local URI of the downloaded asset
        const logoUri = asset.localUri || asset.uri;
        
        if (logoUri) {
          // Read the image file and convert to base64
          logoBase64 = await FileSystem.readAsStringAsync(logoUri, {
            encoding: FileSystem.EncodingType.Base64,
          });
        }
      } catch (error) {
        console.warn("Could not load logo for PDF:", error);
        // Continue without logo if there's an error
        logoBase64 = '';
      }
      
      // Load medications from AsyncStorage
      let medications = [];
      try {
        const prescriptionPlan = await AsyncStorage.getItem("prescriptionPlan");
        if (prescriptionPlan) {
          const parsed = JSON.parse(prescriptionPlan);
          // Filter only medicines with dosage information
          medications = parsed.filter(med => (med.medicine || med.name) && med.dosage);
        }
      } catch (error) {
        console.warn("Could not load medications for PDF:", error);
      }
      
      // Generate PDF from HTML with logo and medications
      const html = await generatePDFHTML(report, logoBase64, medications);
      
      // Generate PDF file - printToFileAsync creates a PDF file and returns its URI
      const { uri } = await Print.printToFileAsync({ html });
      
      // Create the destination file path with the custom filename
      const fileUri = `${FileSystem.documentDirectory}${fileName}`;
      
      // Read the generated PDF file as base64
      const fileBase64 = await FileSystem.readAsStringAsync(uri, {
        encoding: FileSystem.EncodingType.Base64,
      });
      
      // Write the PDF to the desired location with custom filename
      await FileSystem.writeAsStringAsync(fileUri, fileBase64, {
        encoding: FileSystem.EncodingType.Base64,
      });

      // Share the PDF file
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(fileUri, {
          mimeType: "application/pdf",
          dialogTitle: `Share ${cleanedUserName} Health Report`,
          UTI: "com.adobe.pdf",
        });
      } else {
        Alert.alert("Success", `Report saved as: ${fileName}`);
      }
    } catch (error) {
      console.error("Error downloading report:", error);
      Alert.alert("Error", `Failed to download report: ${error.message}`);
    }
  };

  const getBPStatus = (systolic, diastolic) => {
    if (systolic < 90 || diastolic < 60) return { text: "Low", color: "#4A90E2" };
    if (systolic < 120 && diastolic < 80) return { text: "Normal", color: "#4CAF50" };
    if (systolic < 130 && diastolic < 80) return { text: "Elevated", color: "#FFC107" };
    if (systolic < 140 || diastolic < 90) return { text: "High Stage 1", color: "#FF9800" };
    if (systolic < 180 || diastolic < 120) return { text: "High Stage 2", color: "#F44336" };
    return { text: "Crisis", color: "#D32F2F" };
  };

  return (
    <RNSafeAreaView style={styles.safeContainer} edges={["top"]}>
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
            <Ionicons name="arrow-back" size={24} color={colors.white} />
          </TouchableOpacity>
          <Text style={styles.headerText}>Progress Report</Text>
          <View style={styles.downloadButton} />
        </LinearGradient>

        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Add Report Button */}
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => {
              setEditingIndex(null);
              setSystolic("");
              setDiastolic("");
              setPulse("");
              setSugar("");
              setDate(new Date().toISOString().split("T")[0]);
              setTime(new Date().toTimeString().split(" ")[0].slice(0, 5));
              setShowAddModal(true);
            }}
          >
            <LinearGradient
              colors={[colors.primary, colors.accent]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.addButtonGradient}
            >
              <Ionicons name="add-circle" size={20} color={colors.white} />
              <Text style={styles.addButtonText}>Add Progress Report</Text>
            </LinearGradient>
          </TouchableOpacity>

          {/* Reports List */}
          <View style={styles.reportsSection}>
            <Text style={styles.sectionTitle}>All Reports</Text>
            {reports.length === 0 ? (
              <View style={styles.emptyState}>
                <Ionicons name="document-outline" size={40} color={colors.textLight} />
                <Text style={styles.emptyText}>No reports yet</Text>
                <Text style={styles.emptySubtext}>
                  Add your first progress report to track your health
                </Text>
              </View>
            ) : (
              reports.map((report, index) => {
                const bpStatus = getBPStatus(report.systolic, report.diastolic);
                return (
                  <View key={report.id} style={styles.reportCard}>
                    <View style={styles.reportCardHeader}>
                      <View style={styles.reportCardLeft}>
                        <View style={styles.reportIconContainer}>
                          <MaterialCommunityIcons
                            name="heart-pulse"
                            size={18}
                            color={colors.white}
                          />
                        </View>
                        <View style={styles.reportCardTitleSection}>
                          <Text style={styles.reportCardTitle}>
                            {report.date} • {report.time}
                          </Text>
                          <Text style={styles.reportCardCategory}>Health Report</Text>
                        </View>
                      </View>
                      <View style={styles.reportCardActions}>
                        <TouchableOpacity
                          style={styles.actionButton}
                          onPress={() => handleDownloadSingle(report)}
                        >
                          <Ionicons name="download-outline" size={16} color={colors.primary} />
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={styles.actionButton}
                          onPress={() => handleEdit(index)}
                        >
                          <Ionicons name="create-outline" size={16} color={colors.primary} />
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={styles.actionButton}
                          onPress={() => handleDelete(index)}
                        >
                          <Ionicons name="trash-outline" size={16} color="#FF3B30" />
                        </TouchableOpacity>
                      </View>
                    </View>

                    <View style={styles.reportCardContent}>
                      {/* Blood Pressure */}
                      <View style={styles.dataField}>
                        <Text style={styles.dataLabel}>Blood Pressure:</Text>
                        <Text style={styles.dataValue}>
                          {report.systolic}/{report.diastolic} mmHg
                        </Text>
                        <View style={[styles.statusBadge, { backgroundColor: bpStatus.color }]}>
                          <Text style={styles.statusBadgeText}>{bpStatus.text}</Text>
                        </View>
                      </View>

                      {/* Pulse Rate */}
                      {report.pulse && (
                        <View style={styles.dataField}>
                          <Text style={styles.dataLabel}>Pulse Rate:</Text>
                          <Text style={styles.dataValue}>{report.pulse} bpm</Text>
                        </View>
                      )}

                      {/* Blood Sugar */}
                      {report.sugar && (
                        <View style={styles.dataField}>
                          <Text style={styles.dataLabel}>Blood Sugar:</Text>
                          <Text style={styles.dataValue}>{report.sugar} mg/dL</Text>
                        </View>
                      )}
                    </View>
                  </View>
                );
              })
            )}
          </View>
        </ScrollView>

        {/* Add/Edit Modal */}
        <Modal
          visible={showAddModal}
          animationType="slide"
          transparent={true}
          onRequestClose={() => setShowAddModal(false)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>
                  {editingIndex !== null ? "Edit Report" : "Add Progress Report"}
                </Text>
                <TouchableOpacity
                  onPress={() => setShowAddModal(false)}
                  style={styles.modalCloseButton}
                >
                  <Ionicons name="close" size={24} color={colors.textDark} />
                </TouchableOpacity>
              </View>

              <ScrollView style={styles.modalScroll} showsVerticalScrollIndicator={false}>
                {/* Date and Time */}
                <View style={styles.inputRow}>
                  <View style={styles.inputGroup}>
                    <Text style={styles.inputLabel}>Date</Text>
                    <TextInput
                      style={styles.input}
                      value={date}
                      onChangeText={setDate}
                      placeholder="YYYY-MM-DD"
                      placeholderTextColor={colors.textLight}
                    />
                  </View>
                  <View style={styles.inputGroup}>
                    <Text style={styles.inputLabel}>Time</Text>
                    <TextInput
                      style={styles.input}
                      value={time}
                      onChangeText={setTime}
                      placeholder="HH:MM"
                      placeholderTextColor={colors.textLight}
                    />
                  </View>
                </View>

                {/* Blood Pressure */}
                <View style={styles.inputSection}>
                  <Text style={styles.inputLabel}>
                    Blood Pressure <Text style={styles.required}>*</Text>
                  </Text>
                  <View style={styles.bpInputRow}>
                    <View style={styles.bpInputGroup}>
                      <Text style={styles.bpInputLabel}>Systolic</Text>
                      <TextInput
                        style={styles.bpInput}
                        value={systolic}
                        onChangeText={setSystolic}
                        placeholder="120"
                        keyboardType="numeric"
                        placeholderTextColor={colors.textLight}
                      />
                    </View>
                    <Text style={styles.bpDivider}>/</Text>
                    <View style={styles.bpInputGroup}>
                      <Text style={styles.bpInputLabel}>Diastolic</Text>
                      <TextInput
                        style={styles.bpInput}
                        value={diastolic}
                        onChangeText={setDiastolic}
                        placeholder="80"
                        keyboardType="numeric"
                        placeholderTextColor={colors.textLight}
                      />
                    </View>
                  </View>
                  <Text style={styles.inputHint}>Normal: 120/80 mmHg</Text>
                </View>

                {/* Pulse Rate */}
                <View style={styles.inputSection}>
                  <Text style={styles.inputLabel}>Pulse Rate (bpm)</Text>
                  <TextInput
                    style={styles.input}
                    value={pulse}
                    onChangeText={setPulse}
                    placeholder="72"
                    keyboardType="numeric"
                    placeholderTextColor={colors.textLight}
                  />
                  <Text style={styles.inputHint}>Normal: 60-100 bpm</Text>
                </View>

                {/* Blood Sugar */}
                <View style={styles.inputSection}>
                  <Text style={styles.inputLabel}>Blood Sugar (mg/dL)</Text>
                  <TextInput
                    style={styles.input}
                    value={sugar}
                    onChangeText={setSugar}
                    placeholder="100"
                    keyboardType="numeric"
                    placeholderTextColor={colors.textLight}
                  />
                  <Text style={styles.inputHint}>Normal: 70-100 mg/dL (fasting)</Text>
                </View>
              </ScrollView>

              <View style={styles.modalActions}>
                <TouchableOpacity
                  style={styles.cancelButton}
                  onPress={() => setShowAddModal(false)}
                >
                  <Text style={styles.cancelButtonText}>Cancel</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.saveButton}
                  onPress={handleSave}
                >
                  <LinearGradient
                    colors={[colors.primary, colors.accent]}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.saveButtonGradient}
                  >
                    <Text style={styles.saveButtonText}>
                      {editingIndex !== null ? "Update" : "Save"}
                    </Text>
                  </LinearGradient>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      </View>
    </RNSafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  container: {
    flex: 1,
  },
  header: {
    paddingTop: Platform.OS === "android" ? 15 : 20,
    paddingBottom: 20,
    paddingHorizontal: 20,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    elevation: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  backButton: {
    padding: 5,
  },
  headerText: {
    color: colors.white,
    fontSize: 18,
    fontWeight: "700",
    flex: 1,
    textAlign: "center",
  },
  downloadButton: {
    padding: 5,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 100,
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
    fontSize: 14,
    fontWeight: "700",
    marginLeft: 8,
  },
  summaryCard: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    elevation: 3,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  summaryTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.textDark,
    marginBottom: 12,
  },
  summaryRow: {
    flexDirection: "row",
    justifyContent: "space-around",
    marginBottom: 12,
  },
  summaryItem: {
    alignItems: "center",
    flex: 1,
  },
  summaryLabel: {
    fontSize: 12,
    color: colors.textLight,
    marginTop: 6,
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.primary,
    marginBottom: 4,
  },
  summaryStatus: {
    fontSize: 10,
    fontWeight: "600",
  },
  summaryDate: {
    fontSize: 11,
    color: colors.textLight,
    textAlign: "center",
    marginTop: 8,
  },
  reportsSection: {
    marginTop: 10,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.textDark,
    marginBottom: 12,
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.textDark,
    marginTop: 12,
  },
  emptySubtext: {
    fontSize: 12,
    color: colors.textLight,
    marginTop: 6,
    textAlign: "center",
  },
  reportCard: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
  },
  reportCardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#F0F0F0",
  },
  reportCardLeft: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  reportIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: colors.primary,
    alignItems: "center",
    justifyContent: "center",
    marginRight: 10,
  },
  reportCardTitleSection: {
    flex: 1,
  },
  reportCardTitle: {
    fontSize: 15,
    fontWeight: "700",
    color: colors.textDark,
    marginBottom: 2,
  },
  reportCardCategory: {
    fontSize: 12,
    color: colors.textLight,
  },
  reportCardActions: {
    flexDirection: "row",
    alignItems: "center",
  },
  actionButton: {
    padding: 6,
    marginLeft: 8,
  },
  reportCardContent: {
    gap: 8,
  },
  dataField: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 6,
    flexWrap: "wrap",
  },
  dataLabel: {
    fontSize: 13,
    fontWeight: "500",
    color: colors.textDark,
    marginRight: 8,
    minWidth: 100,
  },
  dataValue: {
    fontSize: 13,
    fontWeight: "700",
    color: colors.textDark,
    flex: 1,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginLeft: 8,
  },
  statusBadgeText: {
    fontSize: 10,
    fontWeight: "600",
    color: colors.white,
  },
  // Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "flex-end",
  },
  modalContent: {
    backgroundColor: colors.white,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: "90%",
    paddingBottom: Platform.OS === "ios" ? 30 : 20,
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: "#F0F0F0",
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: "700",
    color: colors.textDark,
  },
  modalCloseButton: {
    padding: 5,
  },
  modalScroll: {
    maxHeight: 400,
  },
  inputRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  inputGroup: {
    flex: 1,
    marginHorizontal: 5,
  },
  inputSection: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 8,
  },
  required: {
    color: "#FF3B30",
  },
  input: {
    backgroundColor: "#F5F5F5",
    borderRadius: 10,
    padding: 12,
    fontSize: 14,
    color: colors.textDark,
    borderWidth: 1,
    borderColor: "#E0E0E0",
  },
  inputHint: {
    fontSize: 11,
    color: colors.textLight,
    marginTop: 6,
  },
  bpInputRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  bpInputGroup: {
    flex: 1,
  },
  bpInputLabel: {
    fontSize: 11,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 6,
  },
  bpInput: {
    backgroundColor: "#F5F5F5",
    borderRadius: 10,
    padding: 12,
    fontSize: 16,
    fontWeight: "700",
    color: colors.textDark,
    textAlign: "center",
    borderWidth: 1,
    borderColor: "#E0E0E0",
  },
  bpDivider: {
    fontSize: 20,
    fontWeight: "700",
    color: colors.textDark,
    marginHorizontal: 10,
    marginTop: 20,
  },
  modalActions: {
    flexDirection: "row",
    paddingHorizontal: 20,
    paddingTop: 20,
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: "#F5F5F5",
    alignItems: "center",
    justifyContent: "center",
  },
  cancelButtonText: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.textDark,
  },
  saveButton: {
    flex: 1,
    borderRadius: 12,
    overflow: "hidden",
  },
  saveButtonGradient: {
    paddingVertical: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  saveButtonText: {
    fontSize: 14,
    fontWeight: "700",
    color: colors.white,
  },
});
