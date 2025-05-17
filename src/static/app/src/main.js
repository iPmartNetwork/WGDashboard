import './css/dashboard.css'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap/dist/js/bootstrap.js'
import 'bootstrap-icons/font/bootstrap-icons.css'
import 'animate.css/animate.compat.css'
import '@vuepic/vue-datepicker/dist/main.css'
import {createApp, markRaw} from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router/router.js'
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
let Locale;
await fetch("/api/locale")
	.then(res => res.json())
	.then(res => Locale = res.data)
	.catch(() => {
		Locale = null
	})
const app = createApp(App)
app.use(router)
const pinia = createPinia();

pinia.use(({ store }) => {
	store.$router = markRaw(router)
})
pinia.use(piniaPluginPersistedstate)

app.use(pinia)
const store = DashboardConfigurationStore()
store.Locale = Locale;
app.mount('#app')