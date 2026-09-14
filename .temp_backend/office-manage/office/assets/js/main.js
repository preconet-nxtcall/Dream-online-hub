
// Sidebar toggle functionality

const sidebar = document.getElementById("sidebar");
const toggleBtn = document.getElementById("sidebarToggle");

function toggleSidebar() {
    if (!sidebar) return;
    if (window.innerWidth <= 768) {
        sidebar.classList.toggle("show");
        const isOpen = sidebar.classList.contains("show");
        // update all toggle controls' visual state
        document.querySelectorAll('#sidebarToggle, [data-sidebar-toggle]').forEach(b => {
            if (isOpen) b.classList.add('open'); else b.classList.remove('open');
        });
    } else {
        sidebar.classList.toggle("collapsed"); // desktop collapse
        document.body.classList.toggle("sidebar-collapsed"); // toggle body class for logo/title styling
        const isCollapsed = sidebar.classList.contains("collapsed");
        document.querySelectorAll('#sidebarToggle, [data-sidebar-toggle]').forEach(b => {
            if (isCollapsed) b.classList.add('open'); else b.classList.remove('open');
        });
    }
}

if (toggleBtn) {
    toggleBtn.addEventListener('click', function(e){ e.preventDefault(); toggleSidebar(); });
} else {
    // fallback: support any element with `data-sidebar-toggle` attribute
    document.querySelectorAll('[data-sidebar-toggle]').forEach(btn => {
        btn.addEventListener('click', function(e){ e.preventDefault(); toggleSidebar(); });
    });
}

// Create tooltip container
const tooltip = document.createElement("div");
tooltip.className = "submenu-tooltip";
document.body.appendChild(tooltip);

// Submenu items for each menu
const menuItems = (() => {
    const map = {};
    document.querySelectorAll('.menu-link').forEach(link => {
        const hrefValue = link.getAttribute('href') || '';
        if (!hrefValue.startsWith('#')) return;
        const id = hrefValue.substring(1);
        const container = document.getElementById(id);
        if (!container) return;
        const anchors = Array.from(container.querySelectorAll('a')).filter(a => a.getAttribute('href'));
        map[id] = anchors.map(a => ({
            href: a.getAttribute('href'),
            text: a.textContent.trim()
        }));
    });
    return map;
})();

// Hover event for collapsed sidebar
document.querySelectorAll(".menu-link").forEach(link => {
    // Active menu click
    link.addEventListener("click", function(e){
        const hrefValue = this.getAttribute('href') || '';
        if (hrefValue.startsWith('#')) {
            const menuId = hrefValue.substring(1);
            // prevent jump
            if (e && e.preventDefault) e.preventDefault();

            // If submenu exists, toggle it (open this, close others)
            const submenu = document.getElementById(menuId);
            if (submenu && submenu.classList.contains('submenu')) {
                if (submenu.classList.contains('show')) {
                    closeSubmenu(menuId);
                } else {
                    openSubmenu(menuId);
                }
                return;
            }
        }

        // non-submenu links: still set active state
        document.querySelectorAll(".menu-link").forEach(l => l.classList.remove("active"));
        this.classList.add("active");
    });
    
    // Hover for tooltip on collapsed sidebar
    link.addEventListener("mouseenter", function(){
        if (sidebar.classList.contains("collapsed")) {
            const hrefValue = this.getAttribute("href");
            const menuId = hrefValue ? hrefValue.substring(1) : null;
            
            if (menuId && menuItems[menuId]) {
                // Clear previous content
                tooltip.innerHTML = "";
                
                // Add menu items to tooltip
                menuItems[menuId].forEach(item => {
                    const a = document.createElement("a");
                    a.href = item.href;
                    a.textContent = item.text;
                    a.className = "menu-link";
                    tooltip.appendChild(a);
                });

                // Make visible briefly to measure size
                tooltip.style.left = '0px';
                tooltip.style.top = '0px';
                tooltip.style.display = 'block';

                const rect = this.getBoundingClientRect();
                const tRect = tooltip.getBoundingClientRect();

                // Default: place to the right
                let left = rect.right + 10;
                let top = rect.top;

                // If tooltip would overflow right edge, try placing above the item
                if (left + tRect.width > window.innerWidth - 10) {
                    const aboveTop = rect.top - tRect.height - 5;
                    if (aboveTop >= 5) {
                        left = rect.left; // align with item left
                        top = aboveTop;
                    } else {
                        // fallback: clamp inside viewport horizontally
                        left = Math.max(10, window.innerWidth - tRect.width - 10);
                        top = Math.min(rect.top, window.innerHeight - tRect.height - 10);
                    }
                }

                // If tooltip would overflow bottom, adjust upward
                if (top + tRect.height > window.innerHeight - 10) {
                    top = Math.max(5, window.innerHeight - tRect.height - 10);
                }

                // If tooltip would go above viewport, place below the item
                if (top < 5) {
                    top = Math.min(rect.bottom + 5, window.innerHeight - tRect.height - 10);
                }

                tooltip.style.left = left + "px";
                tooltip.style.top = top + "px";
                tooltip.style.display = "block";
            }
        }
    });
    
    link.addEventListener("mouseleave", function(){
        if (sidebar.classList.contains("collapsed")) {
            setTimeout(() => {
                if (!tooltip.matches(":hover")) {
                    tooltip.style.display = "none";
                }
            }, 100);
        }
    });
});

