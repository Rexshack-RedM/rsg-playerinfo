const app = document.getElementById('app');
const heroEl = document.getElementById('hero');
const colsEl = document.getElementById('columns');
const resName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rsg-playerinfo';

let ctx = { labels: {}, show: {} };
let lastKey = '';

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

const has = v => v !== undefined && v !== null && v !== '';
const clamp = v => Math.max(0, Math.min(100, Math.round(Number(v) || 0)));

function money(n) {
    const v = Number(n);
    if (!isFinite(v)) return null;
    return '$' + v.toLocaleString('en-US', {
        minimumFractionDigits: Number.isInteger(v) ? 0 : 2,
        maximumFractionDigits: 2
    });
}

function plain(n) {
    const v = Number(n);
    if (!isFinite(v)) return null;
    return v.toLocaleString('en-US', { minimumFractionDigits: Number.isInteger(v) ? 0 : 2, maximumFractionDigits: 2 });
}

function val(v) {
    return has(v) ? escapeHtml(v) : `<span class="empty">${escapeHtml(ctx.labels.no_data)}</span>`;
}

/* ---------- building blocks ---------- */
function row(icon, label, valueHtml) {
    return `<div class="row">
        <div class="badge"><i class="${safeIcon(icon)}"></i></div>
        <div class="row-label">${escapeHtml(label)}</div>
        <div class="row-value">${valueHtml}</div>
    </div>`;
}

function card(icon, title, body) {
    return `<div class="card">
        <div class="card-title"><i class="${safeIcon(icon)}"></i><span>${escapeHtml(title)}</span></div>
        ${body}
    </div>`;
}

/* ---------- sections ---------- */
function tiles(D) {
    const L = ctx.labels, S = ctx.show, M = D.money || {};
    const defs = [
        ['show_cash', 'fa-solid fa-money-bill-wave', L.cash, M.cash, ''],
        ['show_bloodmoney', 'fa-solid fa-droplet', L.bloodmoney, M.bloodmoney, 'blood'],
        ['show_gold', 'fa-solid fa-coins', L.gold, M.gold, 'gold', true],
        ['show_bank', 'fa-solid fa-building-columns', L.bank, M.bank, ''],
    ];
    return defs.filter(d => S[d[0]]).map(d => {
        const text = d[5] ? plain(d[3]) : money(d[3]);
        return `<div class="tile ${d[4]}">
            <div class="badge"><i class="${safeIcon(d[1])}"></i></div>
            <div>
                <div class="tile-label">${escapeHtml(d[2])}</div>
                <div class="tile-value">${text === null ? val(null) : escapeHtml(text)}</div>
            </div>
        </div>`;
    }).join('');
}

function identityCard(D) {
    const L = ctx.labels, S = ctx.show;
    let gender = D.gender;
    if (gender === 'male') gender = L.male;
    else if (gender === 'female') gender = L.female;

    const defs = [
        ['show_birthdate', 'fa-solid fa-cake-candles', L.birthdate, D.birthdate],
        ['show_gender', 'fa-solid fa-venus-mars', L.gender, gender],
        ['show_nationality', 'fa-solid fa-flag', L.nationality, D.nationality],
        ['show_bloodtype', 'fa-solid fa-droplet', L.bloodtype, D.bloodtype],
        ['show_citizenid', 'fa-solid fa-id-card', L.citizenid, D.citizenid],
        ['show_serverid', 'fa-solid fa-server', L.serverid, D.serverid],
        ['show_fingerprint', 'fa-solid fa-fingerprint', L.fingerprint, D.fingerprint],
        ['show_walletid', 'fa-solid fa-wallet', L.walletid, D.walletid],
        ['show_callsign', 'fa-solid fa-tower-broadcast', L.callsign, D.callsign],
    ].filter(d => S[d[0]]);
    if (!defs.length) return '';
    return card('fa-solid fa-address-card', L.sec_identity, defs.map(d => row(d[1], d[2], val(d[3]))).join(''));
}

