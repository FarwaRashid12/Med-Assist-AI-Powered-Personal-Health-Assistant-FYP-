// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getAnalytics } from "firebase/analytics";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAhagnW2deM_SrdFPWMdRj5p854zz9lPoc",
  authDomain: "med-assist-fyp.firebaseapp.com",
  projectId: "med-assist-fyp",
  storageBucket: "med-assist-fyp.firebasestorage.app",
  messagingSenderId: "441564237705",
  appId: "1:441564237705:web:479a28b0febbb9980ddb58",
  measurementId: "G-C2XYD1K7CT"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication and export it
export const auth = getAuth(app);

// (Optional) Initialize Analytics if running in browser
export const analytics = getAnalytics(app);

