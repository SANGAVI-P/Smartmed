'use client';

import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Navbar } from '../../components/Navbar';
import { Bell, Moon, Sun, ShieldAlert, CheckCircle, RefreshCw } from 'lucide-react';
import { motion } from 'framer-motion';

export default function SettingsPage() {
  const { theme, setTheme } = useApp();
  
  const [reminders, setReminders] = useState(true);
  const [stockAlerts, setStockAlerts] = useState(true);
  const [emailLogs, setEmailLogs] = useState(false);
  
  const [success, setSuccess] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
  };

  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-300 dark:bg-slate-950">
      <Navbar />

      <main className="mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white">
              System Settings
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Configure notifications, theme preferences, and synchronization guidelines.
            </p>
          </div>

          <motion.div 
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            className="rounded-3xl border border-slate-200/80 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900"
          >
            <form onSubmit={handleSave} className="space-y-8">
              
              {success && (
                <div className="flex items-center gap-2 rounded-xl bg-emerald-50 border border-emerald-100 p-3 text-sm text-emerald-600 dark:bg-emerald-950/20 dark:border-emerald-900/30 dark:text-emerald-400">
                  <CheckCircle className="h-5 w-5 shrink-0" />
                  <span>Preferences saved successfully!</span>
                </div>
              )}

              {/* Theme Preferences */}
              <div className="space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 flex items-center gap-2">
                  <Moon className="h-4.5 w-4.5 text-slate-500" />
                  Theme Preference
                </h3>
                
                <div className="flex gap-4">
                  <button
                    type="button"
                    onClick={() => setTheme('light')}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border text-sm font-bold transition-all ${
                      theme === 'light'
                        ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-550 dark:text-blue-400'
                        : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950'
                    }`}
                  >
                    <Sun className="h-4.5 w-4.5" />
                    Light Theme
                  </button>
                  <button
                    type="button"
                    onClick={() => setTheme('dark')}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border text-sm font-bold transition-all ${
                      theme === 'dark'
                        ? 'bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-950/20 dark:border-blue-550 dark:text-blue-400'
                        : 'border-slate-200 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-950'
                    }`}
                  >
                    <Moon className="h-4.5 w-4.5" />
                    Dark Theme
                  </button>
                </div>
              </div>

              {/* Notification Toggles */}
              <div className="border-t border-slate-100 dark:border-slate-800 pt-6 space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 flex items-center gap-2">
                  <Bell className="h-4.5 w-4.5 text-slate-500" />
                  Alert Notification Preferences
                </h3>

                <div className="space-y-4">
                  {/* Toggle 1 */}
                  <label className="flex items-center justify-between cursor-pointer">
                    <div>
                      <span className="text-sm font-bold text-slate-850 dark:text-slate-200">Daily Intake Reminders</span>
                      <p className="text-xs text-slate-400 mt-0.5">Send alerts when scheduled medicine compartments unlock.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={reminders}
                      onChange={(e) => setReminders(e.target.checked)}
                      className="h-4.5 w-4.5 rounded border-slate-350 text-blue-650"
                    />
                  </label>

                  {/* Toggle 2 */}
                  <label className="flex items-center justify-between cursor-pointer">
                    <div>
                      <span className="text-sm font-bold text-slate-850 dark:text-slate-200">Inventory Low Stock Warnings</span>
                      <p className="text-xs text-slate-400 mt-0.5">Notify when tablets count falls below 10.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={stockAlerts}
                      onChange={(e) => setStockAlerts(e.target.checked)}
                      className="h-4.5 w-4.5 rounded border-slate-350 text-blue-650"
                    />
                  </label>

                  {/* Toggle 3 */}
                  <label className="flex items-center justify-between cursor-pointer">
                    <div>
                      <span className="text-sm font-bold text-slate-850 dark:text-slate-200">Weekly Caregiver Reports</span>
                      <p className="text-xs text-slate-400 mt-0.5">Generate weekly email summaries outlining compliance logs.</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={emailLogs}
                      onChange={(e) => setEmailLogs(e.target.checked)}
                      className="h-4.5 w-4.5 rounded border-slate-350 text-blue-650"
                    />
                  </label>
                </div>
              </div>

              {/* Sync settings */}
              <div className="border-t border-slate-100 dark:border-slate-800 pt-6 space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400 flex items-center gap-2">
                  <RefreshCw className="h-4.5 w-4.5 text-slate-500" />
                  IoT Compartments Sync
                </h3>
                <div className="rounded-2xl bg-blue-50/20 border border-blue-100/50 p-4 dark:bg-blue-950/10 dark:border-blue-900/20">
                  <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
                    By default, medication adjustments automatically compile into standard JSON packages for deployment to the physical dispenser compartment registers over the air.
                  </p>
                </div>
              </div>

              {/* Submit */}
              <div className="flex justify-end pt-4 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="submit"
                  className="rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all dark:bg-blue-500"
                >
                  Save Settings
                </button>
              </div>

            </form>
          </motion.div>
        </div>
      </main>
    </div>
  );
}
