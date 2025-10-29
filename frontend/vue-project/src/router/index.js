import { createRouter, createWebHistory } from 'vue-router'
import LandingPage from '../views/LandingPage.vue'
import ProfileSetup from '../views/ProfileSetup.vue'
import GameLobby from '../views/GameLobby.vue'

const routes = [
  {
    path: '/',
    name: 'Landing',
    component: LandingPage
  },
  {
    path: '/setup',
    name: 'ProfileSetup',
    component: ProfileSetup
  },
  {
    path: '/lobby',
    name: 'GameLobby',
    component: GameLobby
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 暫時註解掉路由守衛，測試是否能正常跳轉
/*
router.beforeEach((to, from, next) => {
  const isAuthenticated = localStorage.getItem('authToken')
  
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({ name: 'Landing' })
  } else if (to.name === 'Landing' && isAuthenticated) {
    next({ name: 'GameLobby' })
  } else {
    next()
  }
})
*/

export default router
