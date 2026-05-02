<script>
  import { supabase } from '../lib/supabaseClient.js';
  import './Auth.css';
  import kapisg from '../assets/kapisg.png';
  import vexalBg from '../assets/vexal.png';
  import { onMount } from 'svelte';

  let isLogin = true;
  let isForgotPassword = false;
  let email = '';
  let password = '';
  let confirmPassword = '';
  let displayName = '';
  let error = '';
  let loading = false;
  const BASE_URL = import.meta.env.BASE_URL || '/';

  function toAppPath(path) {
    const base = BASE_URL.endsWith('/') ? BASE_URL.slice(0, -1) : BASE_URL;
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    return base ? `${base}${normalizedPath}` : normalizedPath;
  }
  // Spanish-only labels
  const t = {
    auth: {
      title: 'Bienvenido',
      subtitle: 'Inicia sesión o crea una cuenta',
      loginTab: 'Iniciar sesión',
      signupTab: 'Registrarse',
      fullName: 'Nombre completo',
      fullNamePlaceholder: 'Tu nombre completo',
      email: 'Correo electrónico',
      emailPlaceholder: 'tu@ejemplo.com',
      password: 'Contraseña',
      passwordPlaceholder: 'Contraseña',
      confirmPassword: 'Confirmar contraseña',
      confirmPasswordPlaceholder: 'Repite la contraseña',
      loginButton: 'Entrar',
      signupButton: 'Crear cuenta',
      forgotPassword: '¿Olvidaste tu contraseña?',
      noAccount: '¿No tienes cuenta?',
      signupHere: 'Regístrate',
      hasAccount: '¿Ya tienes cuenta?',
      loginHere: 'Inicia sesión',
      loading: 'Procesando...',
      sendResetLink: 'Enviar enlace de restablecimiento',
      resetPasswordTitle: 'Restablecer contraseña',
      resetPasswordSubtitle: 'Introduce tu correo para recibir instrucciones',
      resetEmailSent: 'Si existe la cuenta, se ha enviado un correo con instrucciones.',
      signupSuccess: 'Registro exitoso. Revisa tu correo para confirmar.',
      errors: {
        loginRequired: 'Ingresa correo y contraseña.',
        signupRequired: 'Completa correo, contraseña y nombre.',
        passwordMismatch: 'Las contraseñas no coinciden.',
        nameRequired: 'Ingresa tu nombre completo.',
        loginError: 'Error al iniciar sesión.',
        signupError: 'Error al registrarse.',
        unexpectedError: 'Ocurrió un error inesperado.'
      }
    }
  };
  function toggleMode() { isLogin = !isLogin; isForgotPassword = false; error = ''; password = ''; confirmPassword = ''; }
  function toggleForgotPassword() { isForgotPassword = !isForgotPassword; error = ''; password = ''; confirmPassword = ''; }


  async function handleResetPassword() {
    error = '';
    if (!email) { error = t.auth.errors.loginRequired; return; }
    loading = true;
    try {
      if (supabase.auth.resetPasswordForEmail) {
        const { data, error: err } = await supabase.auth.resetPasswordForEmail(email);
        if (err) error = err.message;
        else alert(t.auth.resetEmailSent);
        isForgotPassword = false;
      } else {
        const { error: err } = await supabase.auth.api.resetPasswordForEmail?.(email) || { error: null };
        if (err) error = err.message;
        else alert(t.auth.resetEmailSent);
      }
    } catch (e) { error = t.auth.errors.unexpectedError; console.error(e); } finally { loading = false; }
  }

  async function handleSubmit() {
    error = '';
    if (!email || (!isForgotPassword && !password)) { error = isLogin ? t.auth.errors.loginRequired : t.auth.errors.signupRequired; return; }
    if (!isLogin && password !== confirmPassword) { error = t.auth.errors.passwordMismatch; return; }
    if (!isLogin && !displayName.trim()) { error = t.auth.errors.nameRequired; return; }

    loading = true;
    try {
      if (isLogin) {
        const { data, error: err } = await supabase.auth.signInWithPassword({ email, password });
        if (err) {
          error = err.message || t.auth.errors.loginError;
        } else {
          // authenticated — redirect to dashboard
          window.location.href = toAppPath('/dashboard');
        }
      } else {
        const { data, error: err } = await supabase.auth.signUp({ email, password, options: { data: { full_name: displayName } } });
        if (err) {
          error = err.message || t.auth.errors.signupError;
        } else {
          // if user is returned and session exists, navigate to dashboard; otherwise show success message
          if (data?.user) {
            window.location.href = toAppPath('/dashboard');
          } else {
            alert(t.auth.signupSuccess);
            isLogin = true;
            password = '';
            confirmPassword = '';
          }
        }
      }
    } catch (e) {
      error = t.auth.errors.unexpectedError;
      console.error(e);
    } finally {
      loading = false;
    }
  }

  function handleKeyPress(e) { if (e.key === 'Enter') handleSubmit(); }

  onMount(() => {
      console.log('Auth mounted');
      console.log('Current path:', window.location.pathname);
  });
    
