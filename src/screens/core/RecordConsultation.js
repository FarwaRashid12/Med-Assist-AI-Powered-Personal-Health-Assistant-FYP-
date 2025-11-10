import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  Platform,
  Modal,
  ActivityIndicator,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Audio } from "expo-av";
import * as Speech from "expo-speech";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { transcribeAudio, transcribeAudioDetailed, transcribeAndExtractMedicalInfo } from "../../utils/speechToText";
import colors from "../../constants/colors";

const RECORDINGS_KEY = "@medassist_recordings";
const TRANSCRIPTIONS_KEY = "@medassist_transcriptions";

export default function RecordConsultation() {
  const [recording, setRecording] = useState(null);
  const [isRecording, setIsRecording] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [recordings, setRecordings] = useState([]);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const [sound, setSound] = useState(null);
  const [playingIndex, setPlayingIndex] = useState(null);
  const [transcribingIndex, setTranscribingIndex] = useState(null);
  const [transcriptions, setTranscriptions] = useState({});
  const [showTranscriptionModal, setShowTranscriptionModal] = useState(false);
  const [selectedTranscription, setSelectedTranscription] = useState(null);
  const [showTranscriptionOptions, setShowTranscriptionOptions] = useState(false);
  const [selectedRecordingForTranscription, setSelectedRecordingForTranscription] = useState(null);
  const [selectedLanguage, setSelectedLanguage] = useState('auto'); // 'auto', 'en', 'ur'
  const [showLanguageSelector, setShowLanguageSelector] = useState(false);

  useEffect(() => {
    loadRecordings();
    loadTranscriptions();
    return () => {
      if (sound) {
        sound.unloadAsync();
      }
    };
  }, []);

  const loadTranscriptions = async () => {
    try {
      const saved = await AsyncStorage.getItem(TRANSCRIPTIONS_KEY);
      if (saved) {
        setTranscriptions(JSON.parse(saved));
      }
    } catch (error) {
      console.error("Error loading transcriptions:", error);
    }
  };

  const saveTranscription = async (recordingUri, transcription, type = "simple") => {
    try {
      const updated = { ...transcriptions, [recordingUri]: { text: transcription, type, timestamp: new Date().toISOString() } };
      setTranscriptions(updated);
      await AsyncStorage.setItem(TRANSCRIPTIONS_KEY, JSON.stringify(updated));
    } catch (error) {
      console.error("Error saving transcription:", error);
    }
  };

  useEffect(() => {
    let interval = null;
    if (isRecording && !isPaused) {
      interval = setInterval(() => {
        setRecordingDuration((prev) => prev + 1);
      }, 1000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRecording, isPaused]);

  const loadRecordings = async () => {
    try {
      const stored = await AsyncStorage.getItem(RECORDINGS_KEY);
      if (stored) {
        setRecordings(JSON.parse(stored));
      }
    } catch (error) {
      console.error("Error loading recordings:", error);
    }
  };

  const saveRecording = async (newRecording) => {
    try {
      const updated = [newRecording, ...recordings];
      setRecordings(updated);
      await AsyncStorage.setItem(RECORDINGS_KEY, JSON.stringify(updated));
    } catch (error) {
      console.error("Error saving recording:", error);
    }
  };

  const startRecording = async () => {
    try {
      // Clean up any existing recording first
      if (recording) {
        try {
          await recording.stopAndUnloadAsync();
          await recording.unloadAsync();
        } catch (e) {
          console.log("Error cleaning up previous recording:", e);
        }
      }

      // Reset all recording state
      setRecording(null);
      setIsRecording(false);
      setIsPaused(false);
      setRecordingDuration(0);

      // Request permissions
      const permission = await Audio.requestPermissionsAsync();
      if (permission.status !== "granted") {
        Alert.alert("Permission Required", "Please grant microphone permission to record.");
        return;
      }

      // Set audio mode
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      // Start a fresh recording
      const { recording: newRecording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );

      setRecording(newRecording);
      setIsRecording(true);
      setIsPaused(false);
      setRecordingDuration(0); // Ensure duration starts at 0

      // Speak "Your recording has been started"
      Speech.speak("Your recording has been started", {
        language: "en",
        pitch: 1.0,
        rate: 1.0,
      });
    } catch (error) {
      console.error("Failed to start recording:", error);
      Alert.alert("Error", "Failed to start recording. Please try again.");
      // Reset state on error
      setRecording(null);
      setIsRecording(false);
      setIsPaused(false);
      setRecordingDuration(0);
    }
  };

  const pauseRecording = async () => {
    try {
      if (recording) {
        await recording.pauseAsync();
        setIsPaused(true);
      }
    } catch (error) {
      console.error("Failed to pause recording:", error);
    }
  };

  const resumeRecording = async () => {
    try {
      if (recording) {
        await recording.startAsync();
        setIsPaused(false);
      }
    } catch (error) {
      console.error("Failed to resume recording:", error);
    }
  };

  const stopRecording = async () => {
    try {
      if (!recording) return;

      // Get recording info before stopping
      const status = await recording.getStatusAsync();
      const duration = status.durationMillis || 0;
      const uri = recording.getURI();

      // Stop and unload the recording
      await recording.stopAndUnloadAsync();

      // Save recording
      const newRecording = {
        uri,
        duration: Math.floor(duration / 1000),
        timestamp: new Date().toISOString(),
        date: new Date().toLocaleDateString(),
        time: new Date().toLocaleTimeString(),
      };

      await saveRecording(newRecording);

      Alert.alert("Success", "Recording saved successfully!");
    } catch (error) {
      console.error("Failed to stop recording:", error);
      Alert.alert("Error", "Failed to stop recording.");
    } finally {
      // Always reset state after stopping
      setRecording(null);
      setIsRecording(false);
      setIsPaused(false);
      setRecordingDuration(0);
    }
  };

  const playRecording = async (recordingUri, index) => {
    try {
      if (sound) {
        await sound.unloadAsync();
      }

      const { sound: newSound } = await Audio.Sound.createAsync(
        { uri: recordingUri },
        { shouldPlay: true }
      );

      setSound(newSound);
      setPlayingIndex(index);

      newSound.setOnPlaybackStatusUpdate((status) => {
        if (status.didJustFinish) {
          setPlayingIndex(null);
          newSound.unloadAsync();
        }
      });
    } catch (error) {
      console.error("Error playing recording:", error);
      Alert.alert("Error", "Failed to play recording.");
    }
  };

  const stopPlaying = async () => {
    if (sound) {
      await sound.unloadAsync();
      setSound(null);
      setPlayingIndex(null);
    }
  };

  const deleteRecording = async (index) => {
    Alert.alert(
      "Delete Recording",
      "Are you sure you want to delete this recording?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            try {
              const updated = recordings.filter((_, i) => i !== index);
              setRecordings(updated);
              await AsyncStorage.setItem(RECORDINGS_KEY, JSON.stringify(updated));
            } catch (error) {
              console.error("Error deleting recording:", error);
            }
          },
        },
      ]
    );
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  const handleTranscribe = async (recordingUri, index, type = "simple") => {
    try {
      setTranscribingIndex(index);
      setShowTranscriptionOptions(false);
      setShowLanguageSelector(false);
      
      const languageLabel = selectedLanguage === 'auto' ? 'Auto-detect (Urdu/English)' : selectedLanguage === 'ur' ? 'Urdu' : 'English';
      Alert.alert("Transcribing", `Converting audio to text (${languageLabel})... This may take a moment.`);

      let result;
      
      if (type === "detailed") {
        // Get detailed transcription with timestamps
        result = await transcribeAudioDetailed(recordingUri, {
          language: selectedLanguage,
        });
        await saveTranscription(recordingUri, result.text || JSON.stringify(result), "detailed");
        Alert.alert("Success", "Detailed transcription completed!");
        setSelectedTranscription({ text: result.text || JSON.stringify(result), type: "detailed", data: result });
      } else if (type === "medical") {
        // Extract medical information
        result = await transcribeAndExtractMedicalInfo(recordingUri, {
          language: selectedLanguage,
        });
        await saveTranscription(recordingUri, result.transcription, "medical");
        Alert.alert("Success", "Medical transcription and extraction completed!");
        setSelectedTranscription({ text: result.transcription, type: "medical", data: result.medicalInfo });
      } else {
        // Simple transcription
        result = await transcribeAudio(recordingUri, {
          language: selectedLanguage,
        });
        await saveTranscription(recordingUri, result, "simple");
        Alert.alert("Success", "Transcription completed!");
        setSelectedTranscription({ text: result, type: "simple" });
      }
      
      setShowTranscriptionModal(true);
    } catch (error) {
      console.error("Transcription error:", error);
      Alert.alert("Error", `Failed to transcribe: ${error.message}`);
    } finally {
      setTranscribingIndex(null);
    }
  };

  const showTranscriptionTypeMenu = (recordingUri, index) => {
    // Auto-detect language and use detailed transcription directly
    setSelectedLanguage('auto');
    handleTranscribe(recordingUri, index, "detailed");
  };

  return (
    <SafeAreaView style={styles.safeContainer}>
      <View style={styles.container}>
        {/* Main Recording Interface */}
        <View style={styles.recordingInterface}>
          {/* Recording Controls */}
          <View style={styles.controlsContainer}>
            {!isRecording ? (
              <TouchableOpacity style={styles.startButton} onPress={startRecording}>
                <LinearGradient
                  colors={[colors.primary, colors.accent]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.startButtonGradient}
                >
                  <Ionicons name="mic" size={32} color={colors.white} />
                  <Text style={styles.startButtonText}>Start Recording</Text>
                </LinearGradient>
              </TouchableOpacity>
            ) : (
              <View style={styles.recordingControls}>
                {/* Recording Info */}
                <View style={styles.recordingInfo}>
                  <View style={styles.recordingIndicator}>
                    <View style={styles.recordingDot} />
                    <Text style={styles.recordingText}>
                      {isPaused ? "Paused" : "Recording..."}
                    </Text>
                  </View>
                  <Text style={styles.recordingTime}>{formatTime(recordingDuration)}</Text>
                </View>

                {/* Control Buttons */}
                <View style={styles.controlButtons}>
                  {isPaused ? (
                    <TouchableOpacity
                      style={[styles.controlButton, styles.resumeButton]}
                      onPress={resumeRecording}
                    >
                      <Ionicons name="play-circle" size={36} color={colors.primary} />
                      <Text style={styles.controlButtonText}>Resume</Text>
                    </TouchableOpacity>
                  ) : (
                    <TouchableOpacity
                      style={[styles.controlButton, styles.pauseButton]}
                      onPress={pauseRecording}
                    >
                      <Ionicons name="pause-circle" size={36} color="#FF9500" />
                      <Text style={styles.controlButtonText}>Pause</Text>
                    </TouchableOpacity>
                  )}

                  <TouchableOpacity
                    style={[styles.controlButton, styles.stopButton]}
                    onPress={stopRecording}
                  >
                    <Ionicons name="stop-circle" size={36} color="#FF3B30" />
                    <Text style={styles.controlButtonText}>Stop</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}
          </View>
        </View>

        {/* Saved Recordings */}
        <View style={styles.recordingsSection}>
          <Text style={styles.sectionTitle}>Saved Recordings</Text>
          {recordings.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="mic-outline" size={32} color={colors.textLight} />
              <Text style={styles.emptyText}>No recordings yet</Text>
            </View>
          ) : (
            <ScrollView 
              style={styles.recordingsList}
              contentContainerStyle={styles.recordingsListContent}
              showsVerticalScrollIndicator={true}
            >
              {recordings.slice(0, 3).map((rec, index) => (
              <View key={index} style={styles.recordingCard}>
                <View style={styles.recordingCardHeader}>
                  <View style={styles.recordingCardInfo}>
                    <Ionicons name="mic" size={20} color={colors.primary} style={{ marginRight: 10 }} />
                    <View style={styles.recordingCardText}>
                      <Text style={styles.recordingCardDate}>
                        {rec.date} • {rec.time}
                      </Text>
                      <Text style={styles.recordingCardDuration}>
                        Duration: {formatTime(rec.duration)}
                      </Text>
                    </View>
                  </View>
                  <TouchableOpacity
                    onPress={() => deleteRecording(index)}
                    style={styles.deleteButton}
                  >
                    <Ionicons name="trash-outline" size={20} color="#FF3B30" />
                  </TouchableOpacity>
                </View>
                <View style={styles.recordingCardActions}>
                  {playingIndex === index ? (
                    <TouchableOpacity
                      style={styles.playButton}
                      onPress={stopPlaying}
                    >
                      <Ionicons name="pause-circle" size={24} color={colors.primary} style={{ marginRight: 8 }} />
                      <Text style={styles.playButtonText}>Pause</Text>
                    </TouchableOpacity>
                  ) : (
                    <TouchableOpacity
                      style={styles.playButton}
                      onPress={() => playRecording(rec.uri, index)}
                    >
                      <Ionicons name="play-circle" size={24} color={colors.primary} style={{ marginRight: 8 }} />
                      <Text style={styles.playButtonText}>Play</Text>
                    </TouchableOpacity>
                  )}
                  
                  {transcribingIndex === index ? (
                    <TouchableOpacity style={styles.transcribeButton} disabled>
                      <ActivityIndicator size="small" color={colors.primary} />
                      <Text style={styles.transcribeButtonText}>Transcribing...</Text>
                    </TouchableOpacity>
                  ) : (
                    <>
                      <TouchableOpacity
                        style={styles.transcribeButton}
                        onPress={() => showTranscriptionTypeMenu(rec.uri, index)}
                      >
                        <Ionicons name="text-outline" size={20} color={colors.primary} style={{ marginRight: 6 }} />
                        <Text style={styles.transcribeButtonText}>
                          {transcriptions[rec.uri] ? "Re-Transcribe" : "Transcribe"}
                        </Text>
                      </TouchableOpacity>
                      
                      {transcriptions[rec.uri] && (
                        <TouchableOpacity
                          style={[styles.transcribeButton, styles.viewButton]}
                          onPress={() => {
                            setSelectedTranscription({ text: transcriptions[rec.uri].text, type: transcriptions[rec.uri].type });
                            setShowTranscriptionModal(true);
                          }}
                        >
                          <Ionicons name="document-text-outline" size={20} color="#4CAF50" style={{ marginRight: 6 }} />
                          <Text style={[styles.transcribeButtonText, { color: "#4CAF50" }]}>View</Text>
                        </TouchableOpacity>
                      )}
                    </>
                  )}
                </View>
              </View>
              ))}
            </ScrollView>
          )}
        </View>

        {/* Language Selection Modal */}
        <Modal
          visible={showLanguageSelector}
          animationType="fade"
          transparent={true}
          onRequestClose={() => setShowLanguageSelector(false)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.optionsModal}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Select Language</Text>
                <TouchableOpacity onPress={() => setShowLanguageSelector(false)}>
                  <Ionicons name="close" size={24} color={colors.textDark} />
                </TouchableOpacity>
              </View>
              
              <View style={styles.optionsList}>
                <TouchableOpacity
                  style={[styles.optionItem, selectedLanguage === 'auto' && styles.optionItemSelected]}
                  onPress={() => {
                    setSelectedLanguage('auto');
                    setShowLanguageSelector(false);
                    setShowTranscriptionOptions(true);
                  }}
                >
                  <Ionicons name="globe" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>Auto-detect (Urdu/English)</Text>
                    <Text style={styles.optionDescription}>Best for mixed language recordings</Text>
                  </View>
                  {selectedLanguage === 'auto' && <Ionicons name="checkmark-circle" size={24} color={colors.primary} />}
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={[styles.optionItem, selectedLanguage === 'en' && styles.optionItemSelected]}
                  onPress={() => {
                    setSelectedLanguage('en');
                    setShowLanguageSelector(false);
                    setShowTranscriptionOptions(true);
                  }}
                >
                  <Ionicons name="language" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>English Only</Text>
                    <Text style={styles.optionDescription}>For English consultations</Text>
                  </View>
                  {selectedLanguage === 'en' && <Ionicons name="checkmark-circle" size={24} color={colors.primary} />}
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={[styles.optionItem, selectedLanguage === 'ur' && styles.optionItemSelected]}
                  onPress={() => {
                    setSelectedLanguage('ur');
                    setShowLanguageSelector(false);
                    setShowTranscriptionOptions(true);
                  }}
                >
                  <Ionicons name="book" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>Urdu Only</Text>
                    <Text style={styles.optionDescription}>For Urdu consultations</Text>
                  </View>
                  {selectedLanguage === 'ur' && <Ionicons name="checkmark-circle" size={24} color={colors.primary} />}
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

        {/* Transcription Type Selection Modal */}
        <Modal
          visible={showTranscriptionOptions}
          animationType="fade"
          transparent={true}
          onRequestClose={() => setShowTranscriptionOptions(false)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.optionsModal}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Select Transcription Type</Text>
                <TouchableOpacity onPress={() => setShowTranscriptionOptions(false)}>
                  <Ionicons name="close" size={24} color={colors.textDark} />
                </TouchableOpacity>
              </View>
              
              <View style={styles.languageIndicator}>
                <Ionicons name="language" size={16} color={colors.textLight} />
                <Text style={styles.languageIndicatorText}>
                  Language: {selectedLanguage === 'auto' ? 'Auto-detect (Urdu/English)' : selectedLanguage === 'ur' ? 'Urdu' : 'English'}
                </Text>
                <TouchableOpacity onPress={() => { setShowTranscriptionOptions(false); setShowLanguageSelector(true); }}>
                  <Text style={styles.changeLanguageText}>Change</Text>
                </TouchableOpacity>
              </View>
              
              <View style={styles.optionsList}>
                <TouchableOpacity
                  style={styles.optionItem}
                  onPress={() => {
                    if (selectedRecordingForTranscription) {
                      handleTranscribe(selectedRecordingForTranscription.uri, selectedRecordingForTranscription.index, "simple");
                    }
                  }}
                >
                  <Ionicons name="document-text" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>Simple Transcription</Text>
                    <Text style={styles.optionDescription}>Quick text transcription</Text>
                  </View>
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={styles.optionItem}
                  onPress={() => {
                    if (selectedRecordingForTranscription) {
                      handleTranscribe(selectedRecordingForTranscription.uri, selectedRecordingForTranscription.index, "detailed");
                    }
                  }}
                >
                  <Ionicons name="time" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>Detailed Transcription</Text>
                    <Text style={styles.optionDescription}>With timestamps and segments</Text>
                  </View>
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={styles.optionItem}
                  onPress={() => {
                    if (selectedRecordingForTranscription) {
                      handleTranscribe(selectedRecordingForTranscription.uri, selectedRecordingForTranscription.index, "medical");
                    }
                  }}
                >
                  <Ionicons name="medical" size={24} color={colors.primary} />
                  <View style={styles.optionContent}>
                    <Text style={styles.optionTitle}>Medical Extraction</Text>
                    <Text style={styles.optionDescription}>Transcribe + Extract medical info</Text>
                  </View>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

        {/* Transcription Modal */}
        <Modal
          visible={showTranscriptionModal}
          animationType="slide"
          transparent={true}
          onRequestClose={() => setShowTranscriptionModal(false)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.transcriptionModal}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Transcription</Text>
                <TouchableOpacity onPress={() => setShowTranscriptionModal(false)}>
                  <Ionicons name="close" size={24} color={colors.textDark} />
                </TouchableOpacity>
              </View>
              
              <ScrollView style={styles.transcriptionContent} showsVerticalScrollIndicator={true}>
                {selectedTranscription?.type === "medical" && selectedTranscription?.data && (
                  <View style={styles.medicalInfoSection}>
                    <Text style={styles.medicalInfoTitle}>📋 Extracted Medical Information</Text>
                    <Text style={styles.medicalInfoText}>
                      {JSON.stringify(selectedTranscription.data, null, 2)}
                    </Text>
                  </View>
                )}
                
                <View style={styles.transcriptionTextSection}>
                  <Text style={styles.transcriptionLabel}>Transcribed Text:</Text>
                  <Text style={styles.transcriptionText}>
                    {selectedTranscription?.text || "No transcription available"}
                  </Text>
                </View>
              </ScrollView>
              
              <View style={styles.modalActions}>
                <TouchableOpacity
                  style={styles.modalActionButton}
                  onPress={() => setShowTranscriptionModal(false)}
                >
                  <Text style={styles.modalActionButtonText}>Close</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      </View>
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
  },
  header: {
    padding: 15,
    paddingTop: 10,
    paddingBottom: 10,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: "700",
    color: colors.primary,
    marginBottom: 5,
  },
  headerSubtitle: {
    fontSize: 14,
    color: colors.textLight,
  },
  recordingInterface: {
    paddingHorizontal: 20,
    paddingTop: 30,
    marginBottom: 15,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 200,
  },
  controlsContainer: {
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  startButton: {
    borderRadius: 20,
    overflow: "hidden",
    elevation: 5,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  startButtonGradient: {
    paddingVertical: 15,
    paddingHorizontal: 25,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
  },
  startButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "700",
    marginLeft: 8,
  },
  recordingControls: {
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 15,
    elevation: 5,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  recordingInfo: {
    alignItems: "center",
    marginBottom: 15,
  },
  recordingIndicator: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 10,
  },
  recordingDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: "#FF3B30",
    marginRight: 8,
  },
  recordingText: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.textDark,
  },
  recordingTime: {
    fontSize: 28,
    fontWeight: "700",
    color: colors.primary,
  },
  controlButtons: {
    flexDirection: "row",
    justifyContent: "center",
  },
  controlButton: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 10,
    paddingHorizontal: 15,
    marginHorizontal: 10,
  },
  pauseButton: {
    // Styles for pause button
  },
  resumeButton: {
    // Styles for resume button
  },
  stopButton: {
    // Styles for stop button
  },
  controlButtonText: {
    fontSize: 12,
    fontWeight: "600",
    color: colors.textDark,
    marginTop: 4,
  },
  recordingsSection: {
    paddingHorizontal: 20,
    flex: 1,
    maxHeight: 200,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "700",
    color: colors.textDark,
    marginBottom: 10,
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 20,
  },
  emptyText: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.textDark,
    marginTop: 8,
  },
  recordingsList: {
    maxHeight: 150,
  },
  recordingsListContent: {
    paddingBottom: 5,
  },
  recordingCard: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  recordingCardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
  },
  recordingCardInfo: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  recordingCardText: {
    flex: 1,
  },
  recordingCardDate: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 2,
  },
  recordingCardDuration: {
    fontSize: 12,
    color: colors.textLight,
  },
  deleteButton: {
    padding: 5,
  },
  recordingCardActions: {
    flexDirection: "row",
    justifyContent: "flex-start",
  },
  playButton: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  playButtonText: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.primary,
  },
  transcribeButton: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: "#E3F2FD",
    borderRadius: 8,
    marginLeft: 8,
  },
  transcribeButtonText: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.primary,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "center",
  },
  transcriptionModal: {
    backgroundColor: colors.white,
    borderRadius: 20,
    width: "90%",
    maxHeight: "80%",
    padding: 20,
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 15,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: "#E0E0E0",
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: "700",
    color: colors.textDark,
  },
  transcriptionContent: {
    maxHeight: 400,
    marginBottom: 15,
  },
  transcriptionTextSection: {
    marginTop: 10,
  },
  transcriptionLabel: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 10,
  },
  transcriptionText: {
    fontSize: 14,
    color: colors.textDark,
    lineHeight: 22,
    backgroundColor: "#F5F5F5",
    padding: 15,
    borderRadius: 10,
  },
  medicalInfoSection: {
    marginBottom: 20,
    padding: 15,
    backgroundColor: "#E8F5E9",
    borderRadius: 10,
  },
  medicalInfoTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: "#2E7D32",
    marginBottom: 10,
  },
  medicalInfoText: {
    fontSize: 12,
    color: colors.textDark,
    fontFamily: "monospace",
  },
  modalActions: {
    flexDirection: "row",
    justifyContent: "flex-end",
  },
  modalActionButton: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    backgroundColor: colors.primary,
    borderRadius: 8,
  },
  modalActionButtonText: {
    color: colors.white,
    fontWeight: "600",
    fontSize: 16,
  },
  viewButton: {
    backgroundColor: "#E8F5E9",
  },
  optionsModal: {
    backgroundColor: colors.white,
    borderRadius: 20,
    width: "85%",
    maxWidth: 400,
    padding: 20,
  },
  optionsList: {
    marginTop: 10,
  },
  optionItem: {
    flexDirection: "row",
    alignItems: "center",
    padding: 15,
    borderRadius: 12,
    backgroundColor: "#F5F5F5",
    marginBottom: 12,
    borderWidth: 1,
    borderColor: "#E0E0E0",
  },
  optionContent: {
    marginLeft: 15,
    flex: 1,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.textDark,
    marginBottom: 4,
  },
  optionDescription: {
    fontSize: 12,
    color: colors.textLight,
  },
  optionItemSelected: {
    backgroundColor: "#E3F2FD",
    borderColor: colors.primary,
    borderWidth: 2,
  },
  languageIndicator: {
    flexDirection: "row",
    alignItems: "center",
    padding: 12,
    backgroundColor: "#F5F5F5",
    borderRadius: 8,
    marginBottom: 15,
    justifyContent: "space-between",
  },
  languageIndicatorText: {
    fontSize: 14,
    color: colors.textDark,
    marginLeft: 8,
    flex: 1,
  },
  changeLanguageText: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: "600",
  },
});
