'use client';

import React, { useEffect, useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Navbar } from '../../components/Navbar';
import { DashboardChart } from '../../components/DashboardChart';
import { Patient } from '../../services/mockData';
import { 
  Users, 
  Activity, 
  Clock, 
  AlertCircle, 
  Percent, 
  Phone, 
  Stethoscope, 
  ShieldAlert,
  Smartphone,
  Plus,
  Edit,
  Trash2,
  X,
  CheckCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export default function CaregiverDashboard() {
  const { 
    patient, 
    deviceId, 
    medicines, 
    adherenceLogs, 
    notifications,
    doseRecords,
    generateDoseRecordsForDay,
    patients,
    addPatient,
    updatePatient,
    deletePatient,
    user
  } = useApp();

  // Tab State
  const [activeTab, setActiveTab] = useState<'overview' | 'patients'>('overview');
  
  // Directory state
  const [directoryView, setDirectoryView] = useState<'list' | 'form'>('list');
  const [editingPatient, setEditingPatient] = useState<Patient | null>(null);
  
  // Form input states
  const [name, setName] = useState('');
  const [id, setId] = useState('');
  const [age, setAge] = useState('');
  const [gender, setGender] = useState('Male');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [emergencyName, setEmergencyName] = useState('');
  const [emergencyPhone, setEmergencyPhone] = useState('');
  
  // Alerts and validations state
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  useEffect(() => {
    generateDoseRecordsForDay(patient?.id || 'mock-patient', new Date().toISOString().split('T')[0]);
  }, [patient, generateDoseRecordsForDay]);

  const missedDosesCount = adherenceLogs.filter(log => log.status === 'missed').length;
  const emergencyAlerts = notifications.filter(n => n.type === 'emergency');

  // Adherence percentage based on scheduled pill quantities
  const todayStr = new Date().toISOString().split('T')[0];
  const todayDoses = doseRecords.filter(r => r.scheduledDate === todayStr && r.patientId === (patient?.id || 'mock-patient'));
  const totalScheduledPills = todayDoses.reduce((acc, d) => acc + d.scheduledPills, 0);
  const totalTakenPills = todayDoses.reduce((acc, d) => acc + d.takenPills, 0);
  const adherenceRate = totalScheduledPills > 0 ? Math.round((totalTakenPills / totalScheduledPills) * 100) : 100;

  // Filter patients monitored under this caregiver
  const myPatients = patients.filter(p => p.caregiverEmail === user?.email);

  const clearForm = () => {
    setName('');
    setId('');
    setAge('');
    setGender('Male');
    setPhone('');
    setAddress('');
    setEmergencyName('');
    setEmergencyPhone('');
    setErrorMsg('');
    setEditingPatient(null);
  };

  const openAddForm = () => {
    clearForm();
    setDirectoryView('form');
    setSuccessMsg('');
  };

  const openEditForm = (p: Patient) => {
    clearForm();
    setEditingPatient(p);
    setName(p.name);
    setId(p.id || '');
    setAge(p.age.toString());
    setGender(p.gender);
    setPhone(p.phone);
    setAddress(p.address);
    
    if (p.emergencyContact && p.emergencyContact.includes(' - ')) {
      const parts = p.emergencyContact.split(' - ');
      setEmergencyName(parts[0]);
      setEmergencyPhone(parts[1] || '');
    } else {
      setEmergencyName(p.emergencyContact || '');
      setEmergencyPhone('');
    }
    
    setDirectoryView('form');
    setSuccessMsg('');
  };

  const validateForm = () => {
    if (!name.trim()) return 'Patient Name is required.';
    if (!id.trim()) return 'Patient ID is required.';
    if (!/^[a-zA-Z0-9_-]+$/.test(id.trim())) return 'Patient ID must be alphanumeric (dashes/underscores allowed).';
    if (!editingPatient && patients.some(p => p.id?.toLowerCase() === id.trim().toLowerCase())) {
      return 'Patient ID must be unique.';
    }
    const parsedAge = parseInt(age);
    if (isNaN(parsedAge) || parsedAge <= 0 || parsedAge > 130) {
      return 'Please enter a valid age.';
    }
    if (!phone.trim()) return 'Phone Number is required.';
    if (!address.trim()) return 'Address is required.';
    if (!emergencyName.trim()) return 'Emergency Contact Name is required.';
    if (!emergencyPhone.trim()) return 'Emergency Contact Number is required.';
    return '';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const error = validateForm();
    if (error) {
      setErrorMsg(error);
      return;
    }

    const emergencyContactString = `${emergencyName.trim()} - ${emergencyPhone.trim()}`;
    const patientData: Patient = {
      id: id.trim(),
      name: name.trim(),
      age: parseInt(age),
      gender,
      phone: phone.trim(),
      address: address.trim(),
      emergencyContact: emergencyContactString,
      caregiverName: user?.displayName || user?.email || 'Caregiver',
      caregiverPhone: '',
      medicalConditions: editingPatient?.medicalConditions || '',
      allergies: editingPatient?.allergies || '',
      deviceId: editingPatient?.deviceId || '',
      caregiverEmail: user?.email
    };

    try {
      if (editingPatient) {
        await updatePatient(editingPatient.id!, patientData);
        setSuccessMsg('Patient Updated Successfully');
      } else {
        await addPatient(patientData);
        setSuccessMsg('Patient Added Successfully');
      }

      setDirectoryView('list');
      clearForm();

      setTimeout(() => {
        setSuccessMsg('');
      }, 3000);
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to save patient.');
    }
  };

  const handleDelete = async (patientId: string) => {
    try {
      await deletePatient(patientId);
      setDeleteConfirmId(null);
      setSuccessMsg('Patient Deleted Successfully');
      setTimeout(() => {
        setSuccessMsg('');
      }, 3000);
    } catch (err: any) {
      setErrorMsg('Failed to delete patient.');
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-300 dark:bg-slate-950">
      <Navbar />

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        
        {/* Header section */}
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
              <Users className="h-8 w-8 text-emerald-600 dark:text-emerald-500" />
              Caregiver Console
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Manage patient profiles, medication compliance, and IoT devices.
            </p>
          </div>
        </div>

        {/* Tab Selection */}
        <div className="mt-8 flex border-b border-slate-200 dark:border-slate-800">
          <button
            onClick={() => setActiveTab('overview')}
            className={`px-5 py-2.5 text-sm font-bold border-b-2 transition-all -mb-px ${
              activeTab === 'overview'
                ? 'border-blue-600 text-blue-600 dark:border-blue-400 dark:text-blue-400'
                : 'border-transparent text-slate-550 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
            }`}
          >
            Overview Dashboard
          </button>
          <button
            onClick={() => setActiveTab('patients')}
            className={`px-5 py-2.5 text-sm font-bold border-b-2 transition-all -mb-px ${
              activeTab === 'patients'
                ? 'border-blue-600 text-blue-600 dark:border-blue-400 dark:text-blue-400'
                : 'border-transparent text-slate-550 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
            }`}
          >
            Patient Directory
          </button>
        </div>

        <div className="mt-8">
          {activeTab === 'overview' ? (
            /* Tab 1: Overview Dashboard */
            <>
              {/* Adherence Widgets Row */}
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
                {/* Compliance percentage */}
                <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Adherence Rate</span>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-2xl font-black text-slate-800 dark:text-slate-200">{adherenceRate}%</span>
                    <Percent className="h-6 w-6 text-emerald-500" />
                  </div>
                  <div className="mt-3 text-xs text-slate-400">
                    Adherence target: <span className="font-semibold text-slate-600 dark:text-slate-300">&gt;90% compliance</span>
                  </div>
                </div>

                {/* Missed doses */}
                <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Missed Doses</span>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-2xl font-black text-slate-800 dark:text-slate-200">{missedDosesCount}</span>
                    <AlertCircle className={`h-6 w-6 ${missedDosesCount > 0 ? 'text-amber-500' : 'text-slate-300'}`} />
                  </div>
                  <div className="mt-3 text-xs text-slate-400">
                    Timeline: <span className="font-semibold text-slate-600 dark:text-slate-300">past 30 days logs</span>
                  </div>
                </div>

                {/* Connected Device */}
                <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Connected Device</span>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="font-mono text-base font-bold text-slate-850 dark:text-slate-200">
                      {deviceId || 'BOX-8800'}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-bold text-blue-600 dark:bg-blue-950/20 dark:text-blue-400">
                      IoT Sync Active
                    </span>
                  </div>
                  <div className="mt-3 text-xs text-slate-400">
                    Hardware Battery Charge: <span className="font-semibold text-slate-600 dark:text-slate-300">88%</span>
                  </div>
                </div>

                {/* Emergency Alerts Indicator */}
                <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Emergency Alarms</span>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-2xl font-black text-slate-800 dark:text-slate-200">{emergencyAlerts.length}</span>
                    <ShieldAlert className={`h-6 w-6 ${emergencyAlerts.length > 0 ? 'text-rose-500 fill-rose-500/10 animate-pulse' : 'text-slate-300'}`} />
                  </div>
                  <div className="mt-3 text-xs text-slate-400">
                    Critical Alerts: <span className="font-semibold text-slate-600 dark:text-slate-300">{emergencyAlerts.length > 0 ? 'Action required!' : 'None'}</span>
                  </div>
                </div>
              </div>

              {/* Dashboard Panels Layout */}
              <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-3">
                {/* Left Column: Patient Info & Alerts */}
                <div className="lg:col-span-1 space-y-6">
                  {/* Patient Info Card */}
                  <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                    <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                      <Users className="h-5 w-5 text-emerald-600 dark:text-emerald-500" />
                      Patient Information
                    </h2>
                    
                    <div className="mt-6 space-y-4 text-sm">
                      <div>
                        <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Full Name</span>
                        <p className="font-bold text-slate-900 dark:text-white mt-0.5">{patient?.name || 'Arthur Pendelton'}</p>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Age</span>
                          <p className="font-semibold text-slate-700 dark:text-slate-300 mt-0.5">{patient?.age || '78'} years</p>
                        </div>
                        <div>
                          <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Gender</span>
                          <p className="font-semibold text-slate-700 dark:text-slate-300 mt-0.5">{patient?.gender || 'Male'}</p>
                        </div>
                      </div>
                      <div>
                        <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Phone & Address</span>
                        <p className="font-semibold text-slate-700 dark:text-slate-300 mt-0.5">{patient?.phone || '555-0199'}</p>
                        <p className="text-xs text-slate-500 mt-0.5">{patient?.address || '123 Care Street, Boston MA'}</p>
                      </div>
                      
                      <div className="border-t border-slate-100 dark:border-slate-800 pt-4 space-y-3">
                        <div className="flex items-center gap-2 text-xs font-bold text-slate-800 dark:text-slate-200">
                          <Stethoscope className="h-4.5 w-4.5 text-blue-600" />
                          Medical Conditions
                        </div>
                        <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed bg-slate-50 dark:bg-slate-950 p-2.5 rounded-xl border border-slate-100 dark:border-slate-800">
                          {patient?.medicalConditions || 'Hypertension, Mild Cognitive Impairment'}
                        </p>
                      </div>

                      <div className="pt-2 space-y-3">
                        <div className="flex items-center gap-2 text-xs font-bold text-slate-800 dark:text-slate-200">
                          <AlertCircle className="h-4.5 w-4.5 text-rose-500" />
                          Allergies
                        </div>
                        <p className="text-xs text-rose-700 dark:text-rose-400 leading-relaxed bg-rose-50/30 dark:bg-rose-950/10 p-2.5 rounded-xl border border-rose-100/50 dark:border-rose-900/20">
                          {patient?.allergies || 'Sulfas, Penicillin'}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Today's Adherence Checklist */}
                  <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                    <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                      <Activity className="h-5 w-5 text-emerald-600 dark:text-emerald-500" />
                      Today's Medication Doses
                    </h2>
                    <div className="mt-6 space-y-4">
                      {todayDoses.length === 0 ? (
                        <p className="text-slate-400 text-xs py-4 text-center">No scheduled doses for today</p>
                      ) : (
                        todayDoses.map((record) => {
                          const adherencePct = record.scheduledPills > 0 ? Math.round((record.takenPills / record.scheduledPills) * 100) : 100;
                          return (
                            <div key={record.id} className="p-3 bg-slate-50 dark:bg-slate-950/20 rounded-xl border border-slate-100 dark:border-slate-800 text-xs space-y-2">
                              <div className="flex justify-between items-center">
                                <span className="font-bold text-slate-850 dark:text-slate-200 capitalize">{record.medicineName}</span>
                                <span className={`text-[9px] px-1.5 py-0.5 rounded font-bold ${
                                  record.status === 'Completed' 
                                    ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400' 
                                    : record.status === 'Partially Taken' 
                                      ? 'bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400'
                                      : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-450'
                                }`}>{record.status}</span>
                              </div>
                              <div className="text-[11px] text-slate-500 space-y-1 dark:text-slate-400">
                                <p className="capitalize">Period: <span className="font-semibold text-slate-700 dark:text-slate-350">{record.dosePeriod} ({record.scheduledTime})</span></p>
                                <div className="flex justify-between pt-1 font-mono text-[10px]">
                                  <span>Sched: {record.scheduledPills}</span>
                                  <span>Taken: {record.takenPills}</span>
                                  <span>Rem: {record.remainingPills}</span>
                                  <span className="text-blue-600 dark:text-blue-400 font-bold">Adh: {adherencePct}%</span>
                                </div>
                              </div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  </div>

                  {/* Emergency Alerts Logs */}
                  {emergencyAlerts.length > 0 && (
                    <div className="rounded-3xl border border-rose-100 bg-rose-50/20 p-6 shadow-sm dark:border-rose-900/30 dark:bg-rose-950/10">
                      <h2 className="text-lg font-black tracking-tight text-rose-700 dark:text-rose-400 flex items-center gap-2">
                        <ShieldAlert className="h-5 w-5 animate-bounce" />
                        Urgent Alarms
                      </h2>
                      <div className="mt-4 space-y-3">
                        {emergencyAlerts.map(alert => (
                          <div key={alert.id} className="p-3 bg-white dark:bg-slate-900 rounded-xl border border-rose-100 dark:border-rose-900/30 text-xs">
                            <p className="font-bold text-slate-900 dark:text-white">{alert.message}</p>
                            <span className="text-[10px] text-slate-400 dark:text-slate-500 mt-1 block">{alert.timestamp}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Right Column: Adherence chart & Timelines */}
                <div className="lg:col-span-2 space-y-6">
                  {/* Chart Area */}
                  <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                    <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                      <Activity className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                      Adherence History
                    </h2>
                    <p className="mt-1 text-xs text-slate-400">
                      Compliance score measured over the last week.
                    </p>
                    <div className="mt-6">
                      <DashboardChart />
                    </div>
                  </div>

                  {/* Compliance Timeline Logs */}
                  <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                    <h2 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                      <Clock className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                      Activity Timeline
                    </h2>
                    <p className="mt-1 text-xs text-slate-400">
                      Real-time medication intake log sent by IoT box sensors.
                    </p>

                    <div className="mt-6 relative pl-6 border-l border-slate-100 dark:border-slate-800 space-y-6">
                      {adherenceLogs.length === 0 ? (
                        <p className="text-slate-400 text-xs py-4">No recent compliance events</p>
                      ) : (
                        adherenceLogs.map((log) => (
                          <div key={log.id} className="relative">
                            {/* Timeline dot */}
                            <span className={`absolute -left-[30px] top-1 flex h-4 w-4 rounded-full border-2 border-white dark:border-slate-900 ${
                              log.status === 'taken' ? 'bg-emerald-500' : 'bg-rose-500'
                            }`} />
                            
                            <div className="text-xs">
                              <div className="flex justify-between items-center">
                                <span className="font-bold text-slate-850 dark:text-slate-200">
                                  {log.medicineName} dose ({log.dose})
                                </span>
                                <span className="text-[10px] text-slate-400 font-medium">{log.time}</span>
                              </div>
                              <p className={`mt-1 font-semibold ${
                                log.status === 'taken' ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-450'
                              }`}>
                                {log.status === 'taken' ? 'Intake Confirmed' : 'Dose Missed'}
                              </p>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </>
          ) : (
            /* Tab 2: Patient Directory View */
            <div className="space-y-6">
              
              {/* Success Notification Banner */}
              {successMsg && (
                <div className="flex items-center gap-3 rounded-2xl bg-emerald-50 border border-emerald-100 p-4 text-sm text-emerald-800 dark:bg-emerald-950/20 dark:border-emerald-900/30 dark:text-emerald-400">
                  <CheckCircle className="h-5 w-5 shrink-0 text-emerald-600" />
                  <span className="font-bold">{successMsg}</span>
                </div>
              )}

              {/* Error Notification Banner */}
              {errorMsg && (
                <div className="flex items-center gap-3 rounded-2xl bg-rose-50 border border-rose-100 p-4 text-sm text-rose-800 dark:bg-rose-950/20 dark:border-rose-900/30 dark:text-rose-400">
                  <AlertCircle className="h-5 w-5 shrink-0 text-rose-600" />
                  <span className="font-bold">{errorMsg}</span>
                </div>
              )}

              {directoryView === 'list' ? (
                /* Patient List Sub-view */
                <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  
                  {/* Title & Add button header */}
                  <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-slate-100 pb-5 dark:border-slate-850">
                    <div>
                      <h2 className="text-xl font-black text-slate-900 dark:text-white">Active Patient Monitored List</h2>
                      <p className="mt-1 text-xs text-slate-400">List of profiles synced to your caregiver portal.</p>
                    </div>
                    
                    <button
                      onClick={openAddForm}
                      className="flex items-center justify-center gap-1.5 rounded-xl bg-blue-600 px-4 py-2.5 text-xs font-bold text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all dark:bg-blue-500 dark:hover:bg-blue-600 shrink-0 self-start sm:self-center"
                    >
                      <Plus className="h-4 w-4" />
                      Add Patient
                    </button>
                  </div>

                  {myPatients.length === 0 ? (
                    /* Empty Directory State */
                    <div className="py-20 flex flex-col items-center justify-center text-center">
                      <Users className="h-14 w-14 text-slate-300 dark:text-slate-700 animate-pulse" />
                      <h3 className="mt-4 text-base font-bold text-slate-700 dark:text-slate-350">No Monitored Patients Added</h3>
                      <p className="mt-1.5 text-xs text-slate-400 max-w-sm">
                        Use the "Add Patient" button above to registers patient files and manage their schedules.
                      </p>
                    </div>
                  ) : (
                    /* Patient Table Grid */
                    <div className="mt-6 overflow-x-auto">
                      <table className="w-full text-left border-collapse">
                        <thead>
                          <tr className="border-b border-slate-100 dark:border-slate-800 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                            <th className="pb-3 pl-2">Patient Details</th>
                            <th className="pb-3">Patient ID</th>
                            <th className="pb-3">Age</th>
                            <th className="pb-3">Phone</th>
                            <th className="pb-3">Status</th>
                            <th className="pb-3 text-right pr-2">Actions</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 dark:divide-slate-850 text-xs text-slate-700 dark:text-slate-300">
                          {myPatients.map((p) => {
                            const isLinked = !!p.deviceId;
                            return (
                              <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-900/30 transition-all">
                                <td className="py-3.5 pl-2 font-bold text-slate-900 dark:text-white">
                                  {p.name}
                                </td>
                                <td className="py-3.5 font-mono text-[11px] text-blue-600 dark:text-blue-450 font-bold">
                                  {p.id}
                                </td>
                                <td className="py-3.5">{p.age} years</td>
                                <td className="py-3.5 font-semibold">{p.phone}</td>
                                <td className="py-3.5">
                                  <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[9px] font-bold ${
                                    isLinked 
                                      ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/20 dark:text-emerald-450' 
                                      : 'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400'
                                  }`}>
                                    {isLinked ? 'Connected' : 'Unlinked'}
                                  </span>
                                </td>
                                <td className="py-3.5 text-right pr-2">
                                  <div className="flex justify-end items-center gap-2">
                                    <button
                                      onClick={() => openEditForm(p)}
                                      className="p-1.5 rounded-lg border border-slate-100 text-blue-600 hover:bg-blue-50/50 dark:border-slate-800 dark:text-blue-400 dark:hover:bg-blue-950/20"
                                      title="Edit profile"
                                    >
                                      <Edit className="h-3.5 w-3.5" />
                                    </button>
                                    <button
                                      onClick={() => setDeleteConfirmId(p.id!)}
                                      className="p-1.5 rounded-lg border border-slate-100 text-rose-600 hover:bg-rose-50/50 dark:border-slate-800 dark:text-rose-450 dark:hover:bg-rose-950/20"
                                      title="Delete profile"
                                    >
                                      <Trash2 className="h-3.5 w-3.5" />
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  )}

                </div>
              ) : (
                /* Patient Add/Edit Form */
                <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 max-w-2xl">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-4 dark:border-slate-800">
                    <h3 className="text-lg font-black text-slate-900 dark:text-white">
                      {editingPatient ? 'Modify Patient Profile' : 'Register Monitored Patient'}
                    </h3>
                    <button
                      onClick={() => setDirectoryView('list')}
                      className="p-1.5 rounded-full text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-850"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>

                  <form onSubmit={handleSubmit} className="mt-6 space-y-5">
                    
                    {/* Patient Name field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Patient Name</label>
                      <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="John Doe"
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                        required
                      />
                    </div>

                    {/* Patient ID field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Patient ID</label>
                      <input
                        type="text"
                        value={id}
                        onChange={(e) => setId(e.target.value)}
                        placeholder="PAT-9080"
                        disabled={!!editingPatient}
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500 disabled:opacity-50"
                        required
                      />
                    </div>

                    {/* Age and Gender row */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Age</label>
                        <input
                          type="number"
                          value={age}
                          onChange={(e) => setAge(e.target.value)}
                          placeholder="74"
                          className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                          required
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Gender</label>
                        <select
                          value={gender}
                          onChange={(e) => setGender(e.target.value)}
                          className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all dark:border-slate-800 dark:bg-slate-950 dark:text-white focus:border-blue-500"
                        >
                          <option value="Male">Male</option>
                          <option value="Female">Female</option>
                          <option value="Other">Other</option>
                          <option value="Not specified">Not specified</option>
                        </select>
                      </div>
                    </div>

                    {/* Phone field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Phone Number</label>
                      <input
                        type="text"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        placeholder="555-0199"
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                        required
                      />
                    </div>

                    {/* Address field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Home Address</label>
                      <textarea
                        value={address}
                        onChange={(e) => setAddress(e.target.value)}
                        placeholder="123 Care Street, Boston MA"
                        rows={2}
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                        required
                      />
                    </div>

                    {/* Emergency Contacts header */}
                    <div className="border-t border-slate-100 pt-4 dark:border-slate-800">
                      <h4 className="text-sm font-black text-slate-900 dark:text-white">Emergency Contact</h4>
                    </div>

                    {/* Emergency Name field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Contact Name</label>
                      <input
                        type="text"
                        value={emergencyName}
                        onChange={(e) => setEmergencyName(e.target.value)}
                        placeholder="John Doe (Son)"
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                        required
                      />
                    </div>

                    {/* Emergency Phone field */}
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-450">Contact Number</label>
                      <input
                        type="text"
                        value={emergencyPhone}
                        onChange={(e) => setEmergencyPhone(e.target.value)}
                        placeholder="555-0120"
                        className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-xs text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white dark:focus:border-blue-500"
                        required
                      />
                    </div>

                    {/* Action buttons */}
                    <div className="mt-8 flex justify-end gap-3 font-bold text-xs">
                      <button
                        type="button"
                        onClick={() => setDirectoryView('list')}
                        className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-650 hover:bg-slate-50 dark:border-slate-850 dark:text-slate-400 dark:hover:bg-slate-850"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        className="px-5 py-2.5 rounded-xl bg-blue-600 text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all dark:bg-blue-500 dark:hover:bg-blue-600"
                      >
                        Save Patient
                      </button>
                    </div>

                  </form>
                </div>
              )}

            </div>
          )}
        </div>

        {/* Delete Confirmation Overlays */}
        {deleteConfirmId && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-xs">
            <div className="w-full max-w-sm rounded-3xl border border-slate-200/80 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900 animate-in fade-in zoom-in duration-200">
              <h3 className="text-lg font-black text-slate-900 dark:text-white">Delete Patient Profile?</h3>
              <p className="mt-2 text-xs text-slate-500 leading-relaxed">
                Are you sure you want to delete this patient profile? This action cannot be undone and will unbind all schedules.
              </p>
              <div className="mt-6 flex justify-end gap-2 text-xs font-bold">
                <button
                  onClick={() => setDeleteConfirmId(null)}
                  className="px-3.5 py-2 rounded-xl text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-850"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleDelete(deleteConfirmId)}
                  className="px-4 py-2 rounded-xl bg-rose-600 text-white hover:bg-rose-700 transition-colors shadow-md shadow-rose-500/10"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}

      </main>
    </div>
  );
}
