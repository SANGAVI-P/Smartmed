'use client';

import React from 'react';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer 
} from 'recharts';

const mockChartData = [
  { day: 'Mon', rate: 80 },
  { day: 'Tue', rate: 90 },
  { day: 'Wed', rate: 85 },
  { day: 'Thu', rate: 100 },
  { day: 'Fri', rate: 70 },
  { day: 'Sat', rate: 90 },
  { day: 'Sun', rate: 95 },
];

export const DashboardChart: React.FC = () => {
  return (
    <div className="w-full h-80 pt-4">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart
          data={mockChartData}
          margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
        >
          <defs>
            <linearGradient id="adherenceGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#2563eb" stopOpacity={0.2}/>
              <stop offset="95%" stopColor="#2563eb" stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" className="dark:stroke-slate-800" />
          <XAxis 
            dataKey="day" 
            stroke="#94a3b8" 
            fontSize={11} 
            tickLine={false} 
            axisLine={false} 
          />
          <YAxis 
            stroke="#94a3b8" 
            fontSize={11} 
            tickLine={false} 
            axisLine={false} 
            domain={[0, 100]}
            tickFormatter={(value) => `${value}%`}
          />
          <Tooltip 
            contentStyle={{ 
              backgroundColor: '#1e293b', 
              border: 'none', 
              borderRadius: '12px',
              color: '#fff',
              fontSize: '12px',
              fontFamily: 'Inter, sans-serif'
            }}
            formatter={(value: any) => [`${value}% Adherence`, 'Rate']}
            labelFormatter={(label) => `Day: ${label}`}
          />
          <Area 
            type="monotone" 
            dataKey="rate" 
            stroke="#2563eb" 
            strokeWidth={3} 
            fillOpacity={1} 
            fill="url(#adherenceGrad)" 
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};
export default DashboardChart;