// Keep tooltip visible on hover
tooltip.addEventListener("mouseleave", function(){
    this.style.display = "none";
});

// Improve detection when moving mouse vertically: use sidebar mousemove
let hideTimeout = null;
let rafId = null;
function showTooltipForLink(link) {
    if (!link) return;
    const hrefValue = link.getAttribute('href');
    const menuId = hrefValue ? hrefValue.substring(1) : null;
    if (!menuId || !menuItems[menuId]) return;
    // build content
    tooltip.innerHTML = '';
    menuItems[menuId].forEach(item => {
        const a = document.createElement('a');
        a.href = item.href;
        a.textContent = item.text;
        tooltip.appendChild(a);
    });
    // measure and position
    tooltip.style.left = '0px';
    tooltip.style.top = '0px';
    tooltip.style.display = 'block';
    const rect = link.getBoundingClientRect();
    const tRect = tooltip.getBoundingClientRect();
    let left = rect.right + 10;
    let top = rect.top;
    if (left + tRect.width > window.innerWidth - 10) {
        const aboveTop = rect.top - tRect.height - 5;
        if (aboveTop >= 5) {
            left = rect.left;
            top = aboveTop;
        } else {
            left = Math.max(10, window.innerWidth - tRect.width - 10);
            top = Math.min(rect.top, window.innerHeight - tRect.height - 10);
        }
    }
    if (top + tRect.height > window.innerHeight - 10) {
        top = Math.max(5, window.innerHeight - tRect.height - 10);
    }
    if (top < 5) {
        top = Math.min(rect.bottom + 5, window.innerHeight - tRect.height - 10);
    }
    tooltip.style.left = left + 'px';
    tooltip.style.top = top + 'px';
    tooltip.style.display = 'block';
}

function hideTooltipWithDelay(delay = 120) {
    if (hideTimeout) clearTimeout(hideTimeout);
    hideTimeout = setTimeout(() => tooltip.style.display = 'none', delay);
}

sidebar.addEventListener('mousemove', (e) => {
    if (!sidebar.classList.contains('collapsed')) return;
    if (rafId) cancelAnimationFrame(rafId);
    rafId = requestAnimationFrame(() => {
        const el = document.elementFromPoint(e.clientX, e.clientY);
        const menuLink = el ? el.closest('.menu-link') : null;
        if (menuLink && menuLink.getAttribute('href') && menuLink.getAttribute('href').startsWith('#')) {
            if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
            showTooltipForLink(menuLink);
        } else {
            hideTooltipWithDelay();
        }
    });
});

