const toggle = document.getElementById('theme-toggle');
const body = document.body;

function toggleTheme() {
  body.classList.toggle('light');
  toggle.classList.toggle('light');
  toggle.innerHTML = body.classList.contains('light')
    ? 'Switch to dark theme'
    : 'Switch to light theme';
}

window.addEventListener('load', () => {
  toggleTheme();
  toggle.addEventListener('click', toggleTheme);
});

export { dark_theme };
