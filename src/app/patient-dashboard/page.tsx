'use client';

import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { Navbar } from '../../components/Navbar';
import { MedicineModal } from '../../components/MedicineModal';
import { 
  Heart, 
  Search, 
  Plus, 
  Battery, 
  RefreshCw, 
  AlertTriangle,
  Calendar,
  CheckCircle2,
  CheckSquare,
  Square,
  ClipboardList
} from 'lucide-react';
import { motion } from 'framer-motion';

export default function PatientDashboard() {
  const { 
    patient, 
    deviceId, 
    medicines, 
    doseRecords,
    generateDoseRecordsForDay,
    takeWebPill
  } = useApp();

  const [search, setSearch] = useState('');
  const [filterMode, setFilterMode] = useState<'all' | 'morning' | 'afternoon' | 'night'>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    generateDoseRecordsForDay(patient?.id || 'mock-patient', new Date().toISOString().split('T')[0]);
  }, [patient, generateDoseRecordsForDay]);

  const filteredMedicines = medicines.filter(m => {
    const matchesSearch = m.name.toLowerCase().includes(search.toLowerCase()) || 
                          m.dosage.toLowerCase().includes(search.toLowerCase());
    
    if (filterMode === 'all') return matchesSearch;
    if (filterMode === 'morning') return matchesSearch && m.morning;
    if (filterMode === 'afternoon') return matchesSearch && m.afternoon;
    if (filterMode === 'night') return matchesSearch && m.night;
    return matchesSearch;
  });

  const lowStockCount = medicines.filter(m => m.remainingTablets < 10).length;

  // Estimate soonest refill date
  const soonestRefillMed = medicines.length > 0 
    ? [...medicines].sort((a, b) => new Date(a.estimatedRefillDate).getTime() - new Date(b.estimatedRefillDate).getTime())[0]
    : null;

  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-300 dark:bg-slate-950">
      <Navbar />

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        
        {/* Welcome Section */}
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white">
              Hello, {patient?.name || 'Patient'}
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Welcome back to your SmartMed portal. Everything looks stable.
            </p>
          </div>
          
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center justify-center gap-1.5 rounded-xl bg-blue-600 px-4 py-3 text-sm font-bold text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all active:scale-95 dark:bg-blue-500 dark:hover:bg-blue-600"
          >
            <Plus className="h-4 w-4" />
            Add Medication
          </button>
        </div>

        {/* Dashboard Widgets Row */}
        <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {/* Widget 1: Scanned Device */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">IoT Box Status</span>
            <div className="mt-2 flex items-center justify-between">
              <span className="font-mono text-lg font-bold text-slate-800 dark:text-slate-200">
                {deviceId || 'BOX-8800'}
              </span>
              <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-bold text-emerald-600 dark:bg-emerald-950/20 dark:text-emerald-400">
                <RefreshCw className="h-3 w-3 animate-spin" /> Connected
              </span>
            </div>
            <div className="mt-3 text-xs text-slate-400 flex gap-1">
              <span>Last Sync:</span>
              <span className="font-semibold text-slate-600 dark:text-slate-300">Just now</span>
            </div>
          </div>

          {/* Widget 2: Battery Charge */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Device Battery</span>
            <div className="mt-2 flex items-center justify-between">
              <span className="text-2xl font-black text-slate-800 dark:text-slate-200">88%</span>
              <Battery className="h-6 w-6 text-emerald-500 fill-emerald-500/20" />
            </div>
            <div className="mt-3 text-xs text-slate-400">
              Charging Status: <span className="font-semibold text-slate-600 dark:text-slate-300">Not Plugged In</span>
            </div>
          </div>

          {/* Widget 3: Low Stock Warning */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Refill Alerts</span>
            <div className="mt-2 flex items-center justify-between">
              <span className="text-2xl font-black text-slate-800 dark:text-slate-200">{lowStockCount}</span>
              <AlertTriangle className={`h-6 w-6 ${lowStockCount > 0 ? 'text-amber-500 fill-amber-500/20 animate-pulse' : 'text-slate-300'}`} />
            </div>
            <div className="mt-3 text-xs text-slate-400">
              {lowStockCount > 0 ? `${lowStockCount} medications need refills` : 'All stocks satisfied'}
            </div>
          </div>

          {/* Widget 4: Next Refill Date */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Upcoming Refill</span>
            <div className="mt-2 flex items-center justify-between">
              <span className="text-base font-bold text-slate-800 dark:text-slate-200">
                {soonestRefillMed ? soonestRefillMed.estimatedRefillDate : 'N/A'}
              </span>
              <Calendar className="h-6 w-6 text-blue-500" />
            </div>
            <div className="mt-3 text-xs text-slate-400">
              {soonestRefillMed ? `Estimated for ${soonestRefillMed.name}` : 'No active schedules'}
            </div>
          </div>
        </div>

        {/* Dashboard Panels */}
        <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-3">
          
          {/* Left Column: Reminders checklist */}
          <div className="lg:col-span-1 space-y-6">
            <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <h2 className="text-xl font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                <ClipboardList className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                Today&apos;s Reminders
              </h2>
              <p className="mt-1 text-xs text-slate-400">
                Please register your daily intake routine by clicking the taken button.
              </p>

              <div className="mt-6 space-y-4">
                {(() => {
                  const todayStr = new Date().toISOString().split('T')[0];
                  const todayDoses = doseRecords.filter(
                    (r) => r.scheduledDate === todayStr && r.patientId === (patient?.id || 'mock-patient')
                  );

                  if (todayDoses.length === 0) {
                    return <p className="text-center py-8 text-sm text-slate-400">No scheduled doses for today</p>;
                  }

                  return todayDoses.map((record) => {
                    return (
                      <div 
                        key={record.id} 
                        className={`p-4 rounded-2xl border transition-all ${
                          record.status === 'Completed'
                            ? 'border-emerald-100 bg-emerald-50/20 dark:border-emerald-950/40 dark:bg-emerald-950/5'
                            : 'border-slate-100 bg-slate-50/50 dark:border-slate-800 dark:bg-slate-950/20'
                        } space-y-3`}
                      >
                        <div className="flex justify-between items-center">
                          <h4 className="font-bold text-slate-900 dark:text-white capitalize">{record.medicineName}</h4>
                          <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold ${
                            record.status === 'Completed' 
                              ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400' 
                              : record.status === 'Partially Taken' 
                                ? 'bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400'
                                : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-450'
                          }`}>{record.status}</span>
                        </div>
                        
                        <div className="text-xs text-slate-500 space-y-1.5 dark:text-slate-400">
                          <p className="capitalize">Period: <span className="font-semibold text-slate-700 dark:text-slate-300">{record.dosePeriod} Dose ({record.scheduledTime})</span></p>
                          <div className="flex gap-4 pt-1">
                            <span>Scheduled: <strong className="text-slate-700 dark:text-slate-300">{record.scheduledPills}</strong></span>
                            <span>Taken: <strong className="text-emerald-600 dark:text-emerald-400">{record.takenPills}</strong></span>
                            <span>Remaining: <strong className="text-orange-600 dark:text-orange-400">{record.remainingPills}</strong></span>
                          </div>
                        </div>

                        <button
                          disabled={record.takenPills >= record.scheduledPills}
                          onClick={() => takeWebPill(record.id)}
                          className="w-full mt-2 py-2 text-center rounded-xl bg-blue-600 hover:bg-blue-700 disabled:bg-slate-100 disabled:text-slate-400 disabled:cursor-not-allowed text-xs font-bold text-white transition-all active:scale-98 dark:bg-blue-500 dark:hover:bg-blue-600 dark:disabled:bg-slate-850 dark:disabled:text-slate-600"
                        >
                          {record.takenPills >= record.scheduledPills ? 'Completed ✓' : 'Mark 1 Pill Taken'}
                        </button>
                      </div>
                    );
                  });
                })()}
              </div>
            </div>
          </div>

          {/* Right Column: Medications lists */}
          <div className="lg:col-span-2 space-y-6">
            <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              
              {/* Header filters */}
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <h2 className="text-xl font-black tracking-tight text-slate-900 dark:text-white">
                  Active Medications
                </h2>
                
                {/* Search Bar */}
                <div className="relative max-w-xs w-full">
                  <span className="absolute inset-y-0 left-0 flex items-center pl-3">
                    <Search className="h-4 w-4 text-slate-400" />
                  </span>
                  <input
                    type="text"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="Search medications..."
                    className="block w-full rounded-xl border border-slate-200 bg-slate-50 pl-9 pr-3 py-2 text-xs text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
              </div>

              {/* Pill timing filters */}
              <div className="mt-4 flex gap-1.5 overflow-x-auto pb-2">
                {(['all', 'morning', 'afternoon', 'night'] as const).map((mode) => (
                  <button
                    key={mode}
                    onClick={() => setFilterMode(mode)}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold uppercase tracking-wide transition-all ${
                      filterMode === mode
                        ? 'bg-blue-600 text-white dark:bg-blue-500'
                        : 'border border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400 dark:hover:bg-slate-800'
                    }`}
                  >
                    {mode}
                  </button>
                ))}
              </div>

              {/* Medicine Table list */}
              <div className="mt-6 overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-slate-100 dark:border-slate-800 text-xs font-bold text-slate-400 uppercase">
                      <th className="pb-3">Name</th>
                      <th className="pb-3">Dosage</th>
                      <th className="pb-3">Remaining Stock</th>
                      <th className="pb-3">Refill Projection</th>
                      <th className="pb-3 text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredMedicines.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="text-center py-12 text-sm text-slate-400">
                          No matching active medications
                        </td>
                      </tr>
                    ) : (
                      filteredMedicines.map((med) => (
                        <tr key={med.id} className="border-b border-slate-100 last:border-0 dark:border-slate-800 text-sm">
                          <td className="py-4 font-bold text-slate-950 dark:text-white">
                            {med.name}
                          </td>
                          <td className="py-4 text-slate-600 dark:text-slate-350">
                            {med.dosage}
                          </td>
                          <td className="py-4 font-mono font-semibold">
                            {med.remainingTablets} tablets
                          </td>
                          <td className="py-4 text-slate-500 dark:text-slate-400">
                            {med.estimatedRefillDate}
                          </td>
                          <td className="py-4 text-right">
                            {med.remainingTablets < 10 ? (
                              <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-xs font-bold text-amber-600 dark:bg-amber-950/20 dark:text-amber-400">
                                Low Stock
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-bold text-emerald-600 dark:bg-emerald-950/20 dark:text-emerald-400">
                                Satisfied
                              </span>
                            )}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

            </div>
          </div>

        </div>

      </main>

      {/* Add Medication modal widget */}
      <MedicineModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </div>
  );
}
