'use client';

import React from 'react';
import Link from 'next/link';
import { Navbar } from '../components/Navbar';
import { motion } from 'framer-motion';
import { 
  ShieldCheck, 
  Smartphone, 
  Users, 
  BellRing, 
  CalendarClock, 
  ArrowRight,
  Sparkles,
  Database
} from 'lucide-react';

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-slate-50 transition-colors duration-300 dark:bg-slate-950">
      <Navbar />

      {/* Hero Section */}
      <section className="relative overflow-hidden py-20 lg:py-32">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 gap-12 lg:grid-cols-2 lg:items-center">
            
            {/* Left Content */}
            <motion.div 
              initial={{ opacity: 0, x: -30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="flex flex-col text-left"
            >
              <div className="inline-flex max-w-max items-center gap-1.5 rounded-full bg-blue-50 px-3.5 py-1.5 text-sm font-bold text-blue-600 dark:bg-blue-950/30 dark:text-blue-400">
                <Sparkles className="h-4 w-4" />
                IoT Adherence Simulation Enabled
              </div>
              <h1 className="mt-6 text-4xl font-extrabold tracking-tight text-slate-900 sm:text-5xl lg:text-6xl dark:text-white leading-[1.1]">
                SmartMed – <br />
                <span className="text-blue-600 dark:text-blue-400">Smart Medicine</span> <br />
                Management System
              </h1>
              <p className="mt-6 text-lg text-slate-600 dark:text-slate-300 leading-relaxed max-w-xl">
                Ensuring elderly patients take the right medicines at the right times, while giving caregivers the tools to monitor adherence remotely and receive critical refills and emergency updates.
              </p>

              <div className="mt-10 flex flex-wrap gap-4">
                <Link
                  href="/login"
                  className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-6 py-3.5 text-base font-bold text-white shadow-lg shadow-blue-500/20 transition-all hover:bg-blue-700 hover:shadow-xl hover:shadow-blue-500/30 active:scale-95 dark:bg-blue-500 dark:hover:bg-blue-600"
                >
                  Get Started
                  <ArrowRight className="h-5 w-5" />
                </Link>
                <Link
                  href="/device/BOX-8800"
                  className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-6 py-3.5 text-base font-bold text-slate-700 transition-all hover:bg-slate-50 hover:text-blue-600 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                >
                  <Database className="h-5 w-5" />
                  Test QR Scan (BOX-8800)
                </Link>
              </div>
            </motion.div>

            {/* Right Animated IoT Illustration */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="relative flex justify-center lg:justify-end"
            >
              <div className="relative w-full max-w-[480px] aspect-square">
                {/* Visual Backdrop Radial Glow */}
                <div className="absolute inset-0 bg-blue-400/20 rounded-full blur-3xl dark:bg-blue-500/10" />

                {/* SVG Illustration Container */}
                <svg viewBox="0 0 400 400" className="w-full h-full relative z-10">
                  {/* Outer waves representing Wi-Fi syncing */}
                  <motion.circle 
                    cx="200" cy="200" r="160" 
                    fill="none" stroke="#2563eb" strokeWidth="1.5" strokeDasharray="5 5" opacity="0.2"
                    animate={{ rotate: 360 }}
                    transition={{ repeat: Infinity, duration: 40, ease: "linear" }}
                  />
                  <motion.circle 
                    cx="200" cy="200" r="130" 
                    fill="none" stroke="#10b981" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.3"
                    animate={{ rotate: -360 }}
                    transition={{ repeat: Infinity, duration: 30, ease: "linear" }}
                  />

                  {/* Connected Signal Lines */}
                  <line x1="120" y1="240" x2="280" y2="160" stroke="#cbd5e1" strokeWidth="2" strokeDasharray="4 4" className="dark:stroke-slate-700" />
                  
                  {/* Smart Pill Box Component */}
                  <g transform="translate(60, 160)">
                    <rect x="0" y="0" width="120" height="120" rx="20" fill="#ffffff" stroke="#e2e8f0" strokeWidth="3" className="shadow-lg dark:fill-slate-900 dark:stroke-slate-800" />
                    <rect x="15" y="15" width="40" height="40" rx="8" fill="#eff6ff" stroke="#bfdbfe" strokeWidth="1" className="dark:fill-slate-800 dark:stroke-slate-700" />
                    <rect x="65" y="15" width="40" height="40" rx="8" fill="#eff6ff" stroke="#bfdbfe" strokeWidth="1" className="dark:fill-slate-800 dark:stroke-slate-700" />
                    <rect x="15" y="65" width="40" height="40" rx="8" fill="#eff6ff" stroke="#bfdbfe" strokeWidth="1" className="dark:fill-slate-800 dark:stroke-slate-700" />
                    <rect x="65" y="65" width="40" height="40" rx="8" fill="#eff6ff" stroke="#bfdbfe" strokeWidth="1" className="dark:fill-slate-800 dark:stroke-slate-700" />
                    
                    {/* Ringing Alarm Indicator */}
                    <motion.circle 
                      cx="35" cy="35" r="10" 
                      fill="#2563eb" opacity="0.2"
                      animate={{ scale: [1, 1.8, 1] }}
                      transition={{ repeat: Infinity, duration: 1.5 }}
                    />
                    <circle cx="35" cy="35" r="5" fill="#2563eb" />
                    
                    {/* IoT Pill box branding logo */}
                    <path d="M 85, 80 A 5 5 0 0 1 85, 90 A 5 5 0 0 1 85, 80" fill="#10b981" />
                    <text x="60" y="112" fill="#94a3b8" fontSize="10" fontWeight="bold" fontFamily="sans-serif">IOT-BOX</text>
                  </g>

                  {/* Connected Smart Phone Component */}
                  <g transform="translate(240, 60)">
                    <rect x="0" y="0" width="100" height="200" rx="16" fill="#0f172a" stroke="#334155" strokeWidth="4" />
                    {/* Phone Screen */}
                    <rect x="6" y="12" width="88" height="176" rx="10" fill="#f8fafc" />
                    
                    {/* Graph Chart Mock inside phone */}
                    <line x1="20" y1="140" x2="80" y2="140" stroke="#cbd5e1" strokeWidth="2" />
                    <path d="M 20 130 Q 40 100 50 115 T 80 80" fill="none" stroke="#2563eb" strokeWidth="3" />
                    
                    {/* Pill reminder alert on phone */}
                    <g transform="translate(14, 25)">
                      <rect width="72" height="40" rx="8" fill="#ffffff" className="shadow-md" />
                      <circle cx="20" cy="20" r="10" fill="#ecfdf5" />
                      <path d="M 17, 20 L 23, 20" stroke="#10b981" strokeWidth="2" />
                      <text x="36" y="18" fill="#0f172a" fontSize="8" fontWeight="bold" fontFamily="sans-serif">Take Pill</text>
                      <text x="36" y="28" fill="#64748b" fontSize="6" fontFamily="sans-serif">Metformin 8AM</text>
                    </g>
                  </g>

                  {/* Wi-Fi Wave Signals */}
                  <motion.path 
                    d="M 190,140 Q 200,130 210,140" 
                    fill="none" stroke="#2563eb" strokeWidth="3" strokeLinecap="round"
                    animate={{ opacity: [0.2, 1, 0.2] }}
                    transition={{ repeat: Infinity, duration: 2 }}
                  />
                  <motion.path 
                    d="M 180,130 Q 200,110 220,130" 
                    fill="none" stroke="#2563eb" strokeWidth="3" strokeLinecap="round"
                    animate={{ opacity: [0.1, 1, 0.1] }}
                    transition={{ repeat: Infinity, duration: 2, delay: 0.3 }}
                  />
                </svg>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Feature Section */}
      <section className="bg-white py-16 dark:bg-slate-900 transition-colors duration-300">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl dark:text-white">
              Revolutionizing Medicine Adherence
            </h2>
            <p className="mx-auto mt-4 max-w-2xl text-base text-slate-500 dark:text-slate-400">
              SmartMed combines a physical smart dispenser with responsive software to deliver worry-free scheduling.
            </p>
          </div>

          <div className="mt-16 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {/* Feature 1 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-8 dark:border-slate-800 dark:bg-slate-950/20">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                <CalendarClock className="h-6 w-6" />
              </div>
              <h3 className="mt-6 text-lg font-bold text-slate-900 dark:text-white">Elderly-Friendly Reminders</h3>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                Clear alerts with simple checkmarks that instantly sync with physical box drawers.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-8 dark:border-slate-800 dark:bg-slate-950/20">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                <Users className="h-6 w-6" />
              </div>
              <h3 className="mt-6 text-lg font-bold text-slate-900 dark:text-white">Remote Caregiver Watch</h3>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                Caregivers check compliance schedules, adherence rates, and logs from their dashboards.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-8 dark:border-slate-800 dark:bg-slate-950/20">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400">
                <BellRing className="h-6 w-6" />
              </div>
              <h3 className="mt-6 text-lg font-bold text-slate-900 dark:text-white">Smart Inventory & Refills</h3>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                Automatic estimation of refill dates and instant alerts when stock drops below critical levels.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Footer */}
      <footer className="border-t border-slate-200 bg-slate-50 py-12 dark:border-slate-800 dark:bg-slate-950 transition-colors duration-300">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6 lg:px-8">
          <p className="text-sm text-slate-400 dark:text-slate-500">
            © {new Date().getFullYear()} SmartMed Healthcare Inc. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
