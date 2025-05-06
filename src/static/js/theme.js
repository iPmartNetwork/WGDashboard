
// Enable AOS animations
AOS.init({ once: true });

// Dark Mode Toggle
document.addEventListener('DOMContentLoaded', function () {
    const toggle = document.getElementById('darkToggle');
    const root = document.documentElement;

    if (localStorage.getItem('dark-mode') === 'enabled') {
        root.classList.add('dark-mode');
        if (toggle) toggle.checked = true;
    }

    if (toggle) {
        toggle.addEventListener('change', function () {
            if (this.checked) {
                root.classList.add('dark-mode');
                localStorage.setItem('dark-mode', 'enabled');
            } else {
                root.classList.remove('dark-mode');
                localStorage.setItem('dark-mode', 'disabled');
            }
        });
    }
});