function employmentCard(D) {
    const L = ctx.labels, S = ctx.show, J = D.job || {};
    let body = '';
    if (S.show_job) body += row('fa-solid fa-briefcase', L.job, val(J.label));
    if (S.show_job_grade) {
        const grade = has(J.gradeName) ? `${J.gradeName}${has(J.grade) ? ' (' + J.grade + ')' : ''}` : J.grade;
        body += row('fa-solid fa-ranking-star', L.job_grade, val(grade));
    }
    if (S.show_duty) {
        const pill = J.onduty
            ? `<span class="pill on">${escapeHtml(L.on_duty)}</span>`
            : `<span class="pill off">${escapeHtml(L.off_duty)}</span>`;
        body += row('fa-solid fa-clock', L.duty, pill);
    }
    if (S.show_gang) {
        body += row('fa-solid fa-people-group', L.gang, has(D.gang) ? escapeHtml(D.gang) : `<span class="empty">${escapeHtml(L.none)}</span>`);
    }
    if (S.show_other_jobs) {
        const others = D.otherJobs || [];
        body += `<div class="sub-label">${escapeHtml(L.other_jobs)}</div>`;
        body += others.length
            ? `<div class="list">${others.map(j => row('fa-solid fa-user-tie', j.label, escapeHtml(j.grade))).join('')}</div>`
            : `<div class="empty">${escapeHtml(L.none)}</div>`;
    }
    if (!body) return '';
    return card('fa-solid fa-briefcase', L.sec_employment, body);
}

function accountsCard(D) {
    const L = ctx.labels, S = ctx.show, B = D.branches || {};
    const rows = ['rhobank', 'valbank', 'blkbank', 'armbank']
        .filter(k => S['show_' + k] && B[k] !== undefined)
        .map(k => row('fa-solid fa-building-columns', L[k], escapeHtml(money(B[k]) || '')));
    if (!rows.length) return '';
    return card('fa-solid fa-vault', L.sec_accounts, rows.join(''));
}

/* ---------- medical check (bones) ---------- */
const GROUPS = [
    ['core', ['skull', 'neck', 'ribcage', 'lowerspine', 'pelvis']],
    ['arms', ['collarbone_l', 'collarbone_r', 'upperarm_l', 'upperarm_r', 'forearm_l', 'forearm_r', 'hand_l', 'hand_r']],
    ['legs', ['thigh_l', 'thigh_r', 'shin_l', 'shin_r', 'foot_l', 'foot_r']],
];
const BONE_KEYS = GROUPS.flatMap(g => g[1]);
const STATUS_ORDER = ['healthy', 'bruised', 'cracked', 'fractured', 'broken'];
const STATUS_BAR = { healthy: 'stat-good', bruised: 'stat-warn', cracked: 'stat-warn', fractured: 'stat-bad', broken: 'stat-bad' };

function boneStatus(c) {
    const T = ctx.thresholds || { healthy: 90, bruised: 60, cracked: 30 };
    if (c >= T.healthy) return 'healthy';
    if (c >= T.bruised) return 'bruised';
    if (c >= T.cracked) return 'cracked';
    if (c > 0) return 'fractured';
    return 'broken';
}

// Anatomical front-view skeleton (viewBox 0 0 200 450). Player's left is on the viewer's right.
// Classes: f = solid bone, s = bone drawn as a stroke, d = cut-out, crack = break mark (shown for injured bones).
const mir = inner => `<g transform="translate(200 0) scale(-1 1)">${inner}</g>`;
const zig = (cx, cy, w, rot) => {
    const h = w / 2;
    return `<path class="crack" transform="translate(${cx} ${cy}) rotate(${rot})" d="M${-h} 0 L${-h / 2} -3 L${-h / 6} 2.5 L${h / 6} -2.5 L${h / 2} 3 L${h} 0"/>`;
};
const vert = (cx, y, w, h) => `<rect class="f" x="${cx - w / 2}" y="${y}" width="${w}" height="${h}" rx="2"/>`;

// ribs on the viewer-left half (the right half is mirrored)
const RIB_W = [30, 33, 35, 36, 36, 35, 33, 30, 26, 22];
const ribsHalf = RIB_W.map((w, i) => {
    const y = 101 + i * 9.2;
    return `<path class="s" stroke-width="2.6" d="M97 ${y} C${97 - w * 0.35} ${y - 5} ${100 - w} ${y + 2} ${100 - w} ${y + 17}"/>`;
}).join('');

const neck = [0, 1, 2, 3].map(i => vert(100, 73 + i * 6, 9 + i * 0.8, 4.6)).join('');
const lumbar = [0, 1, 2, 3, 4].map(i => {
    const w = 13 + i * 0.9, y = 201 + i * 8.4;
    return vert(100, y, w, 7) +
        `<path class="s" stroke-width="2" d="M${100 - w / 2 - 4.5} ${y + 3.5} H${100 - w / 2} M${100 + w / 2} ${y + 3.5} h4.5"/>`;
}).join('');

const fingerR = (d) => `<path class="s" stroke-width="2.4" d="${d}"/>`;
const handHalf =
    `<rect class="f" x="35" y="246" width="12" height="7" rx="3"/>` +
    fingerR('M36 251 L31 262 L29 269') + fingerR('M38.5 253 L36.5 266 L35.5 278') +
    fingerR('M41 253 L40.5 267 L40.5 281') + fingerR('M43.5 253 L44.5 266 L45.5 278') +
    fingerR('M46 253 L48 263 L49.5 272');

