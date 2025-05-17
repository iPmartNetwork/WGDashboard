import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { hasRole } from './utils/auth';
import LiveGraphs from './components/LiveGraphs';
import Dashboard from './components/Dashboard';
import Login from './components/Login';
import NotFound from './components/NotFound';
import { useAuth } from './hooks/useAuth';

function App() {
  const { currentUser } = useAuth();

  return (
    <Router>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/login" element={<Login />} />
        <Route path="/live-graphs" element={
          hasRole(currentUser, 'admin') || hasRole(currentUser, 'superadmin')
            ? <LiveGraphs />
            : <div>دسترسی ندارید</div>
        } />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Router>
  );
}

export default App;