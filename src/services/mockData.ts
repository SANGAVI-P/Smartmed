export interface Patient {
  id?: string;
  name: string;
  age: number;
  gender: string;
  phone: string;
  address: string;
  emergencyContact: string;
  caregiverName: string;
  caregiverPhone: string;
  medicalConditions: string;
  allergies: string;
  deviceId: string;
  caregiverEmail?: string;
}

export interface Medicine {
  id: string;
  name: string;
  dosage: string;
  morning: boolean;
  afternoon: boolean;
  night: boolean;
  beforeFood: boolean; // true = before, false = after
  startDate: string;
  endDate: string;
  quantity: number;
  remainingTablets: number;
  estimatedRefillDate: string;
  lowStockWarning: boolean;
  pillsPerDose: number;
}

export interface DoseRecord {
  id: string;
  medicineId: string;
  medicineName: string;
  dosage: string;
  patientId: string;
  scheduledDate: string; // YYYY-MM-DD
  scheduledTime: string; // HH:MM
  dosePeriod: 'morning' | 'afternoon' | 'night';
  scheduledPills: number;
  takenPills: number;
  remainingPills: number;
  status: 'Pending' | 'Partially Taken' | 'Completed' | 'Missed';
}

export interface NotificationItem {
  id: string;
  type: 'reminder' | 'lowStock' | 'missed' | 'emergency';
  message: string;
  timestamp: string;
  read: boolean;
}

export interface AdherenceLog {
  id: string;
  time: string;
  medicineName: string;
  status: 'taken' | 'missed' | 'late';
  dose: 'morning' | 'afternoon' | 'night';
}

export const INITIAL_PATIENT: Patient = {
  name: "",
  age: 0,
  gender: "",
  phone: "",
  address: "",
  emergencyContact: "",
  caregiverName: "",
  caregiverPhone: "",
  medicalConditions: "",
  allergies: "",
  deviceId: "",
};

export const INITIAL_MEDICINES: Medicine[] = [];

export const INITIAL_NOTIFICATIONS: NotificationItem[] = [];

export const INITIAL_ADHERENCE_LOGS: AdherenceLog[] = [];

export interface Prescription {
  id: string;
  patientId: string;
  deviceId: string;
  uploadedBy: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  downloadURL: string;
  uploadDate: string;
  createdAt: string;
  extractedMedicines?: any[];
}

export const INITIAL_PRESCRIPTIONS: Prescription[] = [];