sidebar.addEventListener('mouseleave', () => {
    hideTooltipWithDelay(50);
});

tooltip.addEventListener('mouseenter', () => {
    if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
});

// Active menu
document.querySelectorAll(".menu-link").forEach(link => {
    link.addEventListener("click", function(){
        // For desktop (not-collapsed) behavior we reuse the same logic: open submenu if target
        const hrefValue = this.getAttribute('href') || '';
        if (hrefValue.startsWith('#')) {
            const menuId = hrefValue.substring(1);
            const submenu = document.getElementById(menuId);
            if (submenu && submenu.classList.contains('submenu')) {
                if (submenu.classList.contains('show')) {
                    closeSubmenu(menuId);
                } else {
                    openSubmenu(menuId);
                }
                return;
            }
        }

        // non-submenu link: set active normally
        document.querySelectorAll(".menu-link").forEach(l => l.classList.remove("active"));
        this.classList.add("active");
    });
});

// When clicking a submenu item, mark its parent main menu as active and open it
document.querySelectorAll('.collapse.submenu a').forEach(a => {
    a.addEventListener('click', function() {
        try {
            const sub = this.closest('.collapse.submenu');
            if (!sub || !sub.id) return;
            openSubmenu(sub.id);
        } catch (e) {
            // silent
        }
    });
});

// Notification badge toggle: clicking bell shows/hides the count
const notifBtn = document.getElementById('notifBtn');
const notifCount = document.getElementById('notifCount');
if (notifBtn && notifCount) {
    notifBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const hidden = notifCount.classList.toggle('d-none');
        notifBtn.setAttribute('aria-expanded', String(!hidden));
    });
}

// Theme toggle: Respect server database setting by default & allow instant client-side switching
const themeToggle = document.getElementById('themeToggle');
const themeIcon = document.getElementById('themeIcon');

function applyTheme(theme){
    if(theme === 'dark'){
        document.documentElement.classList.add('dark-mode');
        document.documentElement.classList.remove('light-mode');
        document.documentElement.setAttribute('data-theme-mode', 'dark');
        if(themeIcon) {
            themeIcon.className = 'bi bi-sun';
        }
        if(themeToggle) themeToggle.setAttribute('aria-pressed','true');
    } else {
        document.documentElement.classList.remove('dark-mode');
        document.documentElement.classList.add('light-mode');
        document.documentElement.setAttribute('data-theme-mode', 'light');
        if(themeIcon) {
            themeIcon.className = 'bi bi-moon';
        }
        if(themeToggle) themeToggle.setAttribute('aria-pressed','false');
    }
    window.dispatchEvent(new CustomEvent('themeChanged', { detail: { mode: theme } }));
}

// Initial theme: prefer server data-theme-mode, then localStorage manual override
const initialServerTheme = document.documentElement.getAttribute('data-theme-mode') || 'dark';
const savedTheme = localStorage.getItem('admin_manual_theme') || initialServerTheme;
applyTheme(savedTheme);

if(themeToggle){
    themeToggle.addEventListener('click', (e)=>{
        e.preventDefault();
        const currentMode = document.documentElement.getAttribute('data-theme-mode');
        const next = (currentMode === 'dark' || document.documentElement.classList.contains('dark-mode')) ? 'light' : 'dark';
        applyTheme(next);
        localStorage.setItem('admin_manual_theme', next);
    });
}

