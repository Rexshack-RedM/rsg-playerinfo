const app = document.getElementById('app');
const rowsEl = document.getElementById('rows');
const resName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rsg-playerinfo';

function post(name, data = {}) {
    return fetch(`https://${resName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function escapeHtml(v) {
    return String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function safeIcon(icon) {
    return /^[a-z0-9 -]+$/i.test(icon || '') ? icon : 'fa-solid fa-circle-info';
}

function open(data) {
    document.getElementById('title').textContent = data.title || '';
    document.getElementById('subtitle').textContent = data.subtitle || '';
    if (data.closeLabel) document.getElementById('closeBtn2').textContent = data.closeLabel;

    rowsEl.innerHTML = (data.rows || []).map(r => {
        const hasValue = r.value !== undefined && r.value !== null && r.value !== '';
        return `
        <div class="row">
            <div class="badge"><i class="${safeIcon(r.icon)}"></i></div>
            <div class="row-text">
                <div class="row-label">${escapeHtml(r.label)}</div>
                ${hasValue ? `<div class="row-value">${escapeHtml(r.value)}</div>` : ''}
            </div>
        </div>`;
    }).join('');

    app.classList.remove('hidden');
}

function close() {
    app.classList.add('hidden');
}

function requestClose() {
    close();
    post('close');
}

window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open') open(d);
    else if (d.action === 'close') close();
});

document.getElementById('closeBtn').addEventListener('click', requestClose);
document.getElementById('closeBtn2').addEventListener('click', requestClose);
document.addEventListener('keydown', (e) => {
    if ((e.key === 'Escape' || e.key === 'Backspace') && !app.classList.contains('hidden')) requestClose();
});
