<template>
  <q-page padding>
    <div class="row justify-center">
      <div class="col-12 col-md-8">
        <div class="text-center q-mb-xl">
          <h2 class="text-h3 q-mb-md">Bem-vindo ao ProjTest!</h2>
          <p class="text-h6 text-grey-7">
            Aplicação Decoupled com Django REST Framework + Vue.js + Quasar
          </p>
        </div>

        <div class="row q-gutter-md">
          <div class="col-12 col-md-4">
            <q-card class="full-height">
              <q-card-section>
                <div class="text-h6">🚀 Backend API</div>
              </q-card-section>
              <q-card-section>
                <p>Django REST Framework com PostgreSQL e Redis</p>
              </q-card-section>
              <q-card-actions align="right">
                <q-btn flat color="primary" label="Ver API" target="_blank" href="http://localhost:8000/api/" />
              </q-card-actions>
            </q-card>
          </div>

          <div class="col-12 col-md-4">
            <q-card class="full-height">
              <q-card-section>
                <div class="text-h6">🎨 Frontend</div>
              </q-card-section>
              <q-card-section>
                <p>Vue.js 3 + Quasar Framework para interface moderna</p>
              </q-card-section>
              <q-card-actions align="right">
                <q-btn flat color="primary" label="Componentes" target="_blank" href="https://quasar.dev/" />
              </q-card-actions>
            </q-card>
          </div>

          <div class="col-12 col-md-4">
            <q-card class="full-height">
              <q-card-section>
                <div class="text-h6">📚 Documentação</div>
              </q-card-section>
              <q-card-section>
                <p>Swagger UI e ReDoc para documentação interativa</p>
              </q-card-section>
              <q-card-actions align="right">
                <q-btn flat color="primary" label="Ver Docs" target="_blank" href="http://localhost:8000/api/docs/" />
              </q-card-actions>
            </q-card>
          </div>
        </div>

        <div class="text-center q-mt-xl" v-if="!authStore.isAuthenticated">
          <q-btn 
            color="primary" 
            size="lg" 
            label="Fazer Login" 
            to="/login"
            icon="login"
          />
        </div>

        <div class="text-center q-mt-xl" v-else>
          <q-btn 
            color="primary" 
            size="lg" 
            label="Ir para Dashboard" 
            to="/dashboard"
            icon="dashboard"
          />
        </div>
      </div>
    </div>
  </q-page>
</template>

<script>
import { useAuthStore } from '../stores/auth'

export default {
  name: 'HomePage',
  setup() {
    const authStore = useAuthStore()

    return {
      authStore
    }
  }
}
</script>
