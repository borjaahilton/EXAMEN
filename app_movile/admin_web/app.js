// Configuración Base de API apuntando al servidor Django
const API_BASE = 'http://127.0.0.1:8000';

let authToken = localStorage.getItem('sh_admin_token') || null;
let currentUser = JSON.parse(localStorage.getItem('sh_admin_user') || 'null');
let currentOrders = [];
let currentProducts = [];

// DOM Elements
const loginModal = document.getElementById('login-modal');
const loginForm = document.getElementById('login-form');
const appContainer = document.getElementById('app-container');
const btnLogout = document.getElementById('btn-logout');
const btnRefresh = document.getElementById('btn-refresh');
const navItems = document.querySelectorAll('.nav-item');
const tabPanes = document.querySelectorAll('.tab-pane');
const pendingBadge = document.getElementById('pending-badge');
const filterOrderStatus = document.getElementById('filter-order-status');

// Init
document.addEventListener('DOMContentLoaded', () => {
  if (authToken && currentUser && currentUser.rol === 'admin') {
    showDashboard();
  } else {
    showLogin();
  }

  setupEventListeners();
});

function setupEventListeners() {
  // Login Form
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const submitBtn = document.getElementById('btn-login-submit');

    submitBtn.disabled = true;
    submitBtn.textContent = 'Verificando con Django...';

    try {
      const res = await fetch(`${API_BASE}/auth/login/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail || data.message || 'Credenciales inválidas');
      }

      const rol = data.rol || (data.user && data.user.rol);
      if (rol !== 'admin') {
        throw new Error('Acceso denegado: Esta cuenta no posee rol de Administrador.');
      }

      authToken = data.access || data.token;
      currentUser = {
        id: data.id,
        nombre: (data.first_name ? `${data.first_name} ${data.last_name || ''}`.trim() : null) || data.email,
        email: data.email,
        rol: rol
      };

      localStorage.setItem('sh_admin_token', authToken);
      localStorage.setItem('sh_admin_user', JSON.stringify(currentUser));

      showToast('¡Bienvenido al Panel de Administración!', 'success');
      showDashboard();
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Ingresar al Panel';
    }
  });

  // Logout
  btnLogout.addEventListener('click', () => {
    localStorage.removeItem('sh_admin_token');
    localStorage.removeItem('sh_admin_user');
    authToken = null;
    currentUser = null;
    showToast('Sesión cerrada correctamente.', 'info');
    showLogin();
  });

  // Refresh Button
  btnRefresh.addEventListener('click', () => {
    loadAllData();
    showToast('Datos sincronizados con Django', 'success');
  });

  // Navigation Tabs
  navItems.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.getAttribute('data-tab');
      switchTab(tabId);
    });
  });

  // Filter Orders
  filterOrderStatus.addEventListener('change', () => {
    renderOrders();
  });

  // Product Modal Triggers
  document.getElementById('btn-open-create-product').addEventListener('click', () => {
    openProductModal();
  });

  document.getElementById('form-product').addEventListener('submit', handleProductSubmit);
}

function showLogin() {
  loginModal.classList.add('active');
  appContainer.classList.add('hidden');
}

function showDashboard() {
  loginModal.classList.remove('active');
  appContainer.classList.remove('hidden');

  document.getElementById('user-display-name').textContent = currentUser.nombre;
  document.getElementById('user-display-email').textContent = currentUser.email;
  document.getElementById('user-avatar').textContent = currentUser.nombre.charAt(0).toUpperCase();

  loadAllData();
  // Auto-refresh cada 10 segundos para monitoreo de comandas
  setInterval(loadOrders, 10000);
}

function switchTab(tabId) {
  navItems.forEach(b => b.classList.remove('active'));
  tabPanes.forEach(p => p.classList.remove('active'));

  const activeBtn = document.querySelector(`[data-tab="${tabId}"]`);
  if (activeBtn) activeBtn.classList.add('active');

  const activePane = document.getElementById(tabId);
  if (activePane) activePane.classList.add('active');

  const titles = {
    'tab-dashboard': 'Resumen Operativo',
    'tab-orders': 'Comandas y Pedidos',
    'tab-products': 'Gestión de la Carta'
  };
  document.getElementById('page-title').textContent = titles[tabId] || 'Panel Administrativo';
}

async function loadAllData() {
  await Promise.all([loadOrders(), loadProducts()]);
}

// ----------------------------------------------------------------
// PEDIDOS (ADMIN)
// ----------------------------------------------------------------
async function loadOrders() {
  if (!authToken) return;
  try {
    const res = await fetch(`${API_BASE}/admin/orders/`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    if (res.status === 401 || res.status === 403) {
      btnLogout.click();
      return;
    }

    const data = await res.json();
    currentOrders = Array.isArray(data) ? data : (data.data || data.results || []);
    renderOrders();
    updateDashboardKPIs();
  } catch (err) {
    console.error('Error al cargar pedidos:', err);
  }
}

function renderOrders() {
  const recentTbody = document.getElementById('recent-orders-body');
  const fullTbody = document.getElementById('orders-full-body');
  const filter = filterOrderStatus.value;

  const filteredOrders = filter === 'todos'
    ? currentOrders
    : currentOrders.filter(o => o.estado === filter);

  // Recent Table (Dashboard)
  if (recentTbody) {
    const recent = currentOrders.slice(0, 5);
    if (recent.length === 0) {
      recentTbody.innerHTML = `<tr><td colspan="6" class="text-center text-muted py-4">No hay pedidos registrados aún.</td></tr>`;
    } else {
      recentTbody.innerHTML = recent.map(o => {
        const totalNum = parseFloat(o.total) || 0;
        return `
          <tr>
            <td><strong>#${o.id}</strong></td>
            <td>${escapeHtml(o.cliente_email || 'Cliente')}</td>
            <td><span class="badge">🍽️ Local / Salón</span></td>
            <td><strong>S/. ${totalNum.toFixed(2)}</strong></td>
            <td><span class="status-pill status-${slugify(o.estado)}">${o.estado}</span></td>
            <td>
              <select class="form-select form-select-sm" onchange="changeOrderStatus(${o.id}, this.value)">
                <option value="pendiente" ${o.estado === 'pendiente' ? 'selected' : ''}>Pendiente</option>
                <option value="en preparacion" ${o.estado === 'en preparacion' ? 'selected' : ''}>En preparación</option>
                <option value="listo" ${o.estado === 'listo' ? 'selected' : ''}>Listo</option>
                <option value="entregado" ${o.estado === 'entregado' ? 'selected' : ''}>Entregado</option>
              </select>
            </td>
          </tr>
        `;
      }).join('');
    }
  }

  // Full Orders Table
  if (fullTbody) {
    if (filteredOrders.length === 0) {
      fullTbody.innerHTML = `<tr><td colspan="7" class="text-center text-muted py-4">No hay pedidos con el estado seleccionado.</td></tr>`;
    } else {
      fullTbody.innerHTML = filteredOrders.map(o => {
        const items = o.items || [];
        const itemsList = items.map(i => `${i.cantidad}x ${escapeHtml(i.producto_nombre || 'Plato')} (S/. ${parseFloat(i.subtotal || 0).toFixed(2)})`).join('<br>');
        const fechaFormat = o.fecha ? new Date(o.fecha).toLocaleString('es-PE', { dateStyle: 'short', timeStyle: 'short' }) : '-';
        const totalNum = parseFloat(o.total) || 0;

        return `
          <tr>
            <td><strong>#${o.id}</strong></td>
            <td>
              <strong>${escapeHtml(o.cliente_email || 'Cliente')}</strong>
            </td>
            <td><small>${fechaFormat}</small></td>
            <td>
              <div style="font-size:0.85rem">${itemsList || 'Sin items'}</div>
            </td>
            <td><span class="badge">🍽️ En Local</span></td>
            <td><strong style="color:var(--primary); font-size:1.05rem">S/. ${totalNum.toFixed(2)}</strong></td>
            <td>
              <select class="form-select" onchange="changeOrderStatus(${o.id}, this.value)" style="min-width: 155px; font-weight: 600;">
                <option value="pendiente" ${o.estado === 'pendiente' ? 'selected' : ''}>🟡 Pendiente</option>
                <option value="en preparacion" ${o.estado === 'en preparacion' ? 'selected' : ''}>🔵 En preparación</option>
                <option value="listo" ${o.estado === 'listo' ? 'selected' : ''}>🟣 Listo</option>
                <option value="entregado" ${o.estado === 'entregado' ? 'selected' : ''}>🟢 Entregado</option>
              </select>
            </td>
          </tr>
        `;
      }).join('');
    }
  }
}

async function changeOrderStatus(orderId, newStatus) {
  try {
    const res = await fetch(`${API_BASE}/orders/${orderId}/status/`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({ estado: newStatus })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Error al actualizar el estado en Django');

    showToast(`Comanda #${orderId} actualizada a "${newStatus}"`, 'success');
    loadOrders();
  } catch (err) {
    showToast(err.message, 'error');
    loadOrders();
  }
}

// ----------------------------------------------------------------
// PRODUCTOS
// ----------------------------------------------------------------
async function loadProducts() {
  try {
    const res = await fetch(`${API_BASE}/products/`);
    const data = await res.json();
    currentProducts = Array.isArray(data) ? data : (data.data || data.results || []);
    renderProducts();
    updateDashboardKPIs();
  } catch (err) {
    console.error('Error al cargar productos:', err);
  }
}

function renderProducts() {
  const tbody = document.getElementById('products-table-body');
  if (!tbody) return;

  if (currentProducts.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center text-muted py-4">No hay platos registrados en la carta.</td></tr>`;
    return;
  }

  tbody.innerHTML = currentProducts.map(p => {
    const precioNum = parseFloat(p.precio) || 0;
    return `
      <tr>
        <td>
          <img src="${p.imagen_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=120&q=80'}" class="prod-thumb" alt="${escapeHtml(p.nombre)}">
        </td>
        <td><strong>${escapeHtml(p.nombre)}</strong></td>
        <td style="max-width: 280px; font-size: 0.85rem;" class="text-muted">${escapeHtml(p.descripcion || '-')}</td>
        <td><strong>S/. ${precioNum.toFixed(2)}</strong></td>
        <td>
          <span class="${p.disponible ? 'status-badge-active' : 'status-badge-inactive'}">
            ${p.disponible ? '🟢 Disponible' : '🔴 Agotado'}
          </span>
        </td>
        <td>
          <div style="display:flex; gap:6px;">
            <button class="btn btn-secondary btn-sm" onclick="toggleProductAvailability(${p.id}, ${!p.disponible})">
              ${p.disponible ? 'Agotado' : 'Habilitar'}
            </button>
            <button class="btn btn-primary btn-sm" onclick="editProductPrompt(${p.id})">
              ✏️ Precio
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

async function toggleProductAvailability(productId, newStatus) {
  try {
    const res = await fetch(`${API_BASE}/products/${productId}/`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({ disponible: newStatus })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Error al cambiar disponibilidad');

    showToast(`Plato ${newStatus ? 'habilitado' : 'marcado como agotado'}`, 'success');
    loadProducts();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function editProductPrompt(productId) {
  const prod = currentProducts.find(p => p.id === productId);
  if (!prod) return;

  const currentPrice = parseFloat(prod.precio) || 0;
  const newPriceStr = prompt(`Nuevo precio para "${prod.nombre}" (S/.):`, currentPrice.toFixed(2));
  if (!newPriceStr) return;

  const newPrice = parseFloat(newPriceStr);
  if (isNaN(newPrice) || newPrice <= 0) {
    showToast('Por favor ingrese un precio numérico válido mayor a 0', 'error');
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/products/${productId}/`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({ precio: newPrice })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Error al actualizar precio');

    showToast(`Precio actualizado a S/. ${newPrice.toFixed(2)}`, 'success');
    loadProducts();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function openProductModal() {
  document.getElementById('form-product').reset();
  document.getElementById('prod-id').value = '';
  document.getElementById('modal-product').classList.add('active');
}

function closeProductModal() {
  document.getElementById('modal-product').classList.remove('active');
}

async function handleProductSubmit(e) {
  e.preventDefault();
  const nombre = document.getElementById('prod-name').value.trim();
  const descripcion = document.getElementById('prod-desc').value.trim();
  const precio = parseFloat(document.getElementById('prod-price').value);
  const disponible = document.getElementById('prod-available').value === 'true';
  const imagen_url = document.getElementById('prod-image').value.trim() || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80';

  if (!nombre || isNaN(precio) || precio <= 0) {
    showToast('Complete los campos obligatorios con valores válidos', 'error');
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/products/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({ nombre, descripcion, precio, disponible, imagen_url })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Error al crear producto');

    showToast(`Plato "${nombre}" agregado a la carta exitosamente`, 'success');
    closeProductModal();
    loadProducts();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ----------------------------------------------------------------
// KPIs Y RESUMEN
// ----------------------------------------------------------------
function updateDashboardKPIs() {
  const pending = currentOrders.filter(o => o.estado === 'pendiente').length;
  const cooking = currentOrders.filter(o => o.estado === 'en preparacion').length;
  const totalSales = currentOrders.reduce((sum, o) => sum + (parseFloat(o.total) || 0), 0);

  document.getElementById('kpi-pending').textContent = pending;
  document.getElementById('kpi-cooking').textContent = cooking;
  document.getElementById('kpi-total-sales').textContent = `S/. ${totalSales.toFixed(2)}`;
  document.getElementById('kpi-total-dishes').textContent = currentProducts.length;

  if (pendingBadge) {
    pendingBadge.textContent = pending;
    pendingBadge.style.display = pending > 0 ? 'inline-block' : 'none';
  }
}

// ----------------------------------------------------------------
// UTILIDADES
// ----------------------------------------------------------------
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  container.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 4000);
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[m]));
}

function slugify(text) {
  return text.toString().toLowerCase().replace(/\s+/g, '-');
}
