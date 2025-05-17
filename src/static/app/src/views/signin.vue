<script>
import {fetchGet, fetchPost} from "../utilities/fetch.js";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import Message from "@/components/messageCentreComponent/message.vue";
import RemoteServerList from "@/components/signInComponents/RemoteServerList.vue";
import {GetLocale} from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import SignInInput from "@/components/signIn/signInInput.vue";
import SignInTOTP from "@/components/signIn/signInTOTP.vue";

export default {
	name: "signin",
	components: {SignInTOTP, SignInInput, LocaleText, RemoteServerList, Message},
	async setup(){
		const store = DashboardConfigurationStore()
		let theme = "dark"
		let totpEnabled = false;
		let version = undefined;
		if (!store.IsElectronApp){
			await Promise.all([
				fetchGet("/api/getDashboardTheme", {}, (res) => {
					theme = res.data
				}),
				fetchGet("/api/isTotpEnabled", {}, (res) => {
					totpEnabled = res.data
				}),
				fetchGet("/api/getDashboardVersion", {}, (res) => {
					version = res.data
				})
			]);
		}
		store.removeActiveCrossServer();
		return {store, theme, totpEnabled, version}
	},
	data(){
		return {
			data: {
				username: "",
				password: "",
				totp: "",
			},
			loginError: false,
			loginErrorMessage: "",
			loading: false
		}
	},
	computed: {
		getMessages(){
			return this.store.Messages.filter(x => x.show)
		},
		applyLocale(key){
			return GetLocale(key)
		},
		formValid(){
			return this.data.username && this.data.password && ((this.totpEnabled && this.data.totp) || !this.totpEnabled)
		}
	},
	methods: {
		GetLocale,
		async auth(){
			if (this.formValid){
				this.loading = true
				await fetchPost("/api/authenticate", this.data, (response) => {
					if (response.status){
						this.loginError = false;
						this.$refs["signInBtn"].classList.add("signedIn")
						if (response.message){
							this.$router.push('/welcome')
						}else{
							if (this.store.Redirect !== undefined){
								this.$router.push(this.store.Redirect)
							}else{
								this.$router.push('/')
							}
						}
					}else{
						this.store.newMessage("Server", response.message, "danger")
						document.querySelectorAll("input[required]").forEach(x => {
							x.classList.remove("is-valid")
							x.classList.add("is-invalid")
						});
						this.loading = false
					}
					
				})
			}else{
				document.querySelectorAll("input[required]").forEach(x => {
					if (x.value.length === 0){
						x.classList.remove("is-valid")
						x.classList.add("is-invalid")
					}else{
						x.classList.remove("is-invalid")
						x.classList.add("is-valid")
					}
				});
			}
		}
	}
}
</script>

