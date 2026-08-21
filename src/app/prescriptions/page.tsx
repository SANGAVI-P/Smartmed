'use client';

import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { Navbar } from '../../components/Navbar';
import { 
  FileText, 
  Sparkles, 
  Trash2, 
  UploadCloud, 
  CheckCircle2, 
  AlertCircle, 
  Eye, 
  X, 
  PlusCircle, 
  Loader2, 
  Calendar,
  Layers,
  Check,
  ChevronDown,
  Camera,
  RefreshCw,
  File,
  Settings
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Patient } from '../../services/mockData';
import { fuzzyMatchMedicine } from '../../services/fuzzyMatch';

interface DetectedMedicine {
  name: string;
  strength: string;
  dosage: string;
  duration: string;
  schedule: {
    morning: boolean;
    afternoon: boolean;
    night: boolean;
  };
  timing: 'before_food' | 'after_food';
  confidenceScore: number;
  isVerified: boolean;
}

function preprocessBase64Image(base64Url: string): Promise<string> {
  return new Promise((resolve) => {
    if (base64Url.startsWith('data:application/pdf')) {
      resolve(base64Url); // Can't preprocess PDF with canvas
      return;
    }
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        resolve(base64Url);
        return;
      }
      let width = img.width;
      let height = img.height;
      const maxDim = 1200;
      if (width > maxDim || height > maxDim) {
        if (width > height) {
          height = Math.round((height * maxDim) / width);
          width = maxDim;
        } else {
          width = Math.round((width * maxDim) / height);
          height = maxDim;
        }
      }
      canvas.width = width;
      canvas.height = height;
      ctx.drawImage(img, 0, 0, width, height);

      try {
        const imageData = ctx.getImageData(0, 0, width, height);
        const data = imageData.data;
        const contrast = 50; 
        const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
        const brightness = 15;

        for (let i = 0; i < data.length; i += 4) {
          const r = data[i];
          const g = data[i + 1];
          const b = data[i + 2];
          const gray = 0.299 * r + 0.587 * g + 0.114 * b;
          let newColor = factor * (gray - 128) + 128 + brightness;
          if (newColor < 0) newColor = 0;
          if (newColor > 255) newColor = 255;
          data[i] = newColor;
          data[i + 1] = newColor;
          data[i + 2] = newColor;
        }
        ctx.putImageData(imageData, 0, 0);
        resolve(canvas.toDataURL('image/jpeg', 0.85));
      } catch (e) {
        console.warn("Canvas pixel processing error:", e);
        resolve(base64Url);
      }
    };
    img.onerror = () => resolve(base64Url);
    img.src = base64Url;
  });
}


