import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import ProfileView from '../views/ProfileView.vue'
import MarketView from '../views/MarketView.vue'
import RadioView from '../views/RadioView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/login', component: LoginView },
    { path: '/market', component: MarketView },
    { 
      path: '/profile', 
      component: ProfileView,
      meta: { requiresAuth: true }
    },
    { path: '/radio', component: RadioView },
    { path: '/feed', component: { template: '<h1>Feed</h1><p>Coming Soon</p>' } }
  ]
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