const toes = [0, 1, 2, 3, 4].map(j => {
    const x = 77.5 + j * 3.4, tip = [443, 445, 446, 447, 448][j];
    return `<path class="s" stroke-width="2.4" d="M${x} 438 L${x - 0.5 + (j - 2) * 0.5} ${tip}"/>`;
}).join('');

const SKELETON = {
    skull:
        `<path class="f" d="M100 4 C116 4 122 16 121 30 C120 38 117 44 114 48 L112 56 L88 56 L86 48 C83 44 80 38 79 30 C78 16 84 4 100 4 Z"/>` +
        `<path class="f" d="M87 58 C88 67 94 71 100 71 C106 71 112 67 113 58 L108 58 C107 64 104 66 100 66 C96 66 93 64 92 58 Z"/>` +
        `<ellipse class="d" cx="91" cy="31" rx="5" ry="5.5"/><ellipse class="d" cx="109" cy="31" rx="5" ry="5.5"/>` +
        `<path class="d" d="M100 38 L96.5 47 L103.5 47 Z"/>` +
        `<path class="d" d="M91 53 H109 V55 H91 Z"/>` + zig(100, 14, 22, 0),
    neck: neck + zig(100, 82, 14, 0),
    collarbone_r: `<path class="s" stroke-width="4.2" d="M97 98 C88 92 75 92 63 97"/><circle class="f" cx="62.5" cy="97.5" r="3"/>` + zig(80, 93, 9, 80),
    collarbone_l: mir(`<path class="s" stroke-width="4.2" d="M97 98 C88 92 75 92 63 97"/><circle class="f" cx="62.5" cy="97.5" r="3"/>` + zig(80, 93, 9, 80)),
    ribcage:
        `<path class="f" d="M96 98 L104 98 L102.5 140 L100 149 L97.5 140 Z"/>` + ribsHalf + mir(ribsHalf) + zig(100, 122, 16, 0),
    lowerspine: lumbar + zig(100, 222, 18, 0),
    pelvis:
        `<path class="f" d="M92 240 L108 240 L102 268 L100 273 L98 268 Z"/>` +
        `<rect class="f" x="97" y="291" width="6" height="8" rx="2"/>` +
        [0, 1].map(m => {
            const half =
                `<path class="f" d="M97 240 C84 232 68 228 58 236 C52 248 58 264 68 274 C72 278 76 281 80 284 L88 276 C90 270 94 266 97 264 Z"/>` +
                `<path class="f" d="M80 284 C82 293 90 299 97 300 L97 291 C93 289 90 285 88 277 Z"/>` +
                `<ellipse class="d" cx="70" cy="254" rx="6" ry="10" transform="rotate(-12 70 254)"/>` +
                `<ellipse class="d" cx="84" cy="291" rx="3.2" ry="5" transform="rotate(-20 84 291)"/>` +
                zig(66, 250, 14, -50);
            return m ? mir(half) : half;
        }).join(''),
    upperarm_r:
        `<circle class="f" cx="58" cy="102" r="6.2"/><path class="s" stroke-width="5.5" d="M57 108 C54 130 51 150 48 166"/>` +
        `<ellipse class="f" cx="47" cy="170" rx="6" ry="4.5"/>` + zig(53, 138, 10, -10),
    forearm_r:
        `<ellipse class="f" cx="47" cy="175" rx="6" ry="3.6"/>` +
        `<path class="s" stroke-width="3.6" d="M44 176 C42 200 39 222 37 244"/>` +
        `<path class="s" stroke-width="3.6" d="M50 177 C49 200 47 222 45 244"/>` +
        `<ellipse class="f" cx="41" cy="246" rx="6.5" ry="3"/>` + zig(44, 210, 10, -6),
    hand_r: handHalf + zig(41, 250, 12, 0),
    thigh_r:
        `<circle class="f" cx="80" cy="286" r="6.5"/><path class="s" stroke-width="5" d="M83 289 L74 297"/>` +
        `<path class="s" stroke-width="6.5" d="M74 299 C76 320 80 340 83 352"/>` +
        `<ellipse class="f" cx="82" cy="357" rx="9" ry="5"/><ellipse class="f" cx="84" cy="351" rx="4.5" ry="5.5"/>` + zig(78, 324, 12, -6),
    shin_r:
        `<ellipse class="f" cx="84" cy="364" rx="9" ry="3.2"/>` +
        `<path class="s" stroke-width="5.5" d="M84 366 C85 386 85 406 84 422"/><circle class="f" cx="83.5" cy="425" r="4.2"/>` +
        `<path class="s" stroke-width="3" d="M75.5 367 C75 390 77 410 78 424"/><circle class="f" cx="75.5" cy="367" r="2.6"/><circle class="f" cx="77.8" cy="425.5" r="3"/>` + zig(84, 395, 11, 0),
    foot_r:
        `<path class="f" d="M78 428 C78 424 91 424 91 428 L92 438 L77 438 Z"/>` + toes + zig(84, 435, 13, 0),
};
// the viewer-right (player's left) limbs are mirrored copies
['upperarm', 'forearm', 'hand', 'thigh', 'shin', 'foot'].forEach(n => { SKELETON[n + '_l'] = mir(SKELETON[n + '_r']); });

