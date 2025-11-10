import React, { useState } from 'react';
import {
  View,
  Text,
  Alert,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Image,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { extractPrescriptionFromImage } from "../../utils/extractPrescriptionFromImage";
import { extractTextFromImage } from "../../utils/openaiVisionOCR";
import { extractPrescriptionData } from "../../utils/extractPrescriptionData";
import { validatePrescription } from "../../utils/validatePrescription";
import MedicineDetailsModal from "../../components/MedicineDetailsModal";
import colors from "../../constants/colors";

import AsyncStorage from '@react-native-async-storage/async-storage';

const UploadPrescription = ({ navigation }) => {
  const [loading, setLoading] = useState(false);
  const [loadingMessage, setLoadingMessage] = useState('Processing image...');
  const [extractedText, setExtractedText] = useState('');
  const [planner, setPlanner] = useState([]);
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreviewVisible, setImagePreviewVisible] = useState(false);
  const [medicineDetailsModalVisible, setMedicineDetailsModalVisible] = useState(false);
  const [currentMedicineIndex, setCurrentMedicineIndex] = useState(null);
  const [medicinesToComplete, setMedicinesToComplete] = useState([]);
  const [completedMedicines, setCompletedMedicines] = useState([]);

  const requestPermissions = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera access is required.');
      return false;
    }
    return true;
  };

  const pickImage = async () => {
    const ok = await requestPermissions();
    if (!ok) return null;

    const result = await ImagePicker.launchCameraAsync({
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (result.canceled) return null;
    setSelectedImage(result.assets[0].uri);
    setImagePreviewVisible(true);
    return null;
  };

  const pickFromGallery = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });
    if (result.canceled) return null;
    setSelectedImage(result.assets[0].uri);
    setImagePreviewVisible(true);
    return null;
  };

  const handleImageConfirm = () => {
    setImagePreviewVisible(false);
    if (selectedImage) {
      processImage(selectedImage);
    }
    setSelectedImage(null);
  };

  const handleImageCancel = () => {
    setImagePreviewVisible(false);
    setSelectedImage(null);
  };

  const runVisionOCR = async (uri) => {
    try {
      const text = await extractTextFromImage(uri);
      return text || '';
    } catch (error) {
      console.error("OCR Error:", error);
      throw error;
    }
  };

  const doseRegex =
    /(?:take|use)\s*([\d.]+)\s*(tablet|capsule|ml|mg|spoon|syringe)?\s*(.*)/i;
  const freqRegex =
    /(daily|twice|thrice|morning|night|every\s*\d+\s*hour|once|after|before)/i;
  const timeRegex = /(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)|(\d{1,2})\s*(?:AM|PM|am|pm))/i;
  const durationRegex = /(\d+)\s*(day|days|week|weeks|month|months)/i;

  const buildPlanner = (text) => {
    const lines = text.split('\n').map((l) => l.trim()).filter(Boolean);
    const items = [];
    let currentMed = '';

    lines.forEach((line) => {
      if (/^[A-Z][A-Za-z\s]+$/.test(line) && !currentMed && line.length > 2) {
        currentMed = line;
        return;
      }

      const dose = line.match(doseRegex);
      const freq = line.match(freqRegex);
      const time = line.match(timeRegex);
      const duration = line.match(durationRegex);

      if (dose || currentMed) {
        items.push({
          medicine: currentMed || null,
          dosage: dose ? `${dose[1]} ${dose[2] || ''}`.trim() : null,
          timing: freq ? freq[0] : null,
          frequency: freq ? freq[0] : null,
          duration: duration ? `${duration[1]} ${duration[2]}` : null,
          instructions: dose && dose[3] ? dose[3].trim() : null,
          time: time ? time[0] : null,
        });
        currentMed = '';
      }
    });

    return items.length > 0 
      ? items 
      : [{ 
          medicine: null, 
          dosage: null, 
          timing: null,
          frequency: null,
          duration: null,
          instructions: null,
          time: null,
        }];
  };

  const normalizeMedicineForDisplay = (medicine) => {
    return {
      medicine: medicine.name || medicine.medicine || null,
      dosage: medicine.dosage || null,
      timing: medicine.timing || medicine.time || null,
      frequency: medicine.frequency || null,
      duration: medicine.duration || null,
      instructions: medicine.instructions || medicine.instruction || "no instruction given",
      time: medicine.time || medicine.timing || null,
      reminderSet: medicine.reminderSet || false,
    };
  };

  const checkMissingFields = (medicines) => {
    const missing = [];
    medicines.forEach((medicine, index) => {
      if (!medicine.frequency || !medicine.timing) {
        missing.push({ ...medicine, index });
      }
    });
    return missing;
  };

  const handleMedicineDetailsConfirm = async (updatedMedicine) => {
    const updatedMedicines = [...completedMedicines];
    const normalizedMedicine = {
      ...normalizeMedicineForDisplay(updatedMedicine),
      selectedTime: updatedMedicine.selectedTime,
      selectedTimeISO: updatedMedicine.selectedTime ? updatedMedicine.selectedTime.toISOString() : null,
    };
    updatedMedicines[currentMedicineIndex] = normalizedMedicine;
    setCompletedMedicines(updatedMedicines);

    const nextIndex = currentMedicineIndex + 1;
    if (nextIndex < medicinesToComplete.length) {
      setCurrentMedicineIndex(nextIndex);
    } else {
      const medicinesForStorage = updatedMedicines.map(m => ({
        ...m,
        selectedTime: m.selectedTime ? m.selectedTime.toISOString() : null,
      }));
      
      setMedicineDetailsModalVisible(false);
      await AsyncStorage.setItem("prescriptionPlan", JSON.stringify(medicinesForStorage));
      
      Alert.alert(
        "✅ Success",
        `Prescription analyzed successfully!\n\nFound ${updatedMedicines.length} medicine(s).\n\nGo to Reminders tab to set reminders.`,
        [
          {
            text: "OK",
            onPress: () => {
            }
          }
        ]
      );
      setLoading(false);
      setLoadingMessage('Processing image...');
      setCurrentMedicineIndex(null);
      setMedicinesToComplete([]);
      setPlanner([]);
    }
  };

  const processImage = async (uri) => {
    setLoading(true);
    setExtractedText('');
    setPlanner([]);
    
    try {
      setLoadingMessage('Validating prescription...');
      const validation = await validatePrescription(uri);
      
      if (!validation.isPrescription) {
        Alert.alert(
          "Invalid Image",
          "This image may not be a prescription. Please upload a clear image of a medical prescription.",
          [{ text: "OK" }]
        );
        setLoading(false);
        setLoadingMessage('Processing image...');
        return;
      }

      setLoadingMessage('Extracting prescription details...');

      try {
        const structured = await extractPrescriptionFromImage(uri);
        
        if (structured && structured.medicines && structured.medicines.length > 0) {
          const normalizedMedicines = structured.medicines.map(normalizeMedicineForDisplay);
          
          setMedicinesToComplete(normalizedMedicines);
          setCompletedMedicines(normalizedMedicines);
          setCurrentMedicineIndex(0);
          setMedicineDetailsModalVisible(true);
          setLoading(false);
          setLoadingMessage('Processing image...');
          
          const textPreview = normalizedMedicines.map(m => 
            `${m.medicine || 'Unknown'}: ${m.dosage || 'N/A'} - ${m.frequency || 'N/A'}`
          ).join('\n');
          setExtractedText(textPreview || 'Text extracted successfully');
          return;
        }
      } catch (directError) {
        console.log("Direct extraction failed, trying two-step process:", directError);
      }

      try {
        const text = await runVisionOCR(uri);
        if (!text || text.trim().length === 0) {
          Alert.alert("⚠️ Warning", "Could not extract text from image. Please try again with a clearer image.");
          setLoading(false);
          return;
        }
        
        setExtractedText(text);

        const structured = await extractPrescriptionData(text);
        
        if (structured && structured.medicines && structured.medicines.length > 0) {
          const normalizedMedicines = structured.medicines.map(normalizeMedicineForDisplay);
          
          setMedicinesToComplete(normalizedMedicines);
          setCompletedMedicines(normalizedMedicines);
          setCurrentMedicineIndex(0);
          setMedicineDetailsModalVisible(true);
          setLoading(false);
          setLoadingMessage('Processing image...');
          
          const textPreview = normalizedMedicines.map(m => 
            `${m.medicine || 'Unknown'}: ${m.dosage || 'N/A'} - ${m.frequency || 'N/A'}`
          ).join('\n');
          setExtractedText(textPreview || 'Text extracted successfully');
          return;
        } else {
          Alert.alert("⚠️ Partial Extraction", "Using fallback extraction method. Some details may be missing.");
          const fallback = buildPlanner(text);
          const normalizedFallback = fallback.map(normalizeMedicineForDisplay);
          
          setMedicinesToComplete(normalizedFallback);
          setCompletedMedicines(normalizedFallback);
          setCurrentMedicineIndex(0);
          setMedicineDetailsModalVisible(true);
          setLoading(false);
          setLoadingMessage('Processing image...');
        }
      } catch (fallbackError) {
        throw new Error(`Failed to process image: ${fallbackError.message}`);
      }

    } catch (e) {
      console.error("Prescription scan error:", e);
      Alert.alert(
        "❌ Error", 
        e.message || "Failed to process prescription. Please check your internet connection and try again."
      );
    } finally {
      setLoading(false);
      setLoadingMessage('Processing image...');
    }
  };

  const handleScan = async (fromGallery = false) => {
    if (fromGallery) {
      await pickFromGallery();
    } else {
      await pickImage();
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        style={styles.scrollView}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Upload Prescription</Text>
          <Text style={styles.headerSubtitle}>
            Scan or upload your prescription to extract medication information
          </Text>
        </View>

        <View style={styles.uploadSection}>
          <TouchableOpacity
            style={[styles.uploadButton, styles.cameraButton]}
            onPress={() => handleScan(false)}
            disabled={loading}
          >
            <View style={styles.buttonIconContainer}>
              <Ionicons name="camera" size={32} color={colors.white} />
            </View>
            <Text style={styles.uploadButtonText}>Scan Prescription</Text>
            <Text style={styles.uploadButtonSubtext}>Take a photo with camera</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.uploadButton, styles.galleryButton]}
            onPress={() => handleScan(true)}
            disabled={loading}
          >
            <View style={styles.buttonIconContainer}>
              <Ionicons name="images" size={32} color={colors.white} />
            </View>
            <Text style={styles.uploadButtonText}>Choose from Gallery</Text>
            <Text style={styles.uploadButtonSubtext}>Select from your photos</Text>
          </TouchableOpacity>
        </View>

        {loading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
            <Text style={styles.loadingText}>{loadingMessage}</Text>
            <Text style={styles.loadingSubtext}>
              {loadingMessage.includes('Validating') 
                ? 'Checking if image is a prescription' 
                : 'Analyzing prescription content'}
            </Text>
          </View>
        )}

        {extractedText ? (
          <View style={styles.extractedTextContainer}>
            <Text style={styles.extractedTextTitle}>Extracted Text:</Text>
            <Text style={styles.extractedTextContent}>
              {extractedText}
            </Text>
          </View>
        ) : null}

        <Modal
          visible={imagePreviewVisible}
          transparent={true}
          animationType="slide"
          onRequestClose={handleImageCancel}
        >
          <View style={styles.imagePreviewModal}>
            <View style={styles.imagePreviewContainer}>
              <View style={styles.imagePreviewHeader}>
                <Text style={styles.imagePreviewTitle}>Review Image</Text>
                <Text style={styles.imagePreviewSubtitle}>
                  Confirm this image or select another
                </Text>
              </View>
              
              {selectedImage && (
                <Image
                  source={{ uri: selectedImage }}
                  style={styles.previewImage}
                  resizeMode="contain"
                />
              )}

              <View style={styles.imagePreviewActions}>
                <TouchableOpacity
                  style={[styles.actionButton, styles.cancelButton]}
                  onPress={handleImageCancel}
                >
                  <Ionicons name="close-circle" size={28} color={colors.white} />
                  <Text style={styles.actionButtonText}>Cancel</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[styles.actionButton, styles.confirmButton]}
                  onPress={handleImageConfirm}
                >
                  <Ionicons name="checkmark-circle" size={28} color={colors.white} />
                  <Text style={styles.actionButtonText}>Confirm</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

        <MedicineDetailsModal
          visible={medicineDetailsModalVisible}
          medicine={
            currentMedicineIndex !== null && medicinesToComplete.length > 0 && currentMedicineIndex < medicinesToComplete.length
              ? medicinesToComplete[currentMedicineIndex]
              : currentMedicineIndex !== null && completedMedicines.length > 0 && currentMedicineIndex < completedMedicines.length
              ? completedMedicines[currentMedicineIndex]
              : null
          }
          onClose={() => {
            setMedicineDetailsModalVisible(false);
            setCurrentMedicineIndex(null);
            setMedicinesToComplete([]);
            setCompletedMedicines([]);
            setLoading(false);
            setLoadingMessage('Processing image...');
          }}
          onConfirm={handleMedicineDetailsConfirm}
        />
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    paddingTop: 40,
    paddingBottom: 100,
    flexGrow: 1,
  },
  header: {
    marginBottom: 30,
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: 8,
  },
  headerSubtitle: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  uploadSection: {
    marginBottom: 30,
  },
  uploadButton: {
    backgroundColor: colors.primary,
    borderRadius: 20,
    padding: 24,
    marginBottom: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  cameraButton: {
    backgroundColor: colors.primary,
  },
  galleryButton: {
    backgroundColor: '#4CAF50',
  },
  buttonIconContainer: {
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  uploadButtonText: {
    color: colors.white,
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 4,
  },
  uploadButtonSubtext: {
    color: 'rgba(255, 255, 255, 0.9)',
    fontSize: 13,
  },
  loadingContainer: {
    marginTop: 40,
    alignItems: 'center',
    paddingVertical: 30,
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
  },
  loadingSubtext: {
    marginTop: 6,
    fontSize: 13,
    color: colors.textLight,
  },
  imagePreviewModal: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.9)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  imagePreviewContainer: {
    width: '90%',
    maxHeight: '80%',
    backgroundColor: colors.white,
    borderRadius: 20,
    padding: 20,
    alignItems: 'center',
  },
  imagePreviewHeader: {
    width: '100%',
    alignItems: 'center',
    marginBottom: 20,
  },
  imagePreviewTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.textDark,
    marginBottom: 6,
  },
  imagePreviewSubtitle: {
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
  },
  previewImage: {
    width: '100%',
    height: 400,
    borderRadius: 12,
    marginBottom: 20,
    backgroundColor: '#f5f5f5',
  },
  imagePreviewActions: {
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-around',
    gap: 16,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    paddingHorizontal: 20,
    borderRadius: 12,
    gap: 8,
  },
  cancelButton: {
    backgroundColor: '#f44336',
  },
  confirmButton: {
    backgroundColor: '#4CAF50',
  },
  actionButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
  reminderButton: {
    marginTop: 12,
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: colors.primary,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reminderButtonSet: {
    backgroundColor: '#4CAF50',
  },
  reminderButtonText: {
    color: colors.white,
    fontSize: 14,
    fontWeight: '600',
  },
  reminderButtonTextSet: {
    color: colors.white,
  },
  extractedTextContainer: {
    marginTop: 20,
    padding: 16,
    backgroundColor: '#f5f5f5',
    borderRadius: 12,
    marginBottom: 20,
  },
  extractedTextTitle: {
    fontWeight: '700',
    fontSize: 16,
    color: colors.textDark,
    marginBottom: 8,
  },
  extractedTextContent: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: colors.textDark,
    lineHeight: 18,
  },
  plannerContainer: {
    marginTop: 25,
    marginBottom: 20,
  },
  plannerTitle: {
    fontWeight: '700',
    fontSize: 18,
    marginBottom: 16,
    color: colors.textDark,
  },
});

export default UploadPrescription;
