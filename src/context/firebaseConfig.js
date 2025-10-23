import { initializeApp } from "firebase/app";
import { getAuth, RecaptchaVerifier, signInWithPhoneNumber } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAhagnW2deM_SrdFPWMdRj5p854zz9lPoc",
  authDomain: "med-assist-fyp.firebaseapp.com",
  projectId: "med-assist-fyp",
  storageBucket: "med-assist-fyp.firebasestorage.app",
  messagingSenderId: "441564237705",
  appId: "1:441564237705:web:479a28b0febbb9980ddb58",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { auth, RecaptchaVerifier, signInWithPhoneNumber };
