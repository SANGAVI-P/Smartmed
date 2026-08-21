'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useApp } from '../context/AppContext';
import { 
  Heart, 
  Menu, 
  X, 
  Sun, 
  Moon, 
  LayoutDashboard, 
  User, 
  Settings, 
  LogOut,
  Bell,
  FileText
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export const Navbar: React.FC = () => {
  const { theme, setTheme, user, userRole, logout, notifications, clearNotifications } = useApp();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [notifDropdownOpen, setNotifDropdownOpen] = useState(false);
  const pathname = usePathname();

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light');
  };

  const unreadNotifsCount = notifications.filter(n => !n.read).length;

  const dashboardRoute = userRole === 'caregiver' || userRole === 'admin'
    ? '/caregiver-dashboard'
    : '/patient-dashboard';

  const menuItems = user ? [
    { name: 'Dashboard', path: dashboardRoute, icon: LayoutDashboard },
    { name: 'Prescriptions', path: '/prescriptions', icon: FileText },
    { name: 'Profile', path: '/profile', icon: User },
    { name: 'Settings', path: '/settings', icon: Settings },
  ] : [
    { name: 'Home', path: '/', icon: Heart },
  ];

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-slate-200/80 bg-white/90 backdrop-blur-md transition-colors duration-300 dark:border-slate-800/80 dark:bg-slate-900/90">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center gap-2.5">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-600 shadow-md shadow-blue-500/20 dark:bg-blue-500">
                <Heart className="h-5.5 w-5.5 fill-white stroke-white" />
              </div>
              <span className="text-xl font-black tracking-tight text-slate-900 dark:text-white">
                Smart<span className="text-emerald-500">Med</span>
              </span>
            </Link>
          </div>

          {/* Desktop Nav Items */}
          <div className="hidden md:flex items-center gap-6">
            {menuItems.map((item) => (
              <Link
                key={item.name}
                href={item.path}
                className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-semibold transition-colors duration-200 ${
                  pathname === item.path
                    ? 'text-blue-600 bg-blue-50/50 dark:text-blue-400 dark:bg-blue-950/20'
                    : 'text-slate-600 hover:text-blue-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:text-blue-400 dark:hover:bg-slate-800/40'
                }`}
              >
                <item.icon className="h-4 w-4" />
                {item.name}
              </Link>
            ))}

            {/* Notification bell and profile dropdown */}
            {user && (
              <div className="relative">
                <button
                  onClick={() => setNotifDropdownOpen(!notifDropdownOpen)}
                  className="relative p-2 rounded-lg text-slate-600 hover:text-blue-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:text-blue-400 dark:hover:bg-slate-800/40"
                >
                  <Bell className="h-5 w-5" />
                  {unreadNotifsCount > 0 && (
                    <span className="absolute top-1.5 right-1.5 flex h-2 w-2 rounded-full bg-rose-500 ring-2 ring-white dark:ring-slate-900" />
                  )}
                </button>

                {/* Notifications dropdown list */}
                <AnimatePresence>
                  {notifDropdownOpen && (
                    <>
                      <div className="fixed inset-0 z-10" onClick={() => setNotifDropdownOpen(false)} />
                      <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 10 }}
                        className="absolute right-0 mt-2 z-20 w-80 rounded-2xl border border-slate-100 bg-white p-4 shadow-xl dark:border-slate-800 dark:bg-slate-800"
                      >
                        <div className="flex items-center justify-between border-b border-slate-100 pb-2 dark:border-slate-700">
                          <h4 className="font-bold text-slate-900 dark:text-white">Alerts</h4>
                          {unreadNotifsCount > 0 && (
                            <button
                              onClick={clearNotifications}
                              className="text-xs font-semibold text-blue-600 dark:text-blue-400 hover:underline"
                            >
                              Mark all read
                            </button>
                          )}
                        </div>
                        <div className="mt-3 max-h-60 overflow-y-auto space-y-2">
                          {notifications.length === 0 ? (
                            <p className="text-center text-xs py-4 text-slate-400 dark:text-slate-500">No active alerts</p>
                          ) : (
                            notifications.map((notif) => (
                              <div
                                key={notif.id}
                                className={`p-2.5 rounded-lg border text-xs transition-colors ${
                                  notif.read
                                    ? 'bg-white border-slate-100 dark:bg-slate-800 dark:border-slate-700'
                                    : 'bg-blue-50/20 border-blue-100/50 dark:bg-blue-950/10 dark:border-blue-900/30'
                                }`}
                              >
                                <p className="font-semibold text-slate-800 dark:text-slate-200">{notif.message}</p>
                                <span className="text-[10px] text-slate-400 dark:text-slate-500 mt-1 block">{notif.timestamp}</span>
                              </div>
                            ))
                          )}
                        </div>
                      </motion.div>
                    </>
                  )}
                </AnimatePresence>
              </div>
            )}

            {/* Dark Mode Switch */}
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-600 hover:text-blue-600 hover:bg-slate-100 dark:border-slate-800 dark:bg-slate-800/50 dark:text-slate-300 dark:hover:text-blue-400 dark:hover:bg-slate-800"
            >
              {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
            </button>

            {/* Guest Actions or Logout */}
            {user ? (
              <button
                onClick={logout}
                className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-semibold text-rose-600 hover:bg-rose-50 dark:text-rose-400 dark:hover:bg-rose-950/20 transition-all"
              >
                <LogOut className="h-4 w-4" />
                Logout
              </button>
            ) : (
              <Link
                href="/login"
                className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-md shadow-blue-500/10 transition-all hover:bg-blue-700 hover:shadow-lg hover:shadow-blue-500/25 active:scale-95 dark:bg-blue-500 dark:hover:bg-blue-600"
              >
                Sign In
              </Link>
            )}
          </div>

          {/* Hamburguer menu button (mobile) */}
          <div className="flex items-center gap-4 md:hidden">
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg text-slate-600 dark:text-slate-300"
            >
              {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
            </button>
            
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-800/40"
            >
              {mobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden border-t border-slate-200 bg-white py-4 dark:border-slate-800 dark:bg-slate-900"
          >
            <div className="flex flex-col gap-2 px-4">
              {menuItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.path}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-base font-semibold ${
                    pathname === item.path
                      ? 'text-blue-600 bg-blue-50/50 dark:text-blue-400 dark:bg-blue-950/20'
                      : 'text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-800/40'
                  }`}
                >
                  <item.icon className="h-5 w-5" />
                  {item.name}
                </Link>
              ))}

              {user ? (
                <button
                  onClick={() => {
                    logout();
                    setMobileMenuOpen(false);
                  }}
                  className="flex items-center gap-2 px-3 py-2.5 rounded-xl text-base font-semibold text-rose-600 hover:bg-rose-50 dark:text-rose-400 dark:hover:bg-rose-950/20"
                >
                  <LogOut className="h-5 w-5" />
                  Logout
                </button>
              ) : (
                <Link
                  href="/login"
                  onClick={() => setMobileMenuOpen(false)}
                  className="mt-2 flex w-full justify-center rounded-xl bg-blue-600 py-3 text-base font-bold text-white dark:bg-blue-500"
                >
                  Sign In
                </Link>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
};
