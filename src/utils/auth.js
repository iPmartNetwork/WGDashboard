import jwtDecode from 'jwt-decode';

const TOKEN_KEY = 'jwtToken';

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function removeToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export function getUserFromToken() {
  const token = getToken();
  if (!token) return null;

  try {
    return jwtDecode(token);
  } catch (error) {
    console.error('Invalid token:', error);
    return null;
  }
}

export function isAuthenticated() {
  return !!getToken();
}

export function hasRole(user, role) {
  return user && user.role === role;
}