</script>

<div class="auth-container">
  <div class="auth-bg" style="background-image: url({vexalBg})"></div>
  <div class="auth-card">
      <div class="auth-header">
      <div class="auth-header-content">
        <h1 class="auth-title">{t.auth.title}</h1>
        <h2 class="auth-subtitle">{t.auth.subtitle}</h2>
      </div>
    </div>

    <div class="auth-form">
      {#if !isForgotPassword}
        <div class="auth-tabs">
          <button class="auth-tab {isLogin ? 'active' : ''}" on:click={() => { isLogin = true; error = ''; }}>{t.auth.loginTab}</button>
          <button class="auth-tab {!isLogin ? 'active' : ''}" on:click={() => { isLogin = false; error = ''; }}>{t.auth.signupTab}</button>
        </div>
      {:else}
        <div class="auth-reset-header">
          <h3>{t.auth.resetPasswordTitle}</h3>
          <p>{t.auth.resetPasswordSubtitle}</p>
        </div>
      {/if}

      {#if !isLogin}
        <div class="form-group">
          <label for="displayName">{t.auth.fullName}</label>
          <input type="text" id="displayName" bind:value={displayName} placeholder={t.auth.fullNamePlaceholder} on:keypress={handleKeyPress} disabled={loading} />
        </div>
      {/if}

      <div class="form-group">
        <label for="email">{t.auth.email}</label>
        <input type="email" id="email" bind:value={email} placeholder={t.auth.emailPlaceholder} on:keypress={handleKeyPress} disabled={loading} />
      </div>

      <div class="form-group">
        <label for="password">{t.auth.password}</label>
        <input type="password" id="password" bind:value={password} placeholder={t.auth.passwordPlaceholder} on:keypress={handleKeyPress} disabled={loading} />
      </div>

      {#if !isLogin}
        <div class="form-group">
          <label for="confirmPassword">{t.auth.confirmPassword}</label>
          <input type="password" id="confirmPassword" bind:value={confirmPassword} placeholder={t.auth.confirmPasswordPlaceholder} on:keypress={handleKeyPress} disabled={loading} />
        </div>
      {/if}

      {#if error}
        <div class="auth-error">{error}</div>
      {/if}

      <button class="auth-submit" on:click={isForgotPassword ? handleResetPassword : handleSubmit} disabled={loading}>
        {#if loading}{t.auth.loading}{:else if isForgotPassword}{t.auth.sendResetLink}{:else}{isLogin ? t.auth.loginButton : t.auth.signupButton}{/if}
      </button>

      {#if !isForgotPassword}
        {#if isLogin}
          <div class="auth-forgot"><button class="auth-link" on:click={toggleForgotPassword} disabled={loading}>{t.auth.forgotPassword}</button></div>
        {/if}

        <p class="auth-footer">{isLogin ? t.auth.noAccount : t.auth.hasAccount}
          <button class="auth-link" on:click={toggleMode} disabled={loading}>{isLogin ? t.auth.signupHere : t.auth.loginHere}</button>
        </p>
      {:else}
        <p class="auth-footer"><button class="auth-link" on:click={toggleForgotPassword} disabled={loading}>{t.auth.backToLogin || 'Back'}</button></p>
      {/if}
    </div>

    <div class="auth-powered">
      <span>Powered by</span>
      <img src={kapisg} alt="kapisg" />
    </div>
  </div>
</div>