<template>
	<div class="container-fluid login-container-fluid d-flex main flex-column py-4 text-body h-100 bg-blur"
	     style="overflow-y: scroll"
	     :data-bs-theme="this.theme">
		<div class="login-box m-auto glass-card shadow-lg">
			<div class="m-auto signInContainer px-4 py-5" style="width: 380px;">
				<div class="text-center mb-4">
					<div class="dashboardLogo display-3 mb-2 logo-gradient">
						<i class="bi bi-shield-lock-fill"></i>
					</div>
					<h4 class="mb-0 text-body fw-bold">
						<LocaleText t="Welcome to"></LocaleText>
					</h4>
					<span class="dashboardLogo fs-3 fw-bold text-brand">
						WGDashboard
					</span>
				</div>
				<form @submit="(e) => {e.preventDefault(); this.auth();}"
				      class="mt-3"
				      v-if="!this.store.CrossServerConfiguration.Enable">
					 <div v-if="loginError" class="alert alert-danger py-2 px-3 mb-3 animate__animated animate__fadeIn">
						<i class="bi bi-exclamation-triangle-fill me-2"></i>
						{{ loginErrorMessage || applyLocale('Login failed. Please try again.') }}
					</div>
					<div class="form-floating mb-3 input-icon-group">
						<input type="text"
						       required
						       :disabled="loading"
						       v-model="this.data.username"
						       name="username"
						       autocomplete="username"
						       autofocus
						       class="form-control rounded-4"
						       id="username"
						       placeholder="Username">
						<label for="username" class="d-flex align-items-center">
							<i class="bi bi-person-circle me-2"></i>
							<LocaleText t="Username"></LocaleText>
						</label>
					</div>
					<div class="form-floating mb-3 input-icon-group">
						<input type="password"
						       required
						       :disabled="loading"
						       autocomplete="current-password"
						       v-model="this.data.password"
						       class="form-control rounded-4"
						       id="password"
						       placeholder="Password">
						<label for="password" class="d-flex align-items-center">
							<i class="bi bi-key-fill me-2"></i>
							<LocaleText t="Password"></LocaleText>
						</label>
					</div>
					<div class="form-floating mb-3 input-icon-group" v-if="this.totpEnabled">
						<input type="text"
						       id="totp"
						       required
						       :disabled="loading"
						       placeholder="totp"
						       v-model="this.data.totp"
						       class="form-control rounded-4"
						       maxlength="6"
						       inputmode="numeric"
						       autocomplete="one-time-code">
						<label for="totp" class="d-flex align-items-center">
							<i class="bi bi-lock-fill me-2"></i>
							<LocaleText t="OTP from your authenticator"></LocaleText>
						</label>
					</div>
					<button class="btn btn-lg btn-brand-gradient ms-auto mt-4 w-100 d-flex align-items-center justify-content-center signInBtn rounded-4 shadow"
					        :disabled="this.loading || !this.formValid"
					        ref="signInBtn">
						<span v-if="!this.loading" class="d-flex w-100 align-items-center justify-content-center">
							<LocaleText t="Sign In"></LocaleText>
							<i class="ms-2 bi bi-arrow-right-circle-fill fs-5"></i>
						</span>
						<span v-else class="d-flex w-100 align-items-center justify-content-center">
							<LocaleText t="Signing In..."></LocaleText>
							<span class="spinner-border ms-2 spinner-border-sm" role="status"></span>
						</span>
					</button>
				</form>
				<RemoteServerList v-else></RemoteServerList>
				<div class="d-flex mt-3" v-if="!this.store.IsElectronApp">
					<div class="form-check form-switch ms-auto">
						<input
							v-model="this.store.CrossServerConfiguration.Enable"
							:disabled="loading"
							class="form-check-input" type="checkbox" role="switch" id="flexSwitchCheckChecked">
						<label class="form-check-label" for="flexSwitchCheckChecked">
							<LocaleText t="Access Remote Server"></LocaleText>
						</label>
					</div>
				</div>
			</div>
		</div>
		<small class="text-muted pb-3 d-block w-100 text-center mt-3">
			WGDashboard {{ this.version }} | Developed with ❤️ by 
			<a href="https://github.com/donaldzou" target="_blank"><strong>Donald Zou</strong></a>
		</small>
		<div class="messageCentre text-body position-absolute d-flex">
			<TransitionGroup name="message" tag="div"
			                 class="position-relative flex-sm-grow-0 flex-grow-1 d-flex align-items-end ms-sm-auto flex-column gap-2">
				<Message v-for="m in getMessages.slice().reverse()"
				         :message="m" :key="m.id"></Message>
			</TransitionGroup>
		</div>
	</div>
</template>

<style scoped>
/* Glassmorphism background */
.bg-blur {
	background: linear-gradient(135deg, #232526 0%, #414345 100%);
	min-height: 100vh;
}
.glass-card {
	background: rgba(255,255,255,0.10);
	backdrop-filter: blur(16px) saturate(180%);
	-webkit-backdrop-filter: blur(16px) saturate(180%);
	border-radius: 24px;
	border: 1px solid rgba(255,255,255,0.18);
	box-shadow: 0 8px 32px 0 rgba(31,38,135,0.18);
	transition: box-shadow 0.2s;
}
.glass-card:hover {
	box-shadow: 0 12px 40px 0 rgba(31,38,135,0.25);
}
.logo-gradient {
	background: linear-gradient(90deg, #00c6ff 0%, #0072ff 100%);
	-webkit-background-clip: text;
	-webkit-text-fill-color: transparent;
}
.text-brand {
	color: #0072ff;
}
.btn-brand-gradient {
	background: linear-gradient(90deg, #00c6ff 0%, #0072ff 100%);
	color: #fff;
	border: none;
	transition: background 0.2s, box-shadow 0.2s;
}
.btn-brand-gradient:hover, .btn-brand-gradient:focus {
	background: linear-gradient(90deg, #0072ff 0%, #00c6ff 100%);
	color: #fff;
	box-shadow: 0 4px 16px 0 rgba(0,114,255,0.18);
}
.input-icon-group input {
	padding-left: 2.5rem !important;
}
.input-icon-group label i {
	position: absolute;
	left: 1rem;
	top: 50%;
	transform: translateY(-50%);
	color: #0072ff;
	font-size: 1.2rem;
}
.form-floating > .form-control:focus {
	border-color: #0072ff;
	box-shadow: 0 0 0 0.2rem rgba(0,114,255,0.10);
}
.alert {
	border-radius: 12px;
}
@media screen and (max-width: 768px) {
	.login-box{
		width: 100% !important;
	}
	.signInContainer {
		width: 100% !important;
		padding: 2rem 1rem !important;
	}
}
</style>