const getPresetSVG = (name: string) => {
  let title = "Prescription Rx";
  let medName = "Medication";
  let details = "Take as directed";
  let color = "#3b82f6";
  
  const nameLower = name.toLowerCase();
  if (nameLower.includes('lisinopril')) {
    title = "Cardiovascular Care";
    medName = "Lisinopril 10mg";
    details = "Take 1 tablet daily in the morning for hypertension.";
    color = "#3b82f6";
  } else if (nameLower.includes('metformin')) {
    title = "Endocrine Health Care";
    medName = "Metformin 500mg";
    details = "Take 1 tablet twice daily with morning and evening meals.";
    color = "#10b981";
  } else if (nameLower.includes('atorvastatin')) {
    title = "Lipid Clinic";
    medName = "Atorvastatin 20mg";
    details = "Take 1 tablet daily at bedtime.";
    color = "#f59e0b";
  } else if (nameLower.includes('eliquis')) {
    title = "Cardiology Division";
    medName = "Eliquis 5mg";
    details = "Take 1 tablet twice daily.";
    color = "#8b5cf6";
  } else if (nameLower.includes('unclear')) {
    title = "General Clinic";
    medName = "P...etamol 500mg";
    details = "T... 1 tab... pain [ILLEGIBLE]";
    color = "#ef4444";
  }

  const svg = `
    <svg width="400" height="300" xmlns="http://www.w3.org/2000/svg" style="background:#fff; font-family: sans-serif; border: 1px solid #e2e8f0;">
      <!-- Header Rx background -->
      <rect width="400" height="70" fill="${color}" />
      <text x="20" y="42" font-size="18" font-weight="bold" fill="#ffffff" font-family="sans-serif">SMARTMED HOSPITALS</text>
      <text x="340" y="48" font-size="24" font-weight="900" fill="#ffffff" opacity="0.3" font-family="sans-serif">Rx</text>
      
      <!-- Hospital Details -->
      <text x="20" y="100" font-size="11" font-weight="bold" fill="#64748b" font-family="sans-serif">DEPARTMENT: ${title.toUpperCase()}</text>
      <text x="20" y="118" font-size="10" fill="#94a3b8" font-family="sans-serif">DATE: ${new Date().toLocaleDateString()}</text>
      
      <line x1="20" y1="135" x2="380" y2="135" stroke="#cbd5e1" stroke-width="1" />
      
      <!-- Rx symbol and patient details -->
      <text x="20" y="175" font-size="28" font-weight="900" fill="${color}" font-family="sans-serif">℞</text>
      
      <text x="60" y="170" font-size="16" font-weight="bold" fill="#1e293b" font-family="sans-serif">${medName}</text>
      <text x="60" y="190" font-size="11" fill="#64748b" font-family="sans-serif">Disp: #30 • Refills: 3</text>
      
      <!-- Directions -->
      <text x="60" y="220" font-size="12" font-weight="bold" fill="#334155" font-family="sans-serif">Sig / Directions:</text>
      <text x="60" y="240" font-size="11" fill="#475569" font-family="sans-serif">${details}</text>
      
      <!-- Footer security code -->
      <rect y="270" width="400" height="30" fill="#f8fafc" />
      <text x="20" y="288" font-size="9" fill="#94a3b8" font-family="sans-serif">AUTHENTIC CLINICAL PORTAL DOCUMENT • VERIFIED BY SMARTMED OCR</text>
    </svg>
  `;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

export default function PrescriptionsPage() {
  const { 
    user, 
    userRole, 
    patient, 
    patients, 
    prescriptions,
    addPrescription,
    deletePrescription,
    addMedicine
  } = useApp();

  // Selected Patient filter for caregivers
  const [patientFilter, setPatientFilter] = useState('mock-patient');

  // File Upload & Camera State
  const [selectedFile, setSelectedFile] = useState<{
    name: string;
    type: string;
    size: number;
  } | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Custom webcam & drag-drop states
  const [dragActive, setDragActive] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [fileBase64, setFileBase64] = useState<string | null>(null);
  const [apiKey, setApiKey] = useState<string>('');
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [rawOcrText, setRawOcrText] = useState<string>('');
  const [showRawOcrText, setShowRawOcrText] = useState<boolean>(false);
  const [isOcrMocked, setIsOcrMocked] = useState<boolean>(false);

  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [cameraDevices, setCameraDevices] = useState<MediaDeviceInfo[]>([]);
  const [selectedCameraId, setSelectedCameraId] = useState<string>('');
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [cameraLoading, setCameraLoading] = useState(false);

  const videoRef = React.useRef<HTMLVideoElement>(null);
  const streamRef = React.useRef<MediaStream | null>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  // Scan simulation states
  const [isScanning, setIsScanning] = useState(false);
  const [scanProgress, setScanProgress] = useState(0);
  const [scanStatus, setScanStatus] = useState('');
  const [detectedMedicines, setDetectedMedicines] = useState<DetectedMedicine[] | null>(null);
  const [scanningCompleted, setScanningCompleted] = useState(false);

  // Sync animation dialog states
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncStep, setSyncStep] = useState(0);

  // Detail viewer overlay state
  const [viewingPrescription, setViewingPrescription] = useState<any | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedKey = localStorage.getItem('smartmed_gemini_api_key');
      if (savedKey) {
        setApiKey(savedKey);
      }
    }
  }, []);

  const handleSaveApiKey = (key: string) => {
    setApiKey(key);
    if (typeof window !== 'undefined') {
      localStorage.setItem('smartmed_gemini_api_key', key);
    }
  };

  // Webcam stream activation hook
  useEffect(() => {
    let activeStream: MediaStream | null = null;

    const startVideo = async () => {
      if (!isCameraOpen) return;
      setCameraLoading(true);
      setCameraError(null);
      try {
        if (streamRef.current) {
          streamRef.current.getTracks().forEach(t => t.stop());
        }

        const constraints: MediaStreamConstraints = {
          video: selectedCameraId 
            ? { deviceId: { exact: selectedCameraId } }
            : { facingMode: 'environment' }
        };

        const stream = await navigator.mediaDevices.getUserMedia(constraints);
        activeStream = stream;
        streamRef.current = stream;

        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }

        // List cameras
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(d => d.kind === 'videoinput');
        setCameraDevices(videoDevices);
        if (videoDevices.length > 0 && !selectedCameraId) {
          setSelectedCameraId(videoDevices[0].deviceId);
        }
      } catch (err: any) {
        console.error("Camera access error:", err);
        setCameraError(
          err.name === 'NotAllowedError' 
            ? 'Camera access denied. Please grant permission in your browser settings.'
            : 'Could not access camera. Make sure it is not in use by another app.'
        );
      } finally {
        setCameraLoading(false);
      }
    };

    startVideo();

    return () => {
      if (activeStream) {
        activeStream.getTracks().forEach(track => track.stop());
      }
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop());
        streamRef.current = null;
      }
    };
  }, [isCameraOpen, selectedCameraId]);

  // Camera toggle handler
  const toggleCamera = () => {
    if (cameraDevices.length <= 1) return;
    const currentIndex = cameraDevices.findIndex(d => d.deviceId === selectedCameraId);
    const nextIndex = (currentIndex + 1) % cameraDevices.length;
    setSelectedCameraId(cameraDevices[nextIndex].deviceId);
  };

  // Webcam frame snapshot capture
  const capturePhoto = () => {
    if (videoRef.current) {
      const video = videoRef.current;
      const canvas = document.createElement('canvas');
      canvas.width = video.videoWidth || 640;
      canvas.height = video.videoHeight || 480;
      
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg');
        setPreviewUrl(dataUrl);
        setFileBase64(dataUrl.split(',')[1]);
        
        setSelectedFile({
          name: `captured_rx_${new Date().toISOString().slice(0, 10).replace(/-/g, '')}_${Math.floor(100 + Math.random() * 900)}.jpg`,
          type: 'image/jpeg',
          size: Math.round((dataUrl.length * 3) / 4)
        });
        
        setErrorMessage(null);
        setScanningCompleted(false);
        setDetectedMedicines(null);
        setIsOcrMocked(false);
        setIsCameraOpen(false);
      }
    }
  };

  // Local File Processing helper
  const processFile = (file: File) => {
    const validTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (!validTypes.includes(file.type)) {
      setErrorMessage('Invalid file format. Please upload a JPEG, PNG image or a PDF document.');
      return;
    }

    setSelectedFile({
      name: file.name,
      type: file.type,
      size: file.size
    });

    setErrorMessage(null);
    setScanningCompleted(false);
    setDetectedMedicines(null);
    setIsOcrMocked(false);

    const reader = new FileReader();
    reader.onload = (e) => {
      if (e.target?.result) {
        const resultStr = e.target.result as string;
        if (file.type.startsWith('image/')) {
          setPreviewUrl(resultStr);
        } else {
          setPreviewUrl(null); // PDF
        }
        setFileBase64(resultStr.split(',')[1]);
      }
    };
    reader.readAsDataURL(file);
  };

  // File picker handler
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      processFile(e.target.files[0]);
    }
  };

  // Drag-and-Drop handlers
  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processFile(e.dataTransfer.files[0]);
    }
  };

  const handleDropAreaClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  // Auto-select first patient for caregiver
  useEffect(() => {
    if (userRole === 'caregiver' && patients.length > 0) {
      const myPatients = patients.filter(p => p.caregiverEmail === user?.email);
      if (myPatients.length > 0 && myPatients[0].id) {
        setPatientFilter(myPatients[0].id);
      } else if (patients[0].id) {
        setPatientFilter(patients[0].id);
      }
    } else if (patient?.id) {
      setPatientFilter(patient.id);
    }
  }, [user, userRole, patient, patients]);

  // Handle preset file clicks
  const selectPreset = (fileName: string) => {
    let size = 1024 * 342; // default mock size
    let type = 'image/jpeg';
    if (fileName.endsWith('.pdf')) {
      type = 'application/pdf';
      size = 1024 * 1240;
    }
    
    setSelectedFile({ name: fileName, type, size });
    setErrorMessage(null);
    setDetectedMedicines(null);
    setScanningCompleted(false);
    setIsOcrMocked(false);

    const svgUrl = getPresetSVG(fileName);
    setPreviewUrl(svgUrl);
    
    // Convert SVG to base64
    const svgXml = decodeURIComponent(svgUrl.replace('data:image/svg+xml;utf8,', ''));
    const base64Data = btoa(unescape(encodeURIComponent(svgXml)));
    setFileBase64(base64Data);
  };

  // Start real AI scan
  const startAIScan = async () => {
    if (!selectedFile || !fileBase64) {
      setErrorMessage('Please select or capture a prescription file first.');
      return;
    }

    setIsScanning(true);
    setScanProgress(0.1);
    setScanStatus('Initializing SmartMed OCR Engine...');
    setErrorMessage(null);
    setScanningCompleted(false);
    setDetectedMedicines(null);

    try {
      // 1. Image Preprocessing
      setScanStatus('Optimizing image contrast & reducing noise...');
      setScanProgress(0.25);

      let processedBase64 = fileBase64;
      if (selectedFile.type.startsWith('image/')) {
        try {
          const preprocessedDataUrl = await preprocessBase64Image(previewUrl || `data:${selectedFile.type};base64,${fileBase64}`);
          processedBase64 = preprocessedDataUrl.split(',')[1];
        } catch (e) {
          console.warn('Image preprocessing failed, falling back to original:', e);
        }
      }

      // 2. Real OCR / Vision AI Extraction
      setScanStatus('Running handwriting segmentation & character recognition (OCR)...');
      setScanProgress(0.5);

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      };
      
      const localKey = typeof window !== 'undefined' ? localStorage.getItem('smartmed_gemini_api_key') : null;
      if (localKey) {
        headers['Authorization'] = `Bearer ${localKey}`;
      }

      const ocrResponse = await fetch('/api/ocr', {
        method: 'POST',
        headers,
        body: JSON.stringify({
          fileData: processedBase64,
          mimeType: selectedFile.type,
          fileName: selectedFile.name,
        }),
      });

      if (!ocrResponse.ok) {
        const errorData = await ocrResponse.json().catch(() => ({}));
        if (errorData.error === 'API_KEY_NOT_CONFIGURED') {
          throw new Error('API_KEY_NOT_CONFIGURED');
        }
        throw new Error(errorData.message || errorData.error || 'Failed to call OCR API');
      }

      const ocrResult = await ocrResponse.json();

      if (ocrResult.confidence < 45 || !ocrResult.medicines || ocrResult.medicines.length === 0) {
        throw new Error('UNREADABLE_PRESCRIPTION');
      }

      setIsOcrMocked(ocrResult.isMock === true);

      setScanStatus('Matching extracted names against medication database...');
      setScanProgress(0.75);

      // 3. Fuzzy Matching
      const medicinesWithFuzzy = ocrResult.medicines.map((med: any) => {
        const fuzzy = fuzzyMatchMedicine(med.name || '');
        
        // Adjust confidence score:
        // OCR confidence (0-100) * Match Similarity (0-1)
        const ocrConf = med.confidence !== undefined ? med.confidence : 100;
        const matchSim = fuzzy.similarity;
        const combinedConfidence = Math.round(ocrConf * (matchSim > 0 ? matchSim : 1.0));

        // Use canonical name if high similarity, otherwise keep OCR name or fallback to "Not detected"
        const finalName = matchSim >= 0.85 ? fuzzy.matchedName : (med.name || 'Not detected');

        return {
          name: finalName,
          strength: med.strength || 'Not detected',
          dosage: med.dosage || 'Not detected',
          duration: med.duration || 'Not detected',
          schedule: {
            morning: med.morning === true,
            afternoon: med.afternoon === true,
            night: med.night === true,
          },
          timing: med.timing === 'before_food' ? 'before_food' : 'after_food',
          confidenceScore: combinedConfidence,
          isVerified: combinedConfidence >= 85, // auto-verified if high confidence
        };
      });

      setScanStatus('Analyzing dosage patterns and safety guidelines...');
      setScanProgress(1.0);
      
      // Delay slightly so the user sees the 100% completion
      await new Promise((resolve) => setTimeout(resolve, 600));

      setIsScanning(false);
      setRawOcrText(ocrResult.rawText || '');
      setDetectedMedicines(medicinesWithFuzzy);
      setScanningCompleted(true);

    } catch (err: any) {
      setIsScanning(false);
      setScanningCompleted(false);
      setDetectedMedicines(null);
      if (err.message === 'API_KEY_NOT_CONFIGURED') {
        setErrorMessage('Gemini API Key is not configured. Please click the settings gear at the top right to configure your API key.');
      } else if (err.message === 'UNREADABLE_PRESCRIPTION') {
        setErrorMessage('Unable to read this prescription clearly. Please upload a clearer image.');
      } else {
        setErrorMessage(err.message || 'An error occurred during OCR extraction. Please try uploading a clearer image.');
      }
    }
  };

  // Helper edit handlers
  const handleUpdateMedicine = (index: number, fields: Partial<DetectedMedicine>) => {
    if (!detectedMedicines) return;
    const updated = [...detectedMedicines];
    updated[index] = { ...updated[index], ...fields } as DetectedMedicine;
    setDetectedMedicines(updated);
  };

  const handleUpdateSchedule = (index: number, period: 'morning' | 'afternoon' | 'night', checked: boolean) => {
    if (!detectedMedicines) return;
    const updated = [...detectedMedicines];
    updated[index].schedule = { ...updated[index].schedule, [period]: checked };
    setDetectedMedicines(updated);
  };

  const deleteDetectedMedicine = (index: number) => {
    if (!detectedMedicines) return;
    const updated = detectedMedicines.filter((_, i) => i !== index);
    setDetectedMedicines(updated.length > 0 ? updated : null);
  };

  const addEmptyMedicineRow = () => {
    const emptyMed: DetectedMedicine = {
      name: 'New Medicine',
      strength: '500 mg',
      dosage: '1 Tablet',
      duration: '30 days',
      schedule: { morning: true, afternoon: false, night: false },
      timing: 'after_food',
      confidenceScore: 100,
      isVerified: true
    };
    if (detectedMedicines) {
      setDetectedMedicines([...detectedMedicines, emptyMed]);
    } else {
      setDetectedMedicines([emptyMed]);
    }
  };

  // Confirm data and trigger database sync
  const confirmAndSave = () => {
    if (!selectedFile || !detectedMedicines) return;

    const hasUnverified = detectedMedicines.some(m => !m.isVerified);
    if (hasUnverified) {
      alert('⚠️ Please review and verify all unrecognized/low-confidence medications before syncing.');
      return;
    }

    setIsSyncing(true);
    setSyncStep(1);

    // Run premium sync steps simulation
    setTimeout(() => {
      setSyncStep(2);
      setTimeout(() => {
        setSyncStep(3);
        setTimeout(() => {
          setSyncStep(4);
          setTimeout(() => {
            saveDataToSystem();
          }, 800);
        }, 1000);
      }, 1000);
    }, 1000);
  };

  const saveDataToSystem = async () => {
    if (!selectedFile || !detectedMedicines) return;

    // 1. Upload prescription metadata file
    await addPrescription({
      patientId: patientFilter,
      fileName: selectedFile.name,
      fileType: selectedFile.type,
      fileSize: selectedFile.size,
      downloadURL: previewUrl || '#',
      extractedMedicines: detectedMedicines,
    });

    // 2. Add each verified medicine
    for (const med of detectedMedicines) {
      let frequencyCount = 0;
      if (med.schedule.morning) frequencyCount++;
      if (med.schedule.afternoon) frequencyCount++;
      if (med.schedule.night) frequencyCount++;
      if (frequencyCount === 0) frequencyCount = 1;

      const durationDays = parseInt(med.duration.replace(/\D/g, '')) || 30;
      const quantity = durationDays * frequencyCount;

      await addMedicine({
        name: med.name,
        dosage: med.strength,
        morning: med.schedule.morning,
        afternoon: med.schedule.afternoon,
        night: med.schedule.night,
        beforeFood: med.timing === 'before_food',
        startDate: new Date().toISOString().split('T')[0],
        endDate: new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        quantity,
        pillsPerDose: 1
      });
    }

    // Reset Scanner state
    setSelectedFile(null);
    setPreviewUrl(null);
    setDetectedMedicines(null);
    setScanningCompleted(false);
    setIsOcrMocked(false);
    setIsSyncing(false);
    setSyncStep(0);
  };

  // Helper formatting for file size
  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = 1;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  };

  // Get monitored patient profiles (Caregiver role specific)
  const caregiverMonitoredPatients = patients.filter(p => p.caregiverEmail === user?.email);
  const currentPatientProfile = patients.find(p => p.id === patientFilter) || patient;
  const filteredPrescriptions = prescriptions.filter(p => p.patientId === patientFilter);

  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-350 dark:bg-slate-950">
      <Navbar />

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        
        {/* Header Title */}
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div className="flex-1">
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
              <Sparkles className="h-8 w-8 text-blue-600 dark:text-blue-500 animate-pulse" />
              Prescription Reader & AI OCR
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Upload physical prescriptions to automatically detect medication schedules and sync with active boxes.
            </p>
          </div>
          <div className="flex items-center">
            <button
              onClick={() => setIsSettingsOpen(true)}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-all dark:bg-slate-800 dark:hover:bg-slate-700 dark:text-slate-200 border-none cursor-pointer"
            >
              <Settings className="h-4 w-4" />
              OCR Config
            </button>
          </div>
        </div>

        {/* Patient Selection Selector (Caregiver console override) */}
        {userRole === 'caregiver' && (
          <div className="mt-6 flex items-center gap-3 rounded-2xl border border-slate-200/80 bg-white p-4 dark:border-slate-800 dark:bg-slate-900 max-w-md shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Managing Patient:</span>
            <div className="relative flex-1">
              <select
                value={patientFilter}
                onChange={(e) => setPatientFilter(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm outline-none focus:border-blue-500 dark:bg-slate-950 dark:border-slate-800 dark:text-white cursor-pointer appearance-none animate-none"
              >
                {caregiverMonitoredPatients.length > 0 ? (
                  caregiverMonitoredPatients.map(p => (
                    <option key={p.id} value={p.id}>{p.name} ({p.id})</option>
                  ))
                ) : (
                  <option value="mock-patient">Default Mock Patient</option>
                )}
              </select>
              <ChevronDown className="absolute right-3 top-3.5 h-4 w-4 text-slate-400 pointer-events-none" />
            </div>
          </div>
        )}

        <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-12">
          
          {/* Left Column: File upload & OCR engine state (7 columns) */}
          <div className="lg:col-span-7 space-y-6">
            
            {/* Upload Area */}
            <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white">
                Upload Document
              </h2>
              <p className="text-xs text-slate-400 mt-1">
                Upload high resolution JPEG images or PDF prescription slips for the OCR pipeline.
              </p>

              {/* Upload Drop Area */}
              <div 
                onDragEnter={handleDrag}
                onDragOver={handleDrag}
                onDragLeave={handleDrag}
                onDrop={handleDrop}
                onClick={handleDropAreaClick}
                className={`mt-5 border-2 border-dashed rounded-3xl p-8 flex flex-col items-center justify-center text-center transition-all cursor-pointer ${
                  dragActive 
                    ? 'border-blue-500 bg-blue-50/20 dark:bg-blue-950/20' 
                    : 'border-slate-205 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/10 hover:border-slate-350 dark:hover:border-slate-700'
                }`}
              >
                <input 
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  accept="image/*,application/pdf"
                  className="hidden"
                />

                <div className="flex flex-col items-center">
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-500 mb-4 shadow-inner">
                    <UploadCloud className="h-6 w-6" />
                  </div>
                  <span className="text-sm font-bold text-slate-800 dark:text-slate-200">
                    Select prescription document
                  </span>
                  <span className="text-xs text-slate-400 mt-1 max-w-xs leading-relaxed">
                    Drag and drop file here, click to browse, or take a picture using your webcam.
                  </span>
                </div>

                <div className="mt-5 flex items-center gap-3" onClick={(e) => e.stopPropagation()}>
                  <button
                    type="button"
                    onClick={handleDropAreaClick}
                    className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-750 text-xs font-bold transition-all dark:bg-slate-800 dark:hover:bg-slate-700 dark:text-slate-300 border-none cursor-pointer"
                  >
                    <File className="h-3.5 w-3.5" />
                    Browse Files
                  </button>
                  <span className="text-slate-300 dark:text-slate-700 text-xs font-bold">or</span>
                  <button
                    type="button"
                    onClick={() => {
                      setIsCameraOpen(true);
                      setCameraDevices([]);
                      setCameraError(null);
                    }}
                    className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-blue-50 hover:bg-blue-100 text-blue-650 text-xs font-bold transition-all dark:bg-blue-950/40 dark:hover:bg-blue-955/80 dark:text-blue-400 border-none cursor-pointer"
                  >
                    <Camera className="h-3.5 w-3.5" />
                    Take Photo
                  </button>
                </div>

                {/* Quick Presets Section */}
                <div className="mt-8 pt-6 border-t border-slate-100 dark:border-slate-900 w-full" onClick={(e) => e.stopPropagation()}>
                  <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-3">Presets for Quick Demo</p>
                  <div className="flex flex-wrap gap-2 justify-center">
                    <button 
                      onClick={() => selectPreset('lisinopril_rx.jpg')}
                      className="px-3 py-1.5 rounded-lg bg-blue-50 text-blue-650 text-xs font-semibold hover:bg-blue-100 transition-colors dark:bg-blue-950/25 dark:text-blue-455 cursor-pointer border-none"
                    >
                      Lisinopril Rx (10mg)
                    </button>
                    <button 
                      onClick={() => selectPreset('metformin_rx.jpg')}
                      className="px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-650 text-xs font-semibold hover:bg-emerald-100 transition-colors dark:bg-emerald-950/25 dark:text-emerald-455 cursor-pointer border-none"
                    >
                      Metformin Rx (500mg)
                    </button>
                    <button 
                      onClick={() => selectPreset('atorvastatin_rx.jpg')}
                      className="px-3 py-1.5 rounded-lg bg-amber-50 text-amber-650 text-xs font-semibold hover:bg-amber-100 transition-colors dark:bg-amber-950/25 dark:text-amber-455 cursor-pointer border-none"
                    >
                      Atorvastatin Rx (20mg)
                    </button>
                    <button 
                      onClick={() => selectPreset('eliquis_rx.jpg')}
                      className="px-3 py-1.5 rounded-lg bg-purple-50 text-purple-600 text-xs font-semibold hover:bg-purple-100 transition-colors dark:bg-purple-950/25 dark:text-purple-455 cursor-pointer border-none"
                    >
                      Eliquis Rx (5mg)
                    </button>
                    <button 
                      onClick={() => selectPreset('unclear_rx.jpg')}
                      className="px-3 py-1.5 rounded-lg bg-rose-50 text-rose-600 text-xs font-semibold hover:bg-rose-100 transition-colors dark:bg-rose-950/25 dark:text-rose-455 cursor-pointer border-none"
                    >
                      Blurry/Damaged Rx
                    </button>
                  </div>
                </div>
              </div>

              {/* Uploading File Indicator */}
              {selectedFile && !isScanning && !scanningCompleted && (
                <div className="mt-5 p-5 rounded-2xl border border-slate-200/80 bg-slate-50/10 dark:border-slate-850 dark:bg-slate-950/20 space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-500">
                        <FileText className="h-5 w-5" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-bold text-slate-800 dark:text-slate-200 truncate max-w-[200px] sm:max-w-xs">{selectedFile.name}</p>
                        <p className="text-xs text-slate-400">{formatFileSize(selectedFile.size)} • {selectedFile.type}</p>
                      </div>
                    </div>
                    
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedFile(null);
                        setPreviewUrl(null);
                        setErrorMessage(null);
                        setIsOcrMocked(false);
                      }}
                      className="p-2 rounded-xl text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-955/10 transition-colors border-none bg-transparent cursor-pointer"
                      title="Clear Selection"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>

                  {previewUrl && (
                    <div className="border border-slate-205 dark:border-slate-800 rounded-xl overflow-hidden aspect-video bg-white dark:bg-slate-950 max-h-48 flex items-center justify-center relative shadow-inner">
                      <img src={previewUrl} alt="Prescription preview" className="max-w-full max-h-full object-contain" />
                    </div>
                  )}

                  <div className="flex justify-end gap-3 pt-2">
                    <button
                      type="button"
                      onClick={startAIScan}
                      className="flex items-center gap-1.5 rounded-xl bg-blue-600 px-5 py-2.5 text-xs font-bold text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all border-none cursor-pointer"
                    >
                      <Sparkles className="h-3.5 w-3.5" />
                      Scan with SmartMed AI
                    </button>
                  </div>
                </div>
              )}

              {/* Blurry Error Message Indicator */}
              {errorMessage && (
                <div className="mt-5 p-4 rounded-2xl border border-rose-200 bg-rose-50/10 dark:border-rose-950/30 dark:bg-rose-950/5 flex items-start gap-3">
                  <AlertCircle className="h-5 w-5 text-rose-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <h4 className="text-sm font-bold text-rose-600 dark:text-rose-400">OCR Scan Failed</h4>
                    <p className="text-xs text-slate-550 dark:text-slate-405 mt-1 leading-relaxed">{errorMessage}</p>
                  </div>
                </div>
              )}
            </div>

            {/* Simulated OCR Scanner widget */}
            <AnimatePresence>
              {isScanning && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 relative overflow-hidden"
                >
                  {/* Neon Scanning line bar */}
                  <div className="absolute left-0 right-0 top-0 h-1 bg-gradient-to-r from-blue-500 via-emerald-400 to-blue-500 animate-pulse shadow-[0_0_10px_#3b82f6]" />
                  
                  <div className="flex flex-col items-center justify-center py-8">
                    <Loader2 className="h-8 w-8 text-blue-600 dark:text-blue-500 animate-spin mb-4" />
                    
                    <span className="text-xs font-bold uppercase tracking-wider text-blue-600 dark:text-blue-400">
                      SCANNING PRESCRIPTION
                    </span>
                    
                    <span className="text-base font-bold text-slate-800 dark:text-slate-200 text-center mt-2 px-6">
                      {scanStatus}
                    </span>

                    {/* Progress percentage bar */}
                    <div className="w-full max-w-sm bg-slate-100 dark:bg-slate-950 h-2.5 rounded-full mt-6 overflow-hidden">
                      <div 
                        className="bg-blue-600 h-full rounded-full transition-all duration-300"
                        style={{ width: `${scanProgress * 100}%` }}
                      />
                    </div>

                    <span className="text-xs font-bold text-slate-400 mt-2">
                      {Math.round(scanProgress * 100)}% Complete
                    </span>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Verification & Review Grid */}
            <AnimatePresence>
              {scanningCompleted && detectedMedicines && (
                <motion.div
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-md dark:border-slate-800 dark:bg-slate-900"
                >
                  <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-4">
                    <div>
                      <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white">
                        OCR Detection Review
                      </h2>
                      <p className="text-xs text-slate-400 mt-0.5">
                        Please review recognized dosages and schedule mapping before saving.
                      </p>
                    </div>

                    <button
                      onClick={addEmptyMedicineRow}
                      className="flex items-center gap-1 text-xs font-bold text-blue-600 dark:text-blue-400 hover:underline border-none bg-transparent cursor-pointer"
                    >
                      <PlusCircle className="h-4 w-4" />
                      Add Medicine
                    </button>
                  </div>

                  {/* AI Disclaimer Notice */}
                  {isOcrMocked ? (
                    <div className="mt-4 p-4 rounded-2xl border border-amber-200 bg-amber-50/10 dark:border-amber-955/30 dark:bg-amber-955/5 flex items-start gap-3">
                      <Sparkles className="h-5 w-5 text-amber-500 flex-shrink-0 mt-0.5" />
                      <div>
                        <h4 className="text-sm font-bold text-amber-600 dark:text-amber-400">Demo OCR Mode Active</h4>
                        <p className="text-xs text-slate-550 dark:text-slate-405 mt-1 leading-relaxed">
                          Gemini API key is not configured. The extracted values are mock results. Click the settings gear icon in the header to enter your Gemini API Key.
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="mt-4 p-4 rounded-2xl border border-blue-200 bg-blue-50/10 dark:border-blue-950/30 dark:bg-blue-950/5 flex items-start gap-3">
                      <Sparkles className="h-5 w-5 text-blue-500 flex-shrink-0 mt-0.5" />
                      <div>
                        <h4 className="text-sm font-bold text-blue-600 dark:text-blue-400">AI-assisted extraction</h4>
                        <p className="text-xs text-slate-550 dark:text-slate-405 mt-1 leading-relaxed">
                          AI-assisted extraction. Please verify all extracted medicine information before confirmation. Handwritten prescriptions can vary significantly and some characters may be misread.
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Collapsible raw OCR text */}
                  <div className="mt-4 border-b border-slate-100 dark:border-slate-800 pb-4">
                    <button
                      onClick={() => setShowRawOcrText(!showRawOcrText)}
                      className="flex items-center justify-between w-full text-left text-xs font-bold text-blue-600 dark:text-blue-400 hover:underline border-none bg-transparent cursor-pointer"
                    >
                      <span>{showRawOcrText ? 'Hide OCR Extracted Text' : 'View OCR Extracted Text'}</span>
                      <ChevronDown className={`h-4 w-4 transform transition-transform ${showRawOcrText ? 'rotate-180' : ''}`} />
                    </button>
                    <AnimatePresence>
                      {showRawOcrText && (
                        <motion.div
                          initial={{ opacity: 0, height: 0 }}
                          animate={{ opacity: 1, height: 'auto' }}
                          exit={{ opacity: 0, height: 0 }}
                          className="mt-2 p-3 bg-slate-50 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-slate-800 text-xs font-mono whitespace-pre-wrap max-h-40 overflow-y-auto"
                        >
                          {rawOcrText || 'No raw text extracted.'}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>

                  <div className="mt-6 space-y-6">
                    {detectedMedicines.map((med, index) => (
                      <div 
                        key={index} 
                        className="p-5 rounded-2xl border border-slate-100 dark:border-slate-800 bg-slate-50/20 relative"
                      >
                        {/* Remove card button */}
                        <button
                          onClick={() => deleteDetectedMedicine(index)}
                          className="absolute right-4 top-4 text-slate-400 hover:text-rose-500 transition-colors border-none bg-transparent cursor-pointer"
                        >
                          <Trash2 className="h-4.5 w-4.5" />
                        </button>

                        {/* Title Badges */}
                        <div className="flex flex-wrap items-center gap-2 mb-4">
                          <span className={`text-[10px] px-2 py-0.5 rounded font-black uppercase tracking-wider ${
                            med.confidenceScore >= 85
                              ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/20 dark:text-emerald-450'
                              : med.confidenceScore >= 60
                              ? 'bg-amber-50 text-amber-600 dark:bg-amber-950/20 dark:text-amber-455'
                              : 'bg-rose-50 text-rose-600 dark:bg-rose-950/20 dark:text-rose-455'
                          }`}>
                            {med.confidenceScore >= 85
                              ? 'High Confidence'
                              : med.confidenceScore >= 60
                              ? 'Medium Confidence — Please Verify'
                              : 'Low Confidence — Manual Verification Required'}
                          </span>

                          {!med.isVerified && (
                            <span className="text-[10px] bg-rose-50 text-rose-600 px-2 py-0.5 rounded font-bold dark:bg-rose-950/20 dark:text-rose-455 flex items-center gap-0.5">
                              <AlertCircle className="h-3 w-3" /> Unverified Review
                            </span>
                          )}
                        </div>

                        {/* Low confidence safety message */}
                        {med.confidenceScore < 60 && (
                          <div className="mb-4 p-3 rounded-xl border border-rose-200 bg-rose-50/10 dark:border-rose-950/30 dark:bg-rose-950/5 flex items-start gap-2">
                            <AlertCircle className="h-4.5 w-4.5 text-rose-605 dark:text-rose-400 flex-shrink-0 mt-0.5" />
                            <span className="text-xs text-rose-650 dark:text-rose-400 font-bold">
                              Medicine could not be confidently identified. Please verify manually.
                            </span>
                          </div>
                        )}

                        {/* Editable Form Inputs */}
                        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-5">
                          <div className="sm:col-span-2">
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Medicine Name
                            </label>
                            <input
                              type="text"
                              value={med.name}
                              onChange={(e) => handleUpdateMedicine(index, { name: e.target.value })}
                              className="mt-1.5 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                            />
                          </div>

                          <div>
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Strength
                            </label>
                            <input
                              type="text"
                              value={med.strength}
                              onChange={(e) => handleUpdateMedicine(index, { strength: e.target.value })}
                              className="mt-1.5 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                            />
                          </div>

                          <div>
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Dosage / Form
                            </label>
                            <input
                              type="text"
                              value={med.dosage}
                              onChange={(e) => handleUpdateMedicine(index, { dosage: e.target.value })}
                              className="mt-1.5 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                            />
                          </div>

                          <div>
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Duration
                            </label>
                            <input
                              type="text"
                              value={med.duration}
                              onChange={(e) => handleUpdateMedicine(index, { duration: e.target.value })}
                              className="mt-1.5 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                            />
                          </div>
                        </div>

                        {/* Intake Schedules checklist */}
                        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
                          <div>
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Active Daily Schedule
                            </label>
                            <div className="mt-2 flex gap-2">
                              <label className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-lg border cursor-pointer text-[11px] font-bold transition-all ${
                                med.schedule.morning
                                  ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-450'
                                  : 'border-slate-200 bg-slate-50 text-slate-650 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                              }`}>
                                <input 
                                  type="checkbox" 
                                  checked={med.schedule.morning} 
                                  onChange={(e) => handleUpdateSchedule(index, 'morning', e.target.checked)} 
                                  className="hidden" 
                                />
                                Morning
                              </label>
                              <label className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-lg border cursor-pointer text-[11px] font-bold transition-all ${
                                med.schedule.afternoon
                                  ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-450'
                                  : 'border-slate-200 bg-slate-50 text-slate-650 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                              }`}>
                                <input 
                                  type="checkbox" 
                                  checked={med.schedule.afternoon} 
                                  onChange={(e) => handleUpdateSchedule(index, 'afternoon', e.target.checked)} 
                                  className="hidden" 
                                />
                                Afternoon
                              </label>
                              <label className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-lg border cursor-pointer text-[11px] font-bold transition-all ${
                                med.schedule.night
                                  ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-450'
                                  : 'border-slate-200 bg-slate-50 text-slate-650 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                              }`}>
                                <input 
                                  type="checkbox" 
                                  checked={med.schedule.night} 
                                  onChange={(e) => handleUpdateSchedule(index, 'night', e.target.checked)} 
                                  className="hidden" 
                                />
                                Night
                              </label>
                            </div>
                          </div>

                          <div>
                            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                              Food Timing Guidelines
                            </label>
                            <select
                              value={med.timing}
                              onChange={(e) => handleUpdateMedicine(index, { timing: e.target.value as any })}
                              className="mt-2 block w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-xs outline-none focus:border-blue-500 dark:bg-slate-950 dark:border-slate-800 dark:text-white"
                            >
                              <option value="after_food">Take after food</option>
                              <option value="before_food">Take before food</option>
                            </select>
                          </div>
                        </div>

                        {/* Verify Checkbox button */}
                        {!med.isVerified && (
                          <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                            <button
                              onClick={() => handleUpdateMedicine(index, { isVerified: true })}
                              className="flex items-center gap-1.5 rounded-lg border border-emerald-500 text-emerald-600 px-3.5 py-1.5 text-xs font-bold hover:bg-emerald-50 dark:hover:bg-emerald-950/20 transition-all cursor-pointer"
                            >
                              <CheckCircle2 className="h-4 w-4" />
                              Verify Medication Info
                            </button>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>

                  {/* Actions buttons */}
                  <div className="mt-8 border-t border-slate-200 dark:border-slate-800 pt-5 flex flex-wrap gap-4 justify-between items-center">
                    <button
                      onClick={() => {
                        setSelectedFile(null);
                        setDetectedMedicines(null);
                        setScanningCompleted(false);
                        setIsOcrMocked(false);
                      }}
                      className="text-xs font-bold text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 border-none bg-transparent cursor-pointer"
                    >
                      Cancel / Reset Scan
                    </button>

                    <button
                      onClick={confirmAndSave}
                      className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-6 py-3.5 text-sm font-bold text-white shadow-lg shadow-emerald-500/10 hover:bg-emerald-700 transition-all border-none cursor-pointer"
                    >
                      <CheckCircle2 className="h-4.5 w-4.5" />
                      Confirm and Sync to SmartMed Pipeline
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Right Column: Previously Uploaded Prescription Archive files (5 columns) */}
          <div className="lg:col-span-5 space-y-6">
            <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white">
                HIPAA Prescription Files
              </h2>
              <p className="text-xs text-slate-400 mt-1">
                Monitored prescription metadata files archived in security nodes.
              </p>

              <div className="mt-5 space-y-4">
                {filteredPrescriptions.length === 0 ? (
                  <div className="py-12 border border-dashed border-slate-100 dark:border-slate-800 rounded-2xl flex flex-col items-center justify-center text-center text-slate-400">
                    <FileText className="h-8 w-8 text-slate-350 dark:text-slate-800 mb-2" />
                    <span className="text-xs">No uploaded prescription files</span>
                  </div>
                ) : (
                  filteredPrescriptions.map(pres => (
                    <div 
                      key={pres.id}
                      className="p-4 rounded-2xl border border-slate-100 dark:border-slate-800 hover:border-blue-500/30 transition-all flex items-center justify-between bg-slate-50/20 group"
                    >
                      <div className="flex items-center gap-3">
                        <div className="p-2.5 rounded-lg bg-blue-50 text-blue-600 dark:bg-blue-950/20 dark:text-blue-400">
                          <FileText className="h-5 w-5" />
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800 dark:text-slate-200 max-w-[160px] truncate">
                            {pres.fileName}
                          </p>
                          <p className="text-[10px] text-slate-400">
                            {pres.uploadDate} • {formatFileSize(pres.fileSize)}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-1.5 opacity-80 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => setViewingPrescription(pres)}
                          className="p-1.5 text-slate-450 hover:text-blue-550 dark:hover:text-blue-400 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors border-none bg-transparent cursor-pointer"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => deletePrescription(pres.id)}
                          className="p-1.5 text-slate-450 hover:text-rose-500 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors border-none bg-transparent cursor-pointer"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Selected Patient compliance details */}
            {currentPatientProfile && (
              <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Active Patient Info</span>
                <div className="mt-3 flex items-center gap-3">
                  <div className="h-10 w-10 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold">
                    {currentPatientProfile.name.charAt(0)}
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-slate-800 dark:text-slate-200">{currentPatientProfile.name}</h4>
                    <p className="text-xs text-slate-400">{currentPatientProfile.age} years old • {currentPatientProfile.gender}</p>
                  </div>
                </div>
                
                <div className="mt-4 border-t border-slate-100 dark:border-slate-800 pt-4 space-y-2">
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-400">Device Box:</span>
                    <span className="font-semibold font-mono text-slate-700 dark:text-slate-350">
                      {currentPatientProfile.deviceId || 'BOX-8800'}
                    </span>
                  </div>
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-400">Medical Conditions:</span>
                    <span className="font-semibold text-slate-700 dark:text-slate-350 text-right">
                      {currentPatientProfile.medicalConditions || 'None specified'}
                    </span>
                  </div>
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-400">Drug Allergies:</span>
                    <span className="font-semibold text-rose-500">
                      {currentPatientProfile.allergies || 'None'}
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>

      {/* Syncing SmartMed Pipeline Dialog Overlay */}
      <AnimatePresence>
        {isSyncing && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-sm">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm rounded-3xl border border-slate-200/80 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900 text-center"
            >
              <h3 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex justify-center items-center gap-2">
                <Loader2 className="h-5 w-5 text-blue-600 dark:text-blue-500 animate-spin" />
                SmartMed Pipeline
              </h3>
              <p className="text-xs text-slate-400 mt-1">
                Synchronizing metadata & dosage alerts
              </p>

              {/* Steps Progress Check list */}
              <div className="mt-6 text-left space-y-4">
                <div className="flex items-center gap-3">
                  <div className={`h-5 w-5 rounded-full flex items-center justify-center border text-[10px] ${
                    syncStep >= 1 ? 'bg-blue-600 border-blue-600 text-white font-bold' : 'border-slate-300 dark:border-slate-800'
                  }`}>
                    {syncStep > 1 ? <Check className="h-3 w-3" /> : '1'}
                  </div>
                  <span className={`text-xs ${syncStep >= 1 ? 'font-bold text-slate-800 dark:text-slate-200' : 'text-slate-405'}`}>
                    Verifying HIPAA compliance & secure storage...
                  </span>
                </div>

                <div className="flex items-center gap-3">
                  <div className={`h-5 w-5 rounded-full flex items-center justify-center border text-[10px] ${
                    syncStep >= 2 ? 'bg-blue-600 border-blue-600 text-white font-bold' : 'border-slate-300 dark:border-slate-800'
                  }`}>
                    {syncStep > 2 ? <Check className="h-3 w-3" /> : '2'}
                  </div>
                  <span className={`text-xs ${syncStep >= 2 ? 'font-bold text-slate-800 dark:text-slate-200' : 'text-slate-405'}`}>
                    Parsing dosage schedules to smart database...
                  </span>
                </div>

                <div className="flex items-center gap-3">
                  <div className={`h-5 w-5 rounded-full flex items-center justify-center border text-[10px] ${
                    syncStep >= 3 ? 'bg-blue-600 border-blue-600 text-white font-bold' : 'border-slate-300 dark:border-slate-800'
                  }`}>
                    {syncStep > 3 ? <Check className="h-3 w-3" /> : '3'}
                  </div>
                  <span className={`text-xs ${syncStep >= 3 ? 'font-bold text-slate-800 dark:text-slate-200' : 'text-slate-405'}`}>
                    Updating IoT Box schedule reminders...
                  </span>
                </div>

                <div className="flex items-center gap-3">
                  <div className={`h-5 w-5 rounded-full flex items-center justify-center border text-[10px] ${
                    syncStep >= 4 ? 'bg-emerald-600 border-emerald-600 text-white font-bold' : 'border-slate-300 dark:border-slate-800'
                  }`}>
                    {syncStep >= 4 ? <Check className="h-3 w-3" /> : '4'}
                  </div>
                  <span className={`text-xs ${syncStep >= 4 ? 'font-bold text-emerald-600 dark:text-emerald-400' : 'text-slate-405'}`}>
                    Success! Sync complete.
                  </span>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Prescription Detail Viewer Overlay Dialog */}
      <AnimatePresence>
        {viewingPrescription && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-sm">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 15 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 15 }}
              className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200/80 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900"
            >
              {/* Header */}
              <div className="flex items-center justify-between border-b border-slate-105 pb-4 dark:border-slate-800">
                <h3 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                  <FileText className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                  Prescription Details
                </h3>
                <button 
                  onClick={() => setViewingPrescription(null)}
                  className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors border-none bg-transparent cursor-pointer"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Card visual details representation */}
              <div className="mt-6 space-y-4 max-h-[70vh] overflow-y-auto pr-1">
                <div className="p-4 rounded-2xl border border-slate-100 dark:border-slate-800 bg-slate-50/20 grid grid-cols-2 gap-4 text-xs">
                  <div>
                    <span className="text-slate-400">File Name:</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200 mt-0.5 truncate">{viewingPrescription.fileName}</p>
                  </div>
                  <div>
                    <span className="text-slate-400">Upload Date:</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200 mt-0.5">{viewingPrescription.uploadDate}</p>
                  </div>
                  <div>
                    <span className="text-slate-400">File Size:</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200 mt-0.5">{formatFileSize(viewingPrescription.fileSize)}</p>
                  </div>
                  <div>
                    <span className="text-slate-400">Uploaded By:</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200 mt-0.5 truncate">{viewingPrescription.uploadedBy}</p>
                  </div>
                </div>

                {/* Original Document Preview */}
                {viewingPrescription.downloadURL && viewingPrescription.downloadURL !== '#' && (
                  <div className="border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden bg-white dark:bg-slate-950 flex items-center justify-center p-2 relative shadow-inner max-h-48">
                    {viewingPrescription.fileType === 'application/pdf' ? (
                      <div className="flex flex-col items-center gap-2 p-4 text-slate-400 w-full text-center">
                        <FileText className="h-10 w-10 text-red-500" />
                        <span className="text-xs font-bold truncate max-w-full">{viewingPrescription.fileName}</span>
                        <a 
                          href={viewingPrescription.downloadURL} 
                          download={viewingPrescription.fileName}
                          className="px-3 py-1.5 rounded-lg bg-red-50 hover:bg-red-150 text-red-650 dark:bg-red-950/25 dark:text-red-400 text-xs font-bold transition-all decoration-none inline-block border-none mt-1 cursor-pointer"
                        >
                          Download/Open PDF
                        </a>
                      </div>
                    ) : (
                      <img 
                        src={viewingPrescription.downloadURL} 
                        alt="Prescription document" 
                        className="max-w-full max-h-44 object-contain rounded-lg" 
                      />
                    )}
                  </div>
                )}

                {/* Simulated Glass Prescription Slip Visual Layout */}
                <div className="border border-slate-200 dark:border-slate-800 rounded-2xl p-6 bg-gradient-to-br from-white to-slate-50/30 dark:from-slate-900 dark:to-slate-950/20 relative shadow-inner">
                  <div className="absolute right-6 top-6 opacity-5 select-none pointer-events-none">
                    <FileText className="h-32 w-32" />
                  </div>

                  <div className="border-b border-dashed border-slate-200 dark:border-slate-800 pb-3 flex justify-between items-center">
                    <div>
                      <h4 className="font-black text-slate-955 dark:text-white tracking-wider text-xs font-mono">SMARTMED MEDICAL CLINIC</h4>
                      <p className="text-[9px] text-slate-400 font-mono mt-0.5">HIPAA ENCRYPTED EHR RECORD</p>
                    </div>
                    <span className="font-mono text-[9px] text-slate-500 border border-slate-200 dark:border-slate-800 px-2 py-0.5 rounded">Rx APPROVED</span>
                  </div>

                  <div className="mt-4 space-y-4 font-mono">
                    <div className="text-[10px] space-y-1 text-slate-600 dark:text-slate-400">
                      <p>PATIENT ID: <span className="text-slate-955 dark:text-white font-bold">{viewingPrescription.patientId}</span></p>
                      <p>ROUTING NODE: <span className="text-slate-955 dark:text-white font-bold">{viewingPrescription.deviceId}</span></p>
                      <p>DOCUMENT STATUS: <span className="text-emerald-500 font-bold">SYNCHRONIZED</span></p>
                    </div>

                    <div className="border-t border-slate-100 dark:border-slate-800 pt-3">
                      <p className="text-[10px] font-bold text-slate-955 dark:text-white mb-2">DETECTED FORMULATIONS:</p>
                      
                      {viewingPrescription.extractedMedicines && viewingPrescription.extractedMedicines.length > 0 ? (
                        viewingPrescription.extractedMedicines.map((med: any, index: number) => (
                          <div key={index} className="text-xs border-l-2 border-blue-500 pl-3 py-1 space-y-0.5 mb-3">
                            <p className="font-bold text-slate-955 dark:text-white">{med.name} {med.strength}</p>
                            <p className="text-[10px] text-slate-400">
                              Take {med.dosage} ({[
                                med.schedule.morning ? 'Morning' : null,
                                med.schedule.afternoon ? 'Afternoon' : null,
                                med.schedule.night ? 'Night' : null
                              ].filter(Boolean).join(' - ')}) {med.timing === 'after_food' ? 'after food' : 'before food'}. {med.duration && `(${med.duration})`}
                            </p>
                          </div>
                        ))
                      ) : (
                        <p className="text-xs text-slate-400">No formulations detected or saved.</p>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* Footer action button */}
              <div className="mt-6 flex justify-end border-t border-slate-100 dark:border-slate-800 pt-4">
                <button
                  onClick={() => setViewingPrescription(null)}
                  className="rounded-xl border border-slate-200 bg-white px-5 py-2.5 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-all dark:border-slate-800 dark:bg-slate-900 dark:text-slate-350 dark:hover:bg-slate-800 border-none cursor-pointer"
                >
                  Dismiss Details
                </button>
              </div>
            </motion.div>
          </div>
        )}

        {/* Webcam Capture Modal */}
        {isCameraOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 15 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 15 }}
              className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200/80 bg-white dark:border-slate-800 dark:bg-slate-900 shadow-2xl"
            >
              {/* Header */}
              <div className="flex items-center justify-between border-b border-slate-100 p-6 dark:border-slate-800">
                <h3 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                  <Camera className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                  Prescription Scanner Camera
                </h3>
                <button 
                  onClick={() => setIsCameraOpen(false)}
                  className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors border-none bg-transparent cursor-pointer"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Video Preview viewport */}
              <div className="relative aspect-video bg-black flex items-center justify-center overflow-hidden">
                {cameraLoading ? (
                  <div className="flex flex-col items-center gap-2 text-slate-400">
                    <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
                    <span className="text-xs">Accessing camera stream...</span>
                  </div>
                ) : cameraError ? (
                  <div className="p-6 text-center text-rose-500 flex flex-col items-center gap-2">
                    <AlertCircle className="h-10 w-10 text-rose-500" />
                    <p className="text-xs font-bold">{cameraError}</p>
                    <button 
                      onClick={() => setIsCameraOpen(false)}
                      className="mt-4 px-4 py-2 rounded-xl bg-slate-800 text-white text-xs font-bold hover:bg-slate-700 transition-colors border-none"
                    >
                      Close Window
                    </button>
                  </div>
                ) : (
                  <>
                    <video 
                      ref={videoRef} 
                      autoPlay 
                      playsInline 
                      muted 
                      className="w-full h-full object-cover" 
                    />
                    
                    {/* Targeting guides overlay */}
                    <div className="absolute inset-0 pointer-events-none flex items-center justify-center p-6">
                      <div className="w-full h-full border-2 border-dashed border-white/60 rounded-xl relative flex items-center justify-center">
                        <div className="absolute top-2 left-2 text-[9px] font-mono text-white bg-black/40 px-2 py-0.5 rounded uppercase tracking-wider backdrop-blur-xs">
                          Align sheet inside guidelines
                        </div>
                        <div className="w-8 h-8 border-t-2 border-l-2 border-blue-500 absolute top-[-2px] left-[-2px] rounded-tl-lg" />
                        <div className="w-8 h-8 border-t-2 border-r-2 border-blue-500 absolute top-[-2px] right-[-2px] rounded-tr-lg" />
                        <div className="w-8 h-8 border-b-2 border-l-2 border-blue-500 absolute bottom-[-2px] left-[-2px] rounded-bl-lg" />
                        <div className="w-8 h-8 border-b-2 border-r-2 border-blue-500 absolute bottom-[-2px] right-[-2px] rounded-br-lg" />
                      </div>
                    </div>
                  </>
                )}
              </div>

              {/* Controls */}
              <div className="p-6 bg-slate-50 dark:bg-slate-955/40 flex items-center justify-between border-t border-slate-100 dark:border-slate-800">
                {/* Camera selector toggle */}
                {cameraDevices.length > 1 ? (
                  <button
                    onClick={toggleCamera}
                    type="button"
                    title="Switch camera"
                    className="p-2.5 rounded-full border border-slate-200 bg-white hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800 transition-all text-slate-600 dark:text-slate-350 cursor-pointer"
                  >
                    <RefreshCw className="h-4 w-4" />
                  </button>
                ) : (
                  <div className="w-9" />
                )}

                {/* Snap capture */}
                <button
                  disabled={!!cameraError || cameraLoading}
                  onClick={capturePhoto}
                  type="button"
                  className="flex items-center gap-2 rounded-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold px-8 py-3 text-sm shadow-lg shadow-blue-500/20 transition-all cursor-pointer border-none"
                >
                  <Camera className="h-4 w-4" />
                  Capture Photo
                </button>

                <button
                  onClick={() => setIsCameraOpen(false)}
                  type="button"
                  className="text-xs font-bold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-white transition-colors border-none bg-transparent cursor-pointer"
                >
                  Cancel
                </button>
              </div>
            </motion.div>
          </div>
        )}

        {/* OCR Key Settings Modal */}
        {isSettingsOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-sm">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md rounded-3xl border border-slate-200/80 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900"
            >
              <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-4">
                <h3 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                  <Settings className="h-5 w-5 text-slate-650" />
                  Prescription Reader Settings
                </h3>
                <button 
                  onClick={() => setIsSettingsOpen(false)}
                  className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors border-none bg-transparent cursor-pointer"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="mt-6 space-y-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
                    Gemini API Key
                  </label>
                  <input
                    type="password"
                    placeholder="AIzaSy..."
                    value={apiKey}
                    onChange={(e) => handleSaveApiKey(e.target.value)}
                    className="block w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-3 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                  <p className="text-[10px] text-slate-400 mt-2 leading-relaxed">
                    Enter your Gemini API key from Google AI Studio. The key is stored locally in your browser and used only for prescription text extraction. If left blank, the app will try to read <code>GEMINI_API_KEY</code> from the server environment.
                  </p>
                </div>
              </div>

              <div className="mt-6 flex justify-end">
                <button
                  onClick={() => setIsSettingsOpen(false)}
                  className="rounded-xl bg-blue-600 px-5 py-2.5 text-xs font-bold text-white hover:bg-blue-700 transition-all border-none cursor-pointer"
                >
                  Save & Close
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
