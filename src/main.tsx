import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './auth/AuthProvider';
import { ErrorBoundary } from './app/ErrorBoundary';
import { AppRoutes } from './routes/AppRoutes';
import './styles.css';
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><ErrorBoundary><AuthProvider><BrowserRouter><AppRoutes/></BrowserRouter></AuthProvider></ErrorBoundary></React.StrictMode>);
