'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useApp } from '../../../context/AppContext';
import { Heart, Loader2, ShieldCheck, HelpCircle } from 'lucide-react';
import { motion } from 'framer-motion';

export default function DeviceQRPage() {
  const params = useParams();
  const router = useRouter();
  const { setDeviceId, patient } = useApp();
  const [status, setStatus] = useState<'checking' | 'found' | 'not-found'>('checking');
  const deviceId = params?.deviceId as string;

  useEffect(() => {
    if (!deviceId) return;

    // Set scanned device ID in context
    setDeviceId(deviceId);

    // Simulate database lookup check (1.8s delay for scanning animation feel)
    const timer = setTimeout(() => {
      const storedPatientRaw = localStorage.getItem('sm-patient');
      const storedPatient = storedPatientRaw ? JSON.parse(storedPatientRaw) : null;
      
      // If patient exists and device IDs match
      if (storedPatient && storedPatient.deviceId === deviceId) {
        setStatus('found');
        setTimeout(() => {
          router.push('/patient-dashboard');
        }, 1200);
      } else {
        setStatus('not-found');
        setTimeout(() => {
          router.push('/register-patient');
        }, 1500);
      }
    }, 1800);

    return () => clearTimeout(timer);
  }, [deviceId, router, setDeviceId]);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 px-4 text-center transition-colors duration-300 dark:bg-slate-950">
      <div className="w-full max-w-md space-y-8">
        
        {/* Animated Scanner Ring */}
        <div className="relative flex justify-center items-center">
          <motion.div 
            animate={{ scale: [1, 1.25, 1], opacity: [0.15, 0.4, 0.15] }}
            transition={{ repeat: Infinity, duration: 2 }}
            className="absolute h-40 w-40 rounded-full bg-blue-500/20"
          />
          <motion.div 
            animate={{ scale: [1, 1.15, 1], opacity: [0.3, 0.6, 0.3] }}
            transition={{ repeat: Infinity, duration: 2, delay: 0.5 }}
            className="absolute h-32 w-32 rounded-full bg-blue-500/10"
          />
          <div className="relative flex h-24 w-24 items-center justify-center rounded-3xl bg-white shadow-xl shadow-blue-500/10 dark:bg-slate-900 border border-slate-100 dark:border-slate-800">
            {status === 'checking' && (
              <Loader2 className="h-10 w-10 text-blue-600 dark:text-blue-500 animate-spin" />
            )}
            {status === 'found' && (
              <ShieldCheck className="h-12 w-12 text-emerald-600 dark:text-emerald-500" />
            )}
            {status === 'not-found' && (
              <HelpCircle className="h-12 w-12 text-blue-600 dark:text-blue-500" />
            )}
          </div>
        </div>

        {/* Text Details */}
        <div className="space-y-3">
          <h2 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">
            SmartMed IoT Link
          </h2>
          <div className="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-3 py-1 text-sm font-bold text-slate-800 dark:bg-slate-900 dark:text-slate-200">
            Device ID: <span className="font-mono text-blue-600 dark:text-blue-400">{deviceId || 'BOX-8800'}</span>
          </div>

          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-xs mx-auto">
            {status === 'checking' && 'Verifying dispenser registration status...'}
            {status === 'found' && 'Device registered. Loading patient dashboard...'}
            {status === 'not-found' && 'New dispenser detected. Loading registration profile...'}
          </p>
        </div>

        {/* Footer info */}
        <div className="flex justify-center gap-2 items-center text-xs text-slate-400">
          <Heart className="h-3.5 w-3.5 fill-red-400 stroke-red-400" />
          <span>SmartMed IoT Protocol v1.2</span>
        </div>

      </div>
    </div>
  );
}
