'use client';

import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Navbar } from '../../components/Navbar';
import { User, Mail, Phone, MapPin, CheckCircle } from 'lucide-react';
import { motion } from 'framer-motion';

export default function ProfilePage() {
  const { patient, userRole, registerPatient } = useApp();
  
  const [name, setName] = useState(patient?.name || 'Arthur Pendelton');
  const [age, setAge] = useState(patient?.age?.toString() || '78');
  const [phone, setPhone] = useState(patient?.phone || '555-0199');
  const [address, setAddress] = useState(patient?.address || '123 Care Street, Boston MA');
  
  const [success, setSuccess] = useState(false);

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setSuccess(false);

    try {
      const updatedPatient = {
        name,
        age: parseInt(age) || 70,
        gender: patient?.gender || 'Male',
        phone,
        address,
        emergencyContact: patient?.emergencyContact || 'Son: John Doe - 555-0120',
        caregiverName: patient?.caregiverName || 'Sarah Jenkins',
        caregiverPhone: patient?.caregiverPhone || '555-0144',
        medicalConditions: patient?.medicalConditions || 'None',
        allergies: patient?.allergies || 'None',
        deviceId: patient?.deviceId || 'BOX-8800'
      };

      await registerPatient(updatedPatient);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-300 dark:bg-slate-950">
      <Navbar />

      <main className="mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white">
              Profile Settings
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Manage your personal information and contact details.
            </p>
          </div>

          <motion.div 
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            className="rounded-3xl border border-slate-200/80 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900"
          >
            <form onSubmit={handleUpdate} className="space-y-6">
              
              {success && (
                <div className="flex items-center gap-2 rounded-xl bg-emerald-50 border border-emerald-100 p-3 text-sm text-emerald-600 dark:bg-emerald-950/20 dark:border-emerald-900/30 dark:text-emerald-400">
                  <CheckCircle className="h-5 w-5 shrink-0" />
                  <span>Profile updated successfully!</span>
                </div>
              )}

              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                {/* Name */}
                <div>
                  <label className="block text-sm font-bold text-slate-850 dark:text-slate-200">
                    Full Name
                  </label>
                  <div className="relative mt-2">
                    <User className="absolute left-3 top-3.5 h-4.5 w-4.5 text-slate-400" />
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="block w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                    />
                  </div>
                </div>

                {/* Age */}
                <div>
                  <label className="block text-sm font-bold text-slate-850 dark:text-slate-200">
                    Age (Years)
                  </label>
                  <div className="relative mt-2">
                    <input
                      type="number"
                      value={age}
                      onChange={(e) => setAge(e.target.value)}
                      className="block w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                    />
                  </div>
                </div>

                {/* Phone */}
                <div>
                  <label className="block text-sm font-bold text-slate-850 dark:text-slate-200">
                    Phone Number
                  </label>
                  <div className="relative mt-2">
                    <Phone className="absolute left-3 top-3.5 h-4.5 w-4.5 text-slate-400" />
                    <input
                      type="text"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      className="block w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                    />
                  </div>
                </div>

                {/* Role (Read only) */}
                <div>
                  <label className="block text-sm font-bold text-slate-850 dark:text-slate-200">
                    User Profile Type
                  </label>
                  <div className="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-100 px-4 py-3 text-sm text-slate-500 dark:border-slate-800 dark:bg-slate-800 dark:text-slate-400 font-semibold uppercase tracking-wider">
                    {userRole || 'Patient'}
                  </div>
                </div>
              </div>

              {/* Address */}
              <div>
                <label className="block text-sm font-bold text-slate-850 dark:text-slate-200">
                  Home Address
                </label>
                <div className="relative mt-2">
                  <MapPin className="absolute left-3 top-3.5 h-4.5 w-4.5 text-slate-400" />
                  <input
                    type="text"
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    className="block w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm outline-none focus:border-blue-500 focus:bg-white dark:border-slate-800 dark:bg-slate-950 dark:text-white"
                  />
                </div>
              </div>

              {/* Submit */}
              <div className="flex justify-end pt-4">
                <button
                  type="submit"
                  className="rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-md shadow-blue-500/10 hover:bg-blue-700 transition-all dark:bg-blue-500"
                >
                  Save Changes
                </button>
              </div>

            </form>
          </motion.div>
        </div>
      </main>
    </div>
  );
}
