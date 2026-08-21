'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  Patient, 
  Medicine, 
  NotificationItem, 
  AdherenceLog,
  DoseRecord,
  Prescription,
  INITIAL_PATIENT,
  INITIAL_MEDICINES,
  INITIAL_NOTIFICATIONS,
  INITIAL_ADHERENCE_LOGS,
  INITIAL_PRESCRIPTIONS
} from '../services/mockData';
import { isFirebaseConfigured, auth as fbAuth, db as fbDb } from '../services/firebase';
import { 
  doc, 
  setDoc, 
  getDoc, 
  collection, 
  getDocs, 
  addDoc, 
  updateDoc 
} from 'firebase/firestore';

interface AppContextType {
  theme: 'light' | 'dark';
  setTheme: (theme: 'light' | 'dark') => void;
  user: any | null;
  userRole: 'patient' | 'caregiver' | 'admin' | null;
  patient: Patient | null;
  deviceId: string | null;
  setDeviceId: (id: string | null) => void;
  medicines: Medicine[];
  notifications: NotificationItem[];
  adherenceLogs: AdherenceLog[];
  doseRecords: DoseRecord[];
  patients: Patient[];
  prescriptions: Prescription[];
  login: (email: string, role: 'patient' | 'caregiver' | 'admin') => Promise<void>;
  logout: () => void;
  registerPatient: (patientData: Patient) => Promise<void>;
  addMedicine: (medicine: Omit<Medicine, 'id' | 'remainingTablets' | 'estimatedRefillDate' | 'lowStockWarning'>) => Promise<void>;
  toggleDoseReminder: (medicineId: string, dose: 'morning' | 'afternoon' | 'night', checked: boolean) => Promise<void>;
  clearNotifications: () => void;
  generateDoseRecordsForDay: (patientId: string, dateStr: string) => void;
  takeWebPill: (doseRecordId: string) => Promise<void>;
  addPatient: (patientData: Patient) => Promise<void>;
  updatePatient: (patientId: string, patientData: Patient) => Promise<void>;
  deletePatient: (patientId: string) => Promise<void>;
  addPrescription: (data: any) => Promise<void>;
  deletePrescription: (id: string) => Promise<void>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setThemeState] = useState<'light' | 'dark'>(() => {
    if (typeof window !== 'undefined') {
      const savedTheme = localStorage.getItem('smartmed-theme') as 'light' | 'dark';
      return savedTheme || 'light';
    }
    return 'light';
  });
  const [user, setUser] = useState<any | null>(null);
  const [userRole, setUserRole] = useState<'patient' | 'caregiver' | 'admin' | null>(null);
  const [patient, setPatient] = useState<Patient | null>(null);
  const [deviceId, setDeviceIdState] = useState<string | null>(null);
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [adherenceLogs, setAdherenceLogs] = useState<AdherenceLog[]>([]);
  const [doseRecords, setDoseRecords] = useState<DoseRecord[]>([]);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [prescriptions, setPrescriptions] = useState<Prescription[]>([]);

  // Load Theme classes
  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark');
  }, [theme]);

  const setTheme = (newTheme: 'light' | 'dark') => {
    setThemeState(newTheme);
    localStorage.setItem('smartmed-theme', newTheme);
    document.documentElement.classList.toggle('dark', newTheme === 'dark');
  };

  // Load initial app data
  useEffect(() => {
    const initData = async () => {
      // Clear old dummy storage on first load if we haven't migrated
      const migrated = typeof window !== 'undefined' && localStorage.getItem('sm-migrated-empty') === 'true';
      if (!migrated && typeof window !== 'undefined') {
        localStorage.removeItem('sm-patient');
        localStorage.removeItem('sm-medicines');
        localStorage.removeItem('sm-notifications');
        localStorage.removeItem('sm-logs');
        localStorage.removeItem('sm-dose-records');
        localStorage.removeItem('sm-user');
        localStorage.removeItem('sm-role');
        localStorage.removeItem('sm-patients');
        localStorage.removeItem('sm-prescriptions');
        localStorage.setItem('sm-migrated-empty', 'true');
      }

      // 1. If Firebase is active, try to fetch from Firestore
      if (isFirebaseConfigured && fbAuth?.currentUser) {
        try {
          const email = fbAuth.currentUser.email;
          // Set user state
          setUser({ email });
          
          // Fetch Role from profile
          const userDoc = await getDoc(doc(fbDb, 'users', email!));
          const role = userDoc.exists() ? userDoc.data().role : 'patient';
          setUserRole(role);

          // Fetch Patient details
          const patientDoc = await getDoc(doc(fbDb, 'patients', email!));
          if (patientDoc.exists()) {
            const patData = patientDoc.data() as Patient;
            setPatient(patData);
            setDeviceIdState(patData.deviceId);
            
            // Fetch medicines
            const medsCol = await getDocs(collection(fbDb, 'patients', email!, 'medicines'));
            const medsList: Medicine[] = [];
            medsCol.forEach(doc => medsList.push({ id: doc.id, ...doc.data() } as Medicine));
            setMedicines(medsList);

            // Fetch prescriptions
            const presCol = await getDocs(collection(fbDb, 'patients', email!, 'prescriptions'));
            const presList: Prescription[] = [];
            presCol.forEach(doc => presList.push({ id: doc.id, ...doc.data() } as Prescription));
            setPrescriptions(presList);
          }
          return;
        } catch (e) {
          console.error("Error loading Firestore details, falling back:", e);
        }
      }

      // 2. LocalStorage Fallback Layer
      const storedUser = localStorage.getItem('sm-user');
      const storedRole = localStorage.getItem('sm-role') as any;
      const storedPatient = localStorage.getItem('sm-patient');
      const storedMeds = localStorage.getItem('sm-medicines');
      const storedNotifs = localStorage.getItem('sm-notifications');
      const storedLogs = localStorage.getItem('sm-logs');
      const storedDoses = localStorage.getItem('sm-dose-records');
      const storedPatients = localStorage.getItem('sm-patients');
      const storedPrescriptions = localStorage.getItem('sm-prescriptions');

      if (storedUser) {
        setUser(JSON.parse(storedUser));
        setUserRole(storedRole || 'patient');
      }
      
      if (storedPatient) {
        const pat = JSON.parse(storedPatient);
        setPatient(pat);
        setDeviceIdState(pat.deviceId);
      } else if (storedUser) {
        // Logged in but no patient registered, load preset
        setPatient(INITIAL_PATIENT);
        setDeviceIdState(INITIAL_PATIENT.deviceId);
      }

      if (storedMeds) {
        setMedicines(JSON.parse(storedMeds));
      } else {
        setMedicines(INITIAL_MEDICINES);
      }

      if (storedNotifs) {
        setNotifications(JSON.parse(storedNotifs));
      } else {
        setNotifications(INITIAL_NOTIFICATIONS);
      }

      if (storedLogs) {
        setAdherenceLogs(JSON.parse(storedLogs));
      } else {
        setAdherenceLogs(INITIAL_ADHERENCE_LOGS);
      }

      if (storedDoses) {
        setDoseRecords(JSON.parse(storedDoses));
      } else {
        setDoseRecords([]);
      }

      if (storedPatients) {
        setPatients(JSON.parse(storedPatients));
      } else {
        setPatients([]);
      }

      if (storedPrescriptions) {
        setPrescriptions(JSON.parse(storedPrescriptions));
      } else {
        setPrescriptions(INITIAL_PRESCRIPTIONS);
      }
    };

    initData();
  }, [user]);

  // Synchronize LocalStorage state when changed (fallback mode helper)
  const saveStateToLocal = (
    updatedMeds?: Medicine[], 
    updatedNotifs?: NotificationItem[], 
    updatedLogs?: AdherenceLog[],
    updatedDoses?: DoseRecord[],
    updatedPrescriptions?: Prescription[]
  ) => {
    if (updatedMeds) localStorage.setItem('sm-medicines', JSON.stringify(updatedMeds));
    if (updatedNotifs) localStorage.setItem('sm-notifications', JSON.stringify(updatedNotifs));
    if (updatedLogs) localStorage.setItem('sm-logs', JSON.stringify(updatedLogs));
    if (updatedDoses) localStorage.setItem('sm-dose-records', JSON.stringify(updatedDoses));
    if (updatedPrescriptions) localStorage.setItem('sm-prescriptions', JSON.stringify(updatedPrescriptions));
  };

  const login = async (email: string, role: 'patient' | 'caregiver' | 'admin') => {
    const userProfile = { email, displayName: email.split('@')[0] };
    
    if (isFirebaseConfigured) {
      // Firebase auth login simulation or writing user
      try {
        await setDoc(doc(fbDb, 'users', email), { email, role });
      } catch (e) {
        console.warn("Firestore user sync error:", e);
      }
    }

    setUser(userProfile);
    setUserRole(role);
    localStorage.setItem('sm-user', JSON.stringify(userProfile));
    localStorage.setItem('sm-role', role);

    // If patient and not yet in local storage, set default profile
    if (role === 'patient') {
      const storedPatient = localStorage.getItem('sm-patient');
      if (!storedPatient) {
        setPatient(INITIAL_PATIENT);
        setDeviceIdState(INITIAL_PATIENT.deviceId);
        localStorage.setItem('sm-patient', JSON.stringify(INITIAL_PATIENT));
      }
    }
  };

  const logout = () => {
    setUser(null);
    setUserRole(null);
    setPatient(null);
    setDeviceIdState(null);
    localStorage.removeItem('sm-user');
    localStorage.removeItem('sm-role');
    localStorage.removeItem('sm-patient');
  };

  const setDeviceId = (id: string | null) => {
    setDeviceIdState(id);
    if (id) {
      localStorage.setItem('sm-scanned-device', id);
    } else {
      localStorage.removeItem('sm-scanned-device');
    }
  };

  const registerPatient = async (patientData: Patient) => {
    if (isFirebaseConfigured && user) {
      try {
        await setDoc(doc(fbDb, 'patients', user.email), patientData);
        await setDoc(doc(fbDb, 'devices', patientData.deviceId), { 
          registered: true, 
          patientEmail: user.email 
        });
      } catch (e) {
        console.error("Firestore register patient error:", e);
      }
    }

    setPatient(patientData);
    setDeviceIdState(patientData.deviceId);
    localStorage.setItem('sm-patient', JSON.stringify(patientData));
    
    // Seed initial medications if list is empty
    if (medicines.length === 0) {
      setMedicines(INITIAL_MEDICINES);
      saveStateToLocal(INITIAL_MEDICINES);
    }
  };

  const addMedicine = async (medData: Omit<Medicine, 'id' | 'remainingTablets' | 'estimatedRefillDate' | 'lowStockWarning'>) => {
    const id = "med-" + Date.now();
    
    // Auto-calculate values
    const remainingTablets = medData.quantity;
    const dailyDoses = (medData.morning ? 1 : 0) + (medData.afternoon ? 1 : 0) + (medData.night ? 1 : 0);
    const daysRemaining = dailyDoses > 0 ? Math.ceil(remainingTablets / dailyDoses) : 30;
    
    const start = new Date(medData.startDate);
    const refillDate = new Date(start.getTime() + daysRemaining * 24 * 60 * 60 * 1000);
    const estimatedRefillDate = refillDate.toISOString().split('T')[0];
    
    const lowStockWarning = remainingTablets < 10;

    const newMed: Medicine = {
      ...medData,
      id,
      remainingTablets,
      estimatedRefillDate,
      lowStockWarning
    };

    const updatedMeds = [newMed, ...medicines];
    setMedicines(updatedMeds);
    saveStateToLocal(updatedMeds);

    if (isFirebaseConfigured && user) {
      try {
        await setDoc(doc(fbDb, 'patients', user.email, 'medicines', id), newMed);
      } catch (e) {
        console.error("Firestore add medicine error:", e);
      }
    }

    // Add alert notification
    const newNotif: NotificationItem = {
      id: "notif-" + Date.now(),
      type: "reminder",
      message: `New medication "${medData.name} ${medData.dosage}" has been configured successfully.`,
      timestamp: "Just now",
      read: false
    };
    const updatedNotifs = [newNotif, ...notifications];
    setNotifications(updatedNotifs);
    saveStateToLocal(undefined, updatedNotifs);
  };

  const toggleDoseReminder = async (medicineId: string, dose: 'morning' | 'afternoon' | 'night', checked: boolean) => {
    // 1. Toggle status in local UI state
    const targetMed = medicines.find(m => m.id === medicineId);
    if (!targetMed) return;

    // Recalculate stock
    let updatedRemaining = targetMed.remainingTablets;
    if (checked) {
      updatedRemaining = Math.max(0, updatedRemaining - 1);
    } else {
      updatedRemaining = Math.min(targetMed.quantity, updatedRemaining + 1);
    }

    const lowStock = updatedRemaining < 10;
    
    const updatedMeds = medicines.map(m => {
      if (m.id === medicineId) {
        return {
          ...m,
          remainingTablets: updatedRemaining,
          lowStockWarning: lowStock
        };
      }
      return m;
    });

    setMedicines(updatedMeds);
    saveStateToLocal(updatedMeds);

    // 2. Add adherence log entry
    const logTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const logEntry: AdherenceLog = {
      id: "log-" + Date.now(),
      time: `Today, ${logTime}`,
      medicineName: targetMed.name,
      status: checked ? "taken" : "missed",
      dose
    };

    const updatedLogs = [logEntry, ...adherenceLogs];
    setAdherenceLogs(updatedLogs);
    saveStateToLocal(undefined, undefined, updatedLogs);

    // 3. Create a warning alert if low stock is triggered
    if (checked && updatedRemaining === 9) {
      const lowStockAlert: NotificationItem = {
        id: "notif-low-" + Date.now(),
        type: "lowStock",
        message: `Low Stock warning: ${targetMed.name} has only 9 tablets remaining. Estimated refill needed by ${targetMed.estimatedRefillDate}.`,
        timestamp: "Just now",
        read: false
      };
      const updatedNotifs = [lowStockAlert, ...notifications];
      setNotifications(updatedNotifs);
      saveStateToLocal(undefined, updatedNotifs);
    }

    if (isFirebaseConfigured && user) {
      try {
        await updateDoc(doc(fbDb, 'patients', user.email, 'medicines', medicineId), {
          remainingTablets: updatedRemaining,
          lowStockWarning: lowStock
        });
        await addDoc(collection(fbDb, 'patients', user.email, 'adherenceLogs'), logEntry);
      } catch (e) {
        console.error("Firestore update dose error:", e);
      }
    }
  };

  const generateDoseRecordsForDay = (patientId: string, dateStr: string) => {
    const alreadyExist = doseRecords.some(r => r.patientId === patientId && r.scheduledDate === dateStr);
    if (alreadyExist) return;

    const newDoses: DoseRecord[] = [];

    medicines.forEach(med => {
      if (med.id) {
        const scheduledPills = med.pillsPerDose || 1;
        
        if (med.morning) {
          newDoses.push({
            id: `dose-m-${med.id}-${dateStr}`,
            medicineId: med.id,
            medicineName: med.name,
            dosage: med.dosage,
            patientId: patientId,
            scheduledDate: dateStr,
            scheduledTime: '08:00',
            dosePeriod: 'morning',
            scheduledPills,
            takenPills: 0,
            remainingPills: scheduledPills,
            status: 'Pending'
          });
        }
        if (med.afternoon) {
          newDoses.push({
            id: `dose-a-${med.id}-${dateStr}`,
            medicineId: med.id,
            medicineName: med.name,
            dosage: med.dosage,
            patientId: patientId,
            scheduledDate: dateStr,
            scheduledTime: '13:00',
            dosePeriod: 'afternoon',
            scheduledPills,
            takenPills: 0,
            remainingPills: scheduledPills,
            status: 'Pending'
          });
        }
        if (med.night) {
          newDoses.push({
            id: `dose-n-${med.id}-${dateStr}`,
            medicineId: med.id,
            medicineName: med.name,
            dosage: med.dosage,
            patientId: patientId,
            scheduledDate: dateStr,
            scheduledTime: '20:00',
            dosePeriod: 'night',
            scheduledPills,
            takenPills: 0,
            remainingPills: scheduledPills,
            status: 'Pending'
          });
        }
      }
    });

    if (newDoses.length > 0) {
      const updatedDoses = [...doseRecords, ...newDoses];
      setDoseRecords(updatedDoses);
      localStorage.setItem('sm-dose-records', JSON.stringify(updatedDoses));
    }
  };

  const takeWebPill = async (doseRecordId: string) => {
    const record = doseRecords.find(r => r.id === doseRecordId);
    if (!record) return;

    if (record.takenPills >= record.scheduledPills) {
      alert("Scheduled dose already completed. No additional pills are scheduled for this dose.");
      return;
    }

    const updatedTaken = record.takenPills + 1;
    const remaining = record.scheduledPills - updatedTaken;
    const status: 'Completed' | 'Partially Taken' = updatedTaken === record.scheduledPills ? 'Completed' : 'Partially Taken';

    const updatedDoseRecords = doseRecords.map(r => {
      if (r.id === doseRecordId) {
        return {
          ...r,
          takenPills: updatedTaken,
          remainingPills: remaining,
          status
        };
      }
      return r;
    });

    setDoseRecords(updatedDoseRecords);
    localStorage.setItem('sm-dose-records', JSON.stringify(updatedDoseRecords));

    // Decrement stock in medicines
    const targetMed = medicines.find(m => m.id === record.medicineId);
    if (targetMed) {
      const updatedRemainingStock = Math.max(0, targetMed.remainingTablets - 1);
      const lowStock = updatedRemainingStock < 10;

      const updatedMeds = medicines.map(m => {
        if (m.id === record.medicineId) {
          return {
            ...m,
            remainingTablets: updatedRemainingStock,
            lowStockWarning: lowStock
          };
        }
        return m;
      });

      setMedicines(updatedMeds);
      saveStateToLocal(updatedMeds);

      // Create adherence log entry
      const logTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      const logEntry: AdherenceLog = {
        id: "log-" + Date.now(),
        time: `Today, ${logTime}`,
        medicineName: targetMed.name,
        status: status === 'Completed' ? 'taken' : 'late',
        dose: record.dosePeriod
      };

      const updatedLogs = [logEntry, ...adherenceLogs];
      setAdherenceLogs(updatedLogs);
      saveStateToLocal(undefined, undefined, updatedLogs);

      // Create notification warning if stock is low
      if (updatedRemainingStock === 9) {
        const lowStockAlert: NotificationItem = {
          id: "notif-low-" + Date.now(),
          type: "lowStock",
          message: `Low Stock warning: ${targetMed.name} has only 9 tablets remaining. Estimated refill needed by ${targetMed.estimatedRefillDate}.`,
          timestamp: "Just now",
          read: false
        };
        const updatedNotifs = [lowStockAlert, ...notifications];
        setNotifications(updatedNotifs);
        saveStateToLocal(undefined, updatedNotifs);
      }

      if (isFirebaseConfigured && fbAuth?.currentUser) {
        try {
          await updateDoc(doc(fbDb, 'patients', fbAuth.currentUser.email!, 'medicines', record.medicineId), {
            remainingTablets: updatedRemainingStock,
            lowStockWarning: lowStock
          });
          // Also sync dose records to firestore
          await setDoc(doc(fbDb, 'patients', fbAuth.currentUser.email!, 'doseRecords', doseRecordId), {
            takenPills: updatedTaken,
            remainingPills: remaining,
            status
          });
        } catch (e) {
          console.error("Firestore pill update error:", e);
        }
      }
    }
  };

  const clearNotifications = () => {
    const updatedNotifs = notifications.map(n => ({ ...n, read: true }));
    setNotifications(updatedNotifs);
    saveStateToLocal(undefined, updatedNotifs);
  };

  const addPatient = async (patientData: Patient) => {
    if (patients.some(p => p.id?.toLowerCase() === patientData.id?.toLowerCase())) {
      throw new Error('Patient ID must be unique.');
    }
    const updated = [...patients, patientData];
    setPatients(updated);
    localStorage.setItem('sm-patients', JSON.stringify(updated));
  };

  const updatePatient = async (patientId: string, patientData: Patient) => {
    const updated = patients.map(p => p.id === patientId ? patientData : p);
    setPatients(updated);
    localStorage.setItem('sm-patients', JSON.stringify(updated));
  };

  const deletePatient = async (patientId: string) => {
    const updated = patients.filter(p => p.id !== patientId);
    setPatients(updated);
    localStorage.setItem('sm-patients', JSON.stringify(updated));
  };

  const addPrescription = async (data: any) => {
    const id = 'pres-' + Date.now();
    const newPres: Prescription = {
      id,
      patientId: data.patientId,
      deviceId: data.deviceId || 'BOX-8800',
      uploadedBy: user?.email || 'caregiver',
      fileName: data.fileName,
      fileType: data.fileType,
      fileSize: data.fileSize,
      downloadURL: data.downloadURL || '#',
      uploadDate: data.uploadDate || new Date().toISOString().split('T')[0],
      createdAt: new Date().toISOString(),
      extractedMedicines: data.extractedMedicines
    };

    const updated = [newPres, ...prescriptions];
    setPrescriptions(updated);
    saveStateToLocal(undefined, undefined, undefined, undefined, updated);

    if (isFirebaseConfigured && user) {
      try {
        await setDoc(doc(fbDb, 'patients', user.email, 'prescriptions', id), newPres);
      } catch (e) {
        console.error("Firestore add prescription error:", e);
      }
    }
  };

  const deletePrescription = async (presId: string) => {
    const updated = prescriptions.filter(p => p.id !== presId);
    setPrescriptions(updated);
    saveStateToLocal(undefined, undefined, undefined, undefined, updated);
  };

  return (
    <AppContext.Provider value={{
      theme,
      setTheme,
      user,
      userRole,
      patient,
      deviceId,
      setDeviceId,
      medicines,
      notifications,
      adherenceLogs,
      doseRecords,
      patients,
      prescriptions,
      login,
      logout,
      registerPatient,
      addMedicine,
      toggleDoseReminder,
      clearNotifications,
      generateDoseRecordsForDay,
      takeWebPill,
      addPatient,
      updatePatient,
      deletePatient,
      addPrescription,
      deletePrescription
    }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
