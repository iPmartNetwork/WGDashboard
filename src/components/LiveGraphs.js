import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';

const LiveGraphs = () => {
  const [bandwidthData, setBandwidthData] = useState([]);
  const [serverStatus, setServerStatus] = useState([]);

  useEffect(() => {
    const interval = setInterval(() => {
      fetch('/api/monitor/bandwidth')
        .then(res => res.json())
        .then(data => setBandwidthData(data));
      fetch('/api/monitor/server-status')
        .then(res => res.json())
        .then(data => setServerStatus(data));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <h2>گراف زنده مصرف پهنای‌باند</h2>
      <Line data={{
        labels: bandwidthData.map(d => d.time),
        datasets: [{
          label: 'پهنای‌باند (Mbps)',
          data: bandwidthData.map(d => d.value),
          borderColor: 'blue',
          fill: false,
        }]
      }} />
      <h2>وضعیت سرور</h2>
      <Line data={{
        labels: serverStatus.map(d => d.time),
        datasets: [{
          label: 'CPU (%)',
          data: serverStatus.map(d => d.cpu),
          borderColor: 'green',
          fill: false,
        }, {
          label: 'RAM (%)',
          data: serverStatus.map(d => d.ram),
          borderColor: 'red',
          fill: false,
        }]
      }} />
    </div>
  );
};

export default LiveGraphs;

// ...existing code...
