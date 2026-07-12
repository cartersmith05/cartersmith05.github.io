// Minimal lightbox: click any project figure image to view it full-screen.
const lightbox = document.getElementById('lightbox');
if (lightbox) {
  const lightboxImg = lightbox.querySelector('img');
  document.querySelectorAll('.project figure img').forEach((img) => {
    img.addEventListener('click', () => {
      lightboxImg.src = img.src;
      lightboxImg.alt = img.alt;
      lightbox.hidden = false;
      document.body.style.overflow = 'hidden';
    });
  });
  const close = () => {
    lightbox.hidden = true;
    document.body.style.overflow = '';
  };
  lightbox.addEventListener('click', close);
  document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && !lightbox.hidden) close();
  });
}