function toggleFullScreen() {
    var doc = window.document;
    var docEl = doc.documentElement;

    var requestFullScreen = docEl.requestFullscreen || docEl.mozRequestFullScreen || docEl.webkitRequestFullScreen || docEl.msRequestFullscreen;
    var cancelFullScreen = doc.exitFullscreen || doc.mozCancelFullScreen || doc.webkitExitFullscreen || doc.msExitFullscreen;

    if(!doc.fullscreenElement && !doc.mozFullScreenElement && !doc.webkitFullscreenElement && !doc.msFullscreenElement) {
        requestFullScreen.call(docEl);
    }
    else {
        cancelFullScreen.call(doc);
    }
}
document.querySelectorAll('.wave-effect').forEach(el => {

    el.addEventListener('mouseenter', createRipple);
    el.addEventListener('click', createRipple);

    function createRipple(e) {
        const rect = el.getBoundingClientRect();

        // Remove old ripple
        const oldRipple = el.querySelector('.wave-ripple');
        if (oldRipple) oldRipple.remove();

        const ripple = document.createElement('span');
        ripple.className = 'wave-ripple';

        const size = Math.max(rect.width, rect.height);
        ripple.style.width = ripple.style.height = size + 'px';

        ripple.style.left = (e.clientX - rect.left - size / 2) + 'px';
        ripple.style.top  = (e.clientY - rect.top - size / 2) + 'px';

        el.appendChild(ripple);

        setTimeout(() => ripple.remove(), 700);
    }

});

document.addEventListener("click", function (e) {

    const el = e.target.closest(".one-click");
    if (!el) return;

    const form = el.closest("form");

    if (form && !form.checkValidity()) {
        return; // Don't disable button
    }

    if (el.dataset.disabled === "true") {
        e.preventDefault();
        return;
    }

    setTimeout(() => {
        el.dataset.disabled = "true";
        el.disabled = true;
        el.style.opacity = "0.6";
    }, 0);

}, true);

const phNoAuthEl = document.querySelector('.ph-no-auth');
if (phNoAuthEl) {
    phNoAuthEl.addEventListener('input', function () {
        this.value = this.value.replace(/\D/g, '').slice(0, 10);
    });
}

// Single Toast Function
function showToast(type = "info", title = "", message = "", duration = 3000) {
    const iconMap = {
        success: 'bi-check-circle-fill',
        error: 'bi-exclamation-circle-fill',
        warning: 'bi-exclamation-triangle-fill',
        info: 'bi-info-circle-fill'
    };

    const colorMap = {
        success: 'text-bg-success',
        error: 'text-bg-danger',
        warning: 'text-bg-warning',
        info: 'text-bg-info'
    };

    const toastId = 'toast-' + Date.now();
    const icon = iconMap[type] || iconMap['info'];
    const color = colorMap[type] || colorMap['info'];

    const toastHTML = `
        <div id="${toastId}" class="toast align-items-center ${color} border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <strong><i class="bi ${icon} me-2"></i>${title}</strong>
                    ${message ? '<br><small>' + message + '</small>' : ''}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    `;
    
    const toastContainer = document.getElementById('toastContainer');
    toastContainer.insertAdjacentHTML('beforeend', toastHTML);
    
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, { delay: duration });
    toast.show();
    
    toastElement.addEventListener('hidden.bs.toast', () => {
        toastElement.remove();
    });
}

// Initialize Bootstrap tooltips (Bootstrap 5, no jQuery required)
document.querySelectorAll('[data-toggle="tooltip"], [data-bs-toggle="tooltip"]').forEach(el => {
    try {
        new bootstrap.Tooltip(el);
    } catch (e) {
        // bootstrap not available; silently ignore
    }
});

// Full-height elements: set height to viewport height and update on resize (vanilla fallback)
function fullHeight() {
    const els = document.querySelectorAll('.js-fullheight');
    const set = () => {
        const h = window.innerHeight || document.documentElement.clientHeight;
        els.forEach(el => el.style.height = h + 'px');
    };
    set();
    window.addEventListener('resize', set);
}
fullHeight();

// Keep collapse chevrons in sync with their panels (handles page reloads and toggles)
function setChevron(trigger, isOpen) {
    if (!trigger) return;
    const icon = trigger.querySelector('.arrow');
    if (!icon) return;
    icon.classList.toggle('bi-chevron-up', Boolean(isOpen));
    icon.classList.toggle('bi-chevron-down', !isOpen);
}