// faint body silhouette behind the bones
const bodyHalf =
    `<path d="M58 104 C54 130 50 150 47 172 C44 205 41 225 38 248" stroke-width="17" fill="none"/>` +
    `<ellipse cx="39" cy="264" rx="9" ry="19"/>` +
    `<path d="M84 292 C82 320 84 340 85 358" stroke-width="27" fill="none"/>` +
    `<path d="M85 360 C86 385 85 405 84 424" stroke-width="19" fill="none"/>` +
    `<ellipse cx="84" cy="436" rx="11" ry="9"/>`;
const SILHOUETTE =
    `<g class="body">` +
    `<ellipse cx="100" cy="36" rx="25" ry="35"/><rect x="90" y="62" width="20" height="38"/>` +
    `<path d="M66 96 C80 90 90 92 100 92 C110 92 120 90 134 96 C142 100 142 118 138 150 C136 175 132 200 132 232 C132 262 128 290 122 304 L78 304 C72 290 68 262 68 232 C68 200 64 175 62 150 C58 118 58 100 66 96 Z"/>` +
    bodyHalf + mir(bodyHalf) + `</g>`;

function medicalCard(D) {
    const L = ctx.labels;
    if (!ctx.show.show_bones) return '';
    const B = D.bones || {};
    const SP = D.splints || {};

    const info = BONE_KEYS.map(k => {
        const c = Math.max(0, Math.min(100, Math.round(Number(B[k] ?? 100))));
        return { key: k, cond: c, status: boneStatus(c), splint: !!SP[k] && c < 90 };
    });
    const by = Object.fromEntries(info.map(i => [i.key, i]));

    const count = st => info.filter(i => i.status === st).length;
    const fractures = count('fractured') + count('broken');
    const cracks = count('cracked');
    const bruises = count('bruised');
    const integrity = Math.round(info.reduce((a, i) => a + i.cond, 0) / info.length);

    let verdict = 'verdict_ok', vcls = 'good';
    if (count('broken')) { verdict = 'verdict_critical'; vcls = 'bad'; }
    else if (count('fractured')) { verdict = 'verdict_fracture'; vcls = 'bad'; }
    else if (cracks) { verdict = 'verdict_cracks'; vcls = 'warn'; }
    else if (bruises) { verdict = 'verdict_minor'; vcls = 'warn'; }

    const iCls = integrity >= 90 ? 'stat-good' : integrity >= 60 ? 'stat-warn' : 'stat-bad';

    const summary = `
        <div class="med-summary">
            <div class="med-verdict ${vcls}">${escapeHtml(L[verdict])}</div>
            <div class="med-row">
                <div class="stat">
                    <div class="stat-head"><span>${escapeHtml(L.med_integrity)}</span><span>${integrity}%</span></div>
                    <div class="track"><div class="fill ${iCls}" data-w="${integrity}"></div></div>
                </div>
                <div class="med-counts">
                    <div class="count ${fractures ? 'bad' : ''}"><b>${fractures}</b><span>${escapeHtml(L.med_fractures)}</span></div>
                    <div class="count ${cracks ? 'warn' : ''}"><b>${cracks}</b><span>${escapeHtml(L.med_cracks)}</span></div>
                    <div class="count ${bruises ? 'warn' : ''}"><b>${bruises}</b><span>${escapeHtml(L.med_bruises)}</span></div>
                </div>
            </div>
        </div>`;

    const svg = `<svg class="skeleton" viewBox="0 0 200 450" xmlns="http://www.w3.org/2000/svg">` + SILHOUETTE +
        BONE_KEYS.map(k => `<g class="bone st-${by[k].status}${by[k].splint ? ' splinted' : ''}" data-bone="${k}">${SKELETON[k]}</g>`).join('') +
        `</svg>`;

    const group = gid => {
        const keys = GROUPS.find(g => g[0] === gid)[1];
        return `<div class="sub-label">${escapeHtml(L['group_' + gid])}</div>` + keys.map(k => {
            const i = by[k];
            return `<div class="bone-row" data-bone="${k}">
                <div class="bone-line">
                    <span class="bn">${escapeHtml(L['bone_' + k])}</span>
                    <span class="bs st-${i.status}">${escapeHtml(L['status_' + i.status])}${i.splint ? ' · ' + escapeHtml(L.splinted || '') : ''}</span>
                </div>
                <div class="track"><div class="fill ${STATUS_BAR[i.status]}" data-w="${i.cond}"></div></div>
            </div>`;
        }).join('');
    };
    const list = `<div>${group('core')}${group('legs')}</div><div>${group('arms')}</div>`;

    return card('fa-solid fa-bone', L.sec_medical,
        summary + `<div class="med"><div class="map">${svg}</div><div class="med-list">${list}</div></div>`);
}

