import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export const api = axios.create({
    baseURL: `${API_URL}/api/`,
    headers: {
        'Content-Type': 'application/json',
    },
})

// Interceptor para adicionar token automaticamente
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token')
    if (token) {
        config.headers.Authorization = `Bearer ${token}`
    }
    return config
})

// Interceptor para lidar com erros de autenticação
api.interceptors.response.use(
    (response) => response,
    async (error) => {
        const originalRequest = error.config

        if (error.response?.status === 401 && !originalRequest._retry) {
            originalRequest._retry = true

            try {
                const refreshToken = localStorage.getItem('refreshToken')
                if (refreshToken) {
                    const response = await axios.post(`${API_URL}/api/auth/token/refresh/`, {
                        refresh: refreshToken
                    })

                    const newToken = response.data.access
                    localStorage.setItem('token', newToken)

                    // Retry original request with new token
                    originalRequest.headers.Authorization = `Bearer ${newToken}`
                    return api(originalRequest)
                }
            } catch (refreshError) {
                // Refresh token is invalid, redirect to login
                localStorage.removeItem('token')
                localStorage.removeItem('refreshToken')
                window.location.href = '/login'
            }
        }

        return Promise.reject(error)
    }
)