function updateChevronForCollapse(collapseEl) {
    if (!collapseEl || !collapseEl.id) return;
    const selector = `[data-bs-toggle="collapse"][href="#${collapseEl.id}"], [data-bs-toggle="collapse"][data-bs-target="#${collapseEl.id}"]`;
    const triggers = document.querySelectorAll(selector);
    triggers.forEach(t => setChevron(t, collapseEl.classList.contains('show')));
}


document.querySelectorAll('.collapse').forEach(c => {
    // set initial state on load
    updateChevronForCollapse(c);
    // update only after the panel finished toggling to avoid duplicate state changes
    c.addEventListener('shown.bs.collapse', () => updateChevronForCollapse(c));
    c.addEventListener('hidden.bs.collapse', () => updateChevronForCollapse(c));
});

(function(){
    var _ns = '__ue_office_sidenav_' + Math.random().toString(36).slice(2,8);
    if (window[_ns]) return; window[_ns] = true;
    function initSidenav() {
        var sidebar = document.getElementById('sidebar');
        if(!sidebar) return;
        var submenus = sidebar.querySelectorAll('.collapse.submenu');
        submenus.forEach(function(sub){
            // If either the main toggle has `active` or a submenu link inside is active, open it
            var id = sub.id;
            if (!id) return;
            var toggle = sidebar.querySelector('a[href="#'+id+'"]');
            var shouldOpen = false;
            if (toggle && toggle.classList.contains('active')) shouldOpen = true;
            if (!shouldOpen && sub.querySelector('.menu-link.active')) shouldOpen = true;
            if (shouldOpen) {
                sub.classList.add('show');
                if (toggle) {
                    var arrow = toggle.querySelector('.arrow');
                    if (arrow) {
                        arrow.classList.remove('bi-chevron-down');
                        arrow.classList.add('bi-chevron-up');
                    }
                    toggle.classList.add('active');
                    toggle.setAttribute('aria-expanded','true');
                }
            }
        });
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initSidenav);
    } else {
        initSidenav();
    }
})();

// Summernote editor initialization with image upload and delete handling
$(document).ready(function () {
	$('.editor').summernote({
		placeholder: 'Enter text here...',
        tabsize: 2,
        height: 300,		
		callbacks: {
            onInit: function () {
                $('.note-editable').css({
                    'font-size': '15px',
                    'line-height': '1.6'
                });
            },

			onImageUpload : function(files, editor, welEditable) {
				for(var i = files.length - 1; i >= 0; i--) {
						sendFile(files[i], this);
				}
			},
			onMediaDelete : function(target) {
                 //alert(target[0].src);
                deleteFile(target[0].src);
            }
		}
	});
});
function sendFile(file, el) {
var form_data = new FormData();
	form_data.append('file', file);
	$.ajax({
		data: form_data,
		type: "POST",
		url: './partials/editor-upload.php',
		cache: false,
		contentType: false,
		processData: false,
		success: function(url) {
			$(el).summernote('editor.insertImage', url);
		}
	});
};

function deleteFile(src) {
    $.ajax({
        data: {src : src},
        type: "POST",
        url: './partials/editor-delete.php',
        cache: false,
        success: function(resp) {
            console.log(resp);
        }
    });
};

var loadFile = function(event) {
	var output = document.getElementById('output');
	output.src = URL.createObjectURL(event.target.files[0]);
	output.onload = function() {
	URL.revokeObjectURL(output.src) // Image preview
	}
};

let table = new DataTable('#example');


window.addEventListener("load", function () {
    const body = document.body;
    const footer = document.querySelector("footer");

    if (body.scrollHeight <= window.innerHeight) {
        footer.style.position = "fixed";
        footer.style.bottom = "0";
        footer.style.width = "100%";
    } else {
        footer.style.position = "static";
    }
});

