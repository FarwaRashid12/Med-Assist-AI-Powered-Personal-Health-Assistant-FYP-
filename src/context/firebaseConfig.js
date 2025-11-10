import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getDatabase } from "firebase/database";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyAhagnW2deM_SrdFPWMdRj5p854zz9lPoc",
  authDomain: "med-assist-fyp.firebaseapp.com",
  databaseURL: "https://med-assist-fyp-default-rtdb.firebaseio.com",
  projectId: "med-assist-fyp",
  storageBucket: "med-assist-fyp.firebasestorage.app",
  messagingSenderId: "441564237705",
  appId: "1:441564237705:web:479a28b0febbb9980ddb58",
  measurementId: "G-C2XYD1K7CT",
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getDatabase(app);
export const storage = getStorage(app);
