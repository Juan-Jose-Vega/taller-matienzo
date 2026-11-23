import { createApp } from 'vue';
import App from './App.vue';
import router from './router/index.js';
import { aplicarTema } from './services/uiService.js';
import { sincronizar } from './services/subscriptionService.js';
import './styles/variables.css'; import './styles/base.css'; import './styles/layout.css'; import './styles/components.css'; import './styles/responsive.css';
aplicarTema(); sincronizar();
createApp(App).use(router).mount('#app');
