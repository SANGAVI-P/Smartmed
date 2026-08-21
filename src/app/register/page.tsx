'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Heart, Users, ArrowLeft } from 'lucide-react';
import { motion } from 'framer-motion';

export default function RegisterPage() {
  const router = useRouter();

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-12 transition-colors duration-300 dark:bg-slate-950 sm:px-6 lg:px-8 relative">
      {/* Return Home Button */}
      <Link 
        href="/" 
        className="absolute top-8 left-8 flex items-center gap-1.5 text-sm font-semibold text-slate-500 hover:text-blue-600 transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        Return Home
      </Link>

      <div className="w-full max-w-3xl space-y-8">
        {/* Header Branding */}
        <div className="flex flex-col items-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-600 shadow-lg shadow-blue-500/20 dark:bg-blue-500">
            <Heart className="h-6 w-6 fill-white stroke-white" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white">
            Create Secure Account
          </h2>
          <p className="mt-2 text-center text-sm text-slate-500 dark:text-slate-400">
            Choose your profile role to configure correct medicine alerts.
          </p>
        </div>

        {/* Outer White Card Container */}
        <motion.div 
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-3xl border border-slate-200/80 bg-white p-8 shadow-xl shadow-slate-100/50 dark:border-slate-800 dark:bg-slate-900 dark:shadow-none"
        >
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            
            {/* Patient Profile Card */}
            <motion.div
              whileHover={{ scale: 1.025 }}
              onClick={() => router.push('/register-patient')}
              className="group cursor-pointer rounded-2xl border border-slate-100 bg-slate-50/50 p-6 text-left transition-all hover:border-blue-500 hover:bg-white dark:border-slate-800 dark:bg-slate-950/20 dark:hover:border-blue-500 dark:hover:bg-slate-900"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white transition-all dark:bg-blue-950/30 dark:text-blue-400">
                <Heart className="h-6 w-6" />
              </div>
              <h3 className="mt-6 text-lg font-bold text-slate-900 dark:text-white">
                Patient Profile
              </h3>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                I want to manage my own medicines and verify my adherence schedule.
              </p>
            </motion.div>

            {/* Caregiver Profile Card */}
            <motion.div
              whileHover={{ scale: 1.025 }}
              onClick={() => router.push('/register-caregiver')}
              className="group cursor-pointer rounded-2xl border border-slate-100 bg-slate-50/50 p-6 text-left transition-all hover:border-emerald-500 hover:bg-white dark:border-slate-800 dark:bg-slate-950/20 dark:hover:border-emerald-500 dark:hover:bg-slate-900"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white transition-all dark:bg-emerald-950/30 dark:text-emerald-400">
                <Users className="h-6 w-6" />
              </div>
              <h3 className="mt-6 text-lg font-bold text-slate-900 dark:text-white">
                Caregiver Profile
              </h3>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                I want to monitor and assist a patient remotely and receive medicine alerts.
              </p>
            </motion.div>

          </div>
        </motion.div>

        {/* Footer */}
        <p className="text-center text-sm text-slate-500 dark:text-slate-400">
          Already registered?{' '}
          <Link href="/login" className="font-bold text-blue-600 hover:underline dark:text-blue-400">
            Log In to Portal
          </Link>
        </p>
      </div>
    </div>
  );
}
