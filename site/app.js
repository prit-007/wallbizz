document.addEventListener('DOMContentLoaded', () => {
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
      }
    });
  }, observerOptions);

  document.querySelectorAll('.feature-card, .screenshot-card, .cta').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
  });

  document.querySelectorAll('.feature-card').forEach((card, i) => {
    card.style.transitionDelay = `${i * 100}ms`;
  });

  document.querySelectorAll('.screenshot-card').forEach((card, i) => {
    card.style.transitionDelay = `${i * 150}ms`;
  });

  let lastScroll = 0;
  window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    const currentScroll = window.scrollY;
    if (currentScroll > 100) {
      navbar.style.background = 'rgba(10, 10, 24, 0.95)';
    } else {
      navbar.style.background = 'rgba(10, 10, 24, 0.8)';
    }
    lastScroll = currentScroll;
  });
});
