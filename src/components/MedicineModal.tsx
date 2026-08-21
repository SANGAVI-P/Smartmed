'use client';

import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { X, Plus, Calendar } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface MedicineModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const MedicineModal: React.FC<MedicineModalProps> = ({ isOpen, onClose }) => {
  const { addMedicine } = useApp();

  const [name, setName] = useState('');
  const [dosage, setDosage] = useState('');
  const [morning, setMorning] = useState(true);
  const [afternoon, setAfternoon] = useState(false);
  const [night, setNight] = useState(false);
  const [beforeFood, setBeforeFood] = useState(false);
  const [startDate, setStartDate] = useState(() => new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(() =>
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
  );
  const [quantity, setQuantity] = useState('30');
  const [pillsPerDose, setPillsPerDose] = useState('1');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !dosage || !quantity || !pillsPerDose) return;

    setLoading(true);
    try {
      await addMedicine({
        name,
        dosage,
        morning,
        afternoon,
        night,
        beforeFood,
        startDate,
        endDate,
        quantity: parseInt(quantity) || 30,
        pillsPerDose: parseInt(pillsPerDose) || 1
      });
      
      // Reset form
      setName('');
      setDosage('');
      setQuantity('30');
      setPillsPerDose('1');
      setMorning(true);
      setAfternoon(false);
      setNight(false);
      setBeforeFood(false);
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop blur clickoff */}
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"
          />

          {/* Modal Card content */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 15 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 15 }}
            className="relative z-10 w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200/80 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900"
          >
            {/* Header */}
            <div className="flex items-center justify-between border-b border-slate-100 pb-4 dark:border-slate-800">
              <h3 className="text-lg font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
                <Plus className="h-5 w-5 text-blue-600 dark:text-blue-500" />
                Add Medication
              </h3>
              <button 
                onClick={onClose}
                className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="mt-6 space-y-5">
              
              {/* Medicine name & dosage */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Medicine Name</label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Metformin"
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Dosage</label>
                  <input
                    type="text"
                    required
                    value={dosage}
                    onChange={(e) => setDosage(e.target.value)}
                    placeholder="500mg"
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
              </div>

              {/* Day Schedule (Morning, Afternoon, Night) */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Intake Schedule</label>
                <div className="mt-3 flex gap-3">
                  <label className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border cursor-pointer text-xs font-bold transition-all ${
                    morning 
                      ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-400' 
                      : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                  }`}>
                    <input type="checkbox" checked={morning} onChange={(e) => setMorning(e.target.checked)} className="hidden" />
                    Morning
                  </label>
                  <label className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border cursor-pointer text-xs font-bold transition-all ${
                    afternoon 
                      ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-400' 
                      : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                  }`}>
                    <input type="checkbox" checked={afternoon} onChange={(e) => setAfternoon(e.target.checked)} className="hidden" />
                    Afternoon
                  </label>
                  <label className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border cursor-pointer text-xs font-bold transition-all ${
                    night 
                      ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-500 dark:text-blue-400' 
                      : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                  }`}>
                    <input type="checkbox" checked={night} onChange={(e) => setNight(e.target.checked)} className="hidden" />
                    Night
                  </label>
                </div>
              </div>

              {/* Food administration rules */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Administration Rule</label>
                <div className="mt-3 flex gap-3">
                  <button
                    type="button"
                    onClick={() => setBeforeFood(true)}
                    className={`flex-1 py-3 rounded-xl border text-xs font-bold transition-all ${
                      beforeFood 
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-600 dark:bg-emerald-950/20 dark:border-emerald-500 dark:text-emerald-400' 
                        : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                    }`}
                  >
                    Before Food
                  </button>
                  <button
                    type="button"
                    onClick={() => setBeforeFood(false)}
                    className={`flex-1 py-3 rounded-xl border text-xs font-bold transition-all ${
                      !beforeFood 
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-600 dark:bg-emerald-950/20 dark:border-emerald-500 dark:text-emerald-400' 
                        : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-400'
                    }`}
                  >
                    After Food
                  </button>
                </div>
              </div>

              {/* Pills per Dose & Total Quantity */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Pills Per Dose</label>
                  <input
                    type="number"
                    required
                    min="1"
                    value={pillsPerDose}
                    onChange={(e) => setPillsPerDose(e.target.value)}
                    placeholder="1"
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Total Quantity (Stock)</label>
                  <input
                    type="number"
                    required
                    min="1"
                    value={quantity}
                    onChange={(e) => setQuantity(e.target.value)}
                    placeholder="30"
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
              </div>

              {/* Start & End Dates */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">Start Date</label>
                  <input
                    type="date"
                    required
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500">End Date</label>
                  <input
                    type="date"
                    required
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-3 text-sm text-slate-900 outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
              </div>

              {/* Action buttons */}
              <div className="mt-8 flex gap-3 border-t border-slate-100 pt-4 dark:border-slate-800">
                <button
                  type="button"
                  onClick={onClose}
                  className="flex-1 py-3 rounded-xl border border-slate-200 text-slate-600 text-sm font-bold hover:bg-slate-50 dark:border-slate-800 dark:text-slate-400 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 py-3 rounded-xl bg-blue-600 text-white text-sm font-bold hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 disabled:opacity-50"
                >
                  {loading ? 'Adding...' : 'Add Medicine'}
                </button>
              </div>

            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