function standingCard(D) {
    const L = ctx.labels, S = ctx.show, O = D.outlaw || {};
    let body = '';
    if (S.show_outlawstatus) {
        const band = ['good', 'warn', 'bad'].includes(O.band) ? O.band : 'good';
        const pct = clamp(O.value);
        body += `<div class="sub-label" style="margin-top:0">${escapeHtml(L.outlawstatus)}</div>
            <div class="outlaw-text ${band}">${escapeHtml(O.text || L.no_data)}</div>
            <div class="track"><div class="fill stat-${band}" data-w="${pct}"></div></div>`;
    }
    if (S.show_reputation) {
        const rep = D.rep || [];
        if (rep.length) {
            body += `<div class="sub-label">${escapeHtml(L.reputation)}</div><div class="list">` +
                rep.map(r => row('fa-solid fa-handshake', r.name, escapeHtml(r.value))).join('') + '</div>';
        }
    }
    if (!body) return '';
    return card('fa-solid fa-scale-balanced', L.sec_standing, body);
}

/* ---------- render ---------- */
function render(D, animate) {
    const scroll = [...colsEl.querySelectorAll('.col')].map(c => c.scrollTop);

    app.classList.toggle('exam', !!ctx.exam);
    heroEl.innerHTML = ctx.exam ? '' : tiles(D);
    const cols = ctx.exam
        ? [[medicalCard(D)]]
        : [
            [identityCard(D), employmentCard(D)],
            [medicalCard(D)],
            [standingCard(D), accountsCard(D)],
        ];
    colsEl.innerHTML = cols.map(c => `<div class="col">${c.join('')}</div>`).join('');

    [...colsEl.querySelectorAll('.col')].forEach((c, i) => { c.scrollTop = scroll[i] || 0; });

    const fills = document.querySelectorAll('.fill');
    const setBars = () => fills.forEach(f => { f.style.width = f.dataset.w + '%'; });
    if (animate) requestAnimationFrame(() => requestAnimationFrame(setBars));
    else setBars();
}

function highlight(key, on) {
    document.querySelectorAll(`[data-bone="${key}"]`).forEach(e => e.classList.toggle('hl', on));
}
colsEl.addEventListener('mouseover', e => {
    const t = e.target.closest && e.target.closest('[data-bone]');
    if (t) highlight(t.dataset.bone, true);
});
colsEl.addEventListener('mouseout', e => {
    const t = e.target.closest && e.target.closest('[data-bone]');
    if (t) highlight(t.dataset.bone, false);
});

function open(d) {
    ctx = { labels: d.labels || {}, show: d.show || {}, thresholds: d.thresholds, exam: !!d.exam };
    document.documentElement.style.setProperty('--size', String(d.percent || 80));
    document.getElementById('title').textContent = d.title || '';
    document.getElementById('subtitle').textContent = d.subtitle || '';
    if (d.closeLabel) document.getElementById('closeBtn2').textContent = d.closeLabel;

    lastKey = JSON.stringify(d.data);
    render(d.data || {}, true);
    app.classList.remove('hidden');
}

function update(d) {
    if (app.classList.contains('hidden')) return;
    const key = JSON.stringify(d.data);
    if (key === lastKey) return;
    lastKey = key;
    render(d.data || {}, false);
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
    else if (d.action === 'update') update(d);
    else if (d.action === 'close') close();
});

document.getElementById('closeBtn').addEventListener('click', requestClose);
document.getElementById('closeBtn2').addEventListener('click', requestClose);
document.addEventListener('keydown', (e) => {
    if ((e.key === 'Escape' || e.key === 'Backspace') && !app.classList.contains('hidden')) requestClose();
});
