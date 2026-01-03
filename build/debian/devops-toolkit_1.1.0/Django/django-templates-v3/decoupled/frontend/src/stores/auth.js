import { defineStore } from 'pinia'
import { api } from '../services/api'

export const useAuthStore = defineStore('auth', {
    state: () => ({
        user: null,
        token: localStorage.getItem('token'),
        refreshToken: localStorage.getItem('refreshToken')
    }),

    getters: {
        isAuthenticated: (state) => !!state.token,
    },

    actions: {
        async login(username, password) {
            try {
                const response = await api.post('/auth/token/', {
                    username,
                    password
                })

                this.token = response.data.access
                this.refreshToken = response.data.refresh

                localStorage.setItem('token', this.token)
                localStorage.setItem('refreshToken', this.refreshToken)

                // Configurar token no axios
                api.defaults.headers.common['Authorization'] = `Bearer ${this.token}`

                // Buscar dados do usuário
                await this.fetchUser()

                return response.data
            } catch (error) {
                throw error
            }
        },

        async fetchUser() {
            try {
                const response = await api.get('/users/me/')
                this.user = response.data
                return response.data
            } catch (error) {
                console.error('Erro ao buscar usuário:', error)
                throw error
            }
        },

        async refreshAccessToken() {
            try {
                const response = await api.post('/auth/token/refresh/', {
                    refresh: this.refreshToken
                })

                this.token = response.data.access
                localStorage.setItem('token', this.token)
                api.defaults.headers.common['Authorization'] = `Bearer ${this.token}`

                return response.data
            } catch (error) {
                this.logout()
                throw error
            }
        },

        logout() {
            this.user = null
            this.token = null
            this.refreshToken = null

            localStorage.removeItem('token')
            localStorage.removeItem('refreshToken')
            delete api.defaults.headers.common['Authorization']
        },

        // Inicializar autenticação ao carregar a aplicação
        async initAuth() {
            if (this.token) {
                api.defaults.headers.common['Authorization'] = `Bearer ${this.token}`
                try {
                    await this.fetchUser()
                } catch (error) {
                    // Token pode estar expirado, tentar refresh
                    if (this.refreshToken) {
                        try {
                            await this.refreshAccessToken()
                            await this.fetchUser()
                        } catch (refreshError) {
                            this.logout()
                        }
                    } else {
                        this.logout()
                    }
                }
            }
        }
    }
